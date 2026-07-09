"""Extract SQL statements from an unzipped KNIME workflow (.knwf) into .sql files."""
import os
import re
import sys
import xml.etree.ElementTree as ET

SRC = sys.argv[1]   # root of unzipped knwf
DST = sys.argv[2]   # output dir for sql files

NS = {"k": "http://www.knime.org/2008/09/XMLConfig"}
SQL_KEYS = {"sql_statement", "statement", "query", "SQLStatement", "sql"}

def decode_knime(text):
    """Decode KNIME %%000NN character escapes (e.g. %%00010 = LF)."""
    return re.sub(r"%%(\d{5})", lambda m: chr(int(m.group(1))), text)

def find_sql(settings_path):
    """Return list of (key, sql) found in a settings.xml model section."""
    try:
        tree = ET.parse(settings_path)
    except ET.ParseError:
        return []
    root = tree.getroot()
    model = None
    for cfg in root.findall("k:config", NS):
        if cfg.get("key") == "model":
            model = cfg
            break
    if model is None:
        return []
    out = []
    for entry in model.iter():
        key = entry.get("key")
        if key in SQL_KEYS and entry.tag.endswith("entry"):
            val = decode_knime(entry.get("value") or "")
            if val.strip():
                out.append((key, val))
    return out

def sanitize(name):
    name = name.replace("(#", "_").replace(")", "").replace("#", "")
    name = re.sub(r"[^\w\-. ]", "_", name).strip()
    return re.sub(r"\s+", "_", name)

count = 0
index = []
for dirpath, dirnames, filenames in os.walk(SRC):
    if "settings.xml" not in filenames:
        continue
    node_name = os.path.basename(dirpath)
    sqls = find_sql(os.path.join(dirpath, "settings.xml"))
    if not sqls:
        continue
    rel = os.path.relpath(dirpath, SRC)
    parts = rel.split(os.sep)
    # parts[0] = workflow name, middle = components, last = node
    comp_path = os.path.join(*[sanitize(p) for p in parts[1:-1]]) if len(parts) > 2 else ""
    out_dir = os.path.join(DST, comp_path)
    os.makedirs(out_dir, exist_ok=True)
    base = sanitize(parts[-1])
    for i, (key, sql) in enumerate(sqls):
        suffix = f"_{i+1}" if len(sqls) > 1 else ""
        fname = f"{base}{suffix}.sql"
        fpath = os.path.join(out_dir, fname)
        header = f"-- Nodo KNIME : {rel}\n-- Clave      : {key}\n\n"
        with open(fpath, "w", encoding="utf-8") as f:
            f.write(header + sql.replace("\r\n", "\n").rstrip() + "\n")
        index.append(os.path.relpath(fpath, DST))
        count += 1

print(f"Extracted {count} SQL statements")
for p in sorted(index):
    print(" ", p)
