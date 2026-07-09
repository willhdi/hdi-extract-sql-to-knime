"""Genera notebooks/plan_ejecucion.json: el orden real de ejecucion de los
scripts SQL de cada componente del workflow P&G_COCO, obtenido por orden
topologico de las conexiones en los workflow.knime (recursivo en
subcomponentes). El notebook de emulacion consume este JSON.

Uso:  python tools/build_plan.py <dir_knwf_descomprimido> <raiz_repo>
"""
import json
import os
import re
import sys
import xml.etree.ElementTree as ET
from datetime import date

KNWF = sys.argv[1]
REPO = sys.argv[2]

NS = {"k": "http://www.knime.org/2008/09/XMLConfig"}


def sanitize(name):
    name = name.replace("(#", "_").replace(")", "").replace("#", "")
    name = re.sub(r"[^\w\-. ]", "_", name).strip()
    return re.sub(r"\s+", "_", name)


def cfg(parent, key):
    for c in parent.findall("k:config", NS):
        if c.get("key") == key:
            return c
    return None


def parse_workflow(wf_dir):
    """Devuelve (nodos {id: nombre_dir}, aristas [(src, dst)])."""
    root = ET.parse(os.path.join(wf_dir, "workflow.knime")).getroot()
    nodes = {}
    for node in cfg(root, "nodes").findall("k:config", NS):
        nid = fname = None
        for e in node.findall("k:entry", NS):
            if e.get("key") == "id":
                nid = int(e.get("value"))
            if e.get("key") == "node_settings_file":
                fname = e.get("value").split("/")[0]
        if nid is not None and fname:
            nodes[nid] = fname
    edges = []
    conns = cfg(root, "connections")
    if conns is not None:
        for conn in conns.findall("k:config", NS):
            src = dst = None
            for e in conn.findall("k:entry", NS):
                if e.get("key") == "sourceID":
                    src = int(e.get("value"))
                if e.get("key") == "destID":
                    dst = int(e.get("value"))
            if src in nodes and dst in nodes:
                edges.append((src, dst))
    return nodes, edges


def topo_order(nodes, edges):
    """Orden topologico estable (Kahn, desempate por id de nodo)."""
    indeg = {n: 0 for n in nodes}
    succ = {n: [] for n in nodes}
    for s, d in edges:
        indeg[d] += 1
        succ[s].append(d)
    ready = sorted(n for n, k in indeg.items() if k == 0)
    out = []
    while ready:
        n = ready.pop(0)
        out.append(n)
        for m in sorted(succ[n]):
            indeg[m] -= 1
            if indeg[m] == 0:
                ready.append(m)
        ready.sort()
    out += [n for n in nodes if n not in out]  # ciclos: al final
    return out


def collect_steps(wf_dir, sane_parts):
    """Recorre un (sub)workflow en orden topologico y devuelve los pasos SQL."""
    nodes, edges = parse_workflow(wf_dir)
    steps = []
    for nid in topo_order(nodes, edges):
        name = nodes[nid]
        node_dir = os.path.join(wf_dir, name)
        if os.path.exists(os.path.join(node_dir, "workflow.knime")):
            steps += collect_steps(node_dir, sane_parts + [sanitize(name)])
            continue
        if name.startswith("DB SQL Executor"):
            tipo = "executor"
        elif name.startswith("DB Query Reader"):
            tipo = "reader"
        else:
            continue
        base = sanitize(name) + ".sql"
        rel = None
        for clase in ("DDL", "DML"):
            cand = os.path.join("sql", *sane_parts, clase, base)
            if os.path.exists(os.path.join(REPO, cand)):
                rel = cand.replace("\\", "/")
                break
        if rel is None:
            continue  # nodo sin SQL extraido
        steps.append({
            "nodo": "/".join(sane_parts + [name]),
            "tipo": tipo,
            "clase": clase,
            "archivo": rel,
        })
    return steps


top = os.path.join(KNWF, "P&G_COCO")
nodes, edges = parse_workflow(top)
connected = {nodes[s] for s, _ in edges} | {nodes[d] for _, d in edges}
order = topo_order(nodes, edges)

componentes = []
seen = set()
for pass_conectado in (True, False):
    for nid in order:
        name = nodes[nid]
        node_dir = os.path.join(top, name)
        if not os.path.exists(os.path.join(node_dir, "workflow.knime")):
            continue
        if ((name in connected) != pass_conectado) or name in seen:
            continue
        seen.add(name)
        pasos = collect_steps(node_dir, [sanitize(name)])
        if not pasos:
            continue
        componentes.append({
            "nombre": sanitize(name),
            "titulo": name,
            "conectado": name in connected,
            "pasos": pasos,
        })

plan = {
    "generado": str(date.today()),
    "workflow": "P&G_COCO.knwf",
    "variable_flujo": "periodo_contable",
    "marcador_variable": "$${Speriodo_contable}$$",
    "componentes": componentes,
}
out_path = os.path.join(REPO, "notebooks", "plan_ejecucion.json")
os.makedirs(os.path.dirname(out_path), exist_ok=True)
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(plan, f, ensure_ascii=False, indent=1)

n = sum(len(c["pasos"]) for c in componentes)
print(f"{len(componentes)} componentes, {n} pasos -> {out_path}")
for c in componentes:
    tag = "conectado" if c["conectado"] else "AUTONOMO"
    print(f"  [{tag}] {c['titulo']}: {len(c['pasos'])} pasos")
