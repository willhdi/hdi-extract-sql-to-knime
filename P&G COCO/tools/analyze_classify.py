"""Classify extracted SQL files as DDL/DML, move them into subfolders,
extract metadata per file and parse the top-level KNIME workflow graph.
Outputs analysis.json.
"""
import json
import os
import re
import shutil
import sys
import xml.etree.ElementTree as ET

SQL_ROOT = sys.argv[1]      # repo sql/ dir
KNWF_ROOT = sys.argv[2]     # unzipped knwf root (contains P&G_COCO/)
OUT_JSON = sys.argv[3]

NS = {"k": "http://www.knime.org/2008/09/XMLConfig"}

# ---------- 1. workflow graph (top level) ----------
wf = ET.parse(os.path.join(KNWF_ROOT, "P&G_COCO", "workflow.knime")).getroot()

def cfg(parent, key):
    for c in parent.findall("k:config", NS):
        if c.get("key") == key:
            return c
    return None

nodes = {}
for node in cfg(wf, "nodes").findall("k:config", NS):
    nid = None
    fname = None
    for e in node.findall("k:entry", NS):
        if e.get("key") == "id":
            nid = int(e.get("value"))
        if e.get("key") == "node_settings_file":
            fname = e.get("value").split("/")[0]
    if nid is not None:
        nodes[nid] = fname

edges = []
for conn in cfg(wf, "connections").findall("k:config", NS):
    src = dst = None
    for e in conn.findall("k:entry", NS):
        if e.get("key") == "sourceID":
            src = int(e.get("value"))
        if e.get("key") == "destID":
            dst = int(e.get("value"))
    if src in nodes and dst in nodes:
        edges.append([nodes[src], nodes[dst]])

# ---------- 2. classify sql files ----------
RE_CREATE = re.compile(r"\bcreate\s+table\b", re.I)
RE_DROP = re.compile(r"\bdrop\s+table\b", re.I)
RE_TRUNC = re.compile(r"\btruncate\s+table\b", re.I)
RE_ALTER = re.compile(r"\balter\s+table\b", re.I)
RE_SELECT_INTO = re.compile(r"\binto\s+(#{1,2}[\w]+|\[?[\w]+\]?(?:\.\[?[\w]+\]?){0,2})\s*\bfrom\b", re.I | re.S)
RE_INSERT = re.compile(r"\binsert\s+into\s+([#\w.\[\]]+)", re.I)
RE_UPDATE = re.compile(r"\bupdate\s+([#\w.\[\]]+)", re.I)
RE_DELETE = re.compile(r"\bdelete\s+from\s+([#\w.\[\]]+)", re.I)
RE_FROMJOIN = re.compile(r"\b(?:from|join)\s+([#\w.\[\]]+)", re.I)
RE_INTO_TMP = re.compile(r"\binto\s+(#{1,2}\w+)", re.I)
RE_CONCEPT = re.compile(r"'([^']+)'\s+as\s+Concepto_nivel_1", re.I)

def analyze_sql(text):
    body = re.sub(r"--[^\n]*", "", text)  # strip comments
    ops = []
    if RE_DROP.search(body):
        ops.append("DROP TABLE")
    if RE_CREATE.search(body):
        ops.append("CREATE TABLE")
    if RE_ALTER.search(body):
        ops.append("ALTER TABLE")
    if RE_TRUNC.search(body):
        ops.append("TRUNCATE")
    tmp_created = sorted(set(m.group(1).lower() for m in RE_INTO_TMP.finditer(body)))
    if tmp_created:
        ops.append("SELECT INTO")
    inserts = sorted(set(m.group(1).lower() for m in RE_INSERT.finditer(body)))
    if inserts:
        ops.append("INSERT")
    updates = sorted(set(m.group(1).lower() for m in RE_UPDATE.finditer(body)
                         if m.group(1).lower() not in ("statistics",)))
    if updates:
        ops.append("UPDATE")
    deletes = sorted(set(m.group(1).lower() for m in RE_DELETE.finditer(body)))
    if deletes:
        ops.append("DELETE")
    if re.search(r"\bselect\b", body, re.I) and not ops:
        ops.append("SELECT")
    elif re.search(r"\bselect\b", body, re.I) and ops and "SELECT INTO" not in ops and not inserts:
        ops.append("SELECT")
    sources = sorted(set(m.group(1).lower().strip("[]") for m in RE_FROMJOIN.finditer(body)))
    # keep only real tables (schema-qualified or temp), drop aliases/subquery artifacts
    sources = [s for s in sources if s.startswith("#") or "." in s]
    concepts = sorted(set(m.group(1).strip() for m in RE_CONCEPT.finditer(body)))
    is_ddl = bool(RE_CREATE.search(body) or RE_DROP.search(body) or RE_ALTER.search(body)
                  or RE_TRUNC.search(body) or tmp_created)
    return {
        "clase": "DDL" if is_ddl else "DML",
        "ops": ops,
        "temp_creadas": tmp_created,
        "insert_en": inserts,
        "update_en": updates,
        "fuentes": sources,
        "conceptos": concepts,
    }

files = {}
for dirpath, dirnames, filenames in os.walk(SQL_ROOT):
    if os.path.basename(dirpath) in ("DDL", "DML"):
        continue
    for fn in sorted(filenames):
        if not fn.endswith(".sql"):
            continue
        fpath = os.path.join(dirpath, fn)
        rel = os.path.relpath(fpath, SQL_ROOT).replace("\\", "/")
        with open(fpath, encoding="utf-8") as f:
            text = f.read()
        node_path = ""
        m = re.search(r"-- Nodo KNIME : (.+)", text)
        if m:
            node_path = m.group(1).strip()
        info = analyze_sql(text)
        info["nodo"] = node_path
        # move into DDL/ or DML/ subfolder next to current location
        dest_dir = os.path.join(dirpath, info["clase"])
        os.makedirs(dest_dir, exist_ok=True)
        shutil.move(fpath, os.path.join(dest_dir, fn))
        comp = rel.split("/")[0]
        new_rel = os.path.relpath(os.path.join(dest_dir, fn), SQL_ROOT).replace("\\", "/")
        info["archivo"] = new_rel
        files.setdefault(comp, []).append(info)

result = {"edges": edges, "componentes": files}
with open(OUT_JSON, "w", encoding="utf-8") as f:
    json.dump(result, f, ensure_ascii=False, indent=1)

n_ddl = sum(1 for fl in files.values() for i in fl if i["clase"] == "DDL")
n_dml = sum(1 for fl in files.values() for i in fl if i["clase"] == "DML")
print(f"DDL: {n_ddl}  DML: {n_dml}  total: {n_ddl+n_dml}")
print("EDGES:")
for s, d in edges:
    print(f"  {s} -> {d}")
