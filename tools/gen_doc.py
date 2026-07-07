"""Generate docs/FLUJO.md from analysis.json + hand-written component descriptions."""
import json
import sys

ANALYSIS = sys.argv[1]
OUT = sys.argv[2]

d = json.load(open(ANALYSIS, encoding="utf-8"))
comps = d["componentes"]

# Order and prose for each component section (business flow order).
SECTIONS = [
    ("Gross_Writte__43", "Gross Writte (#43) — Prima emitida bruta (Gross Written Premium)",
     "Calcula la **prima emitida bruta** del periodo. Lee la producción de pólizas desde "
     "`liberty.prod.DWH_POL_AMP_H`, clasifica el negocio con `liberty.puac.DWH_TIPO_RIESGO_PUAC`, "
     "homologa el profit center (`amocom.HOMOLOGA_PROFIT_CENTER` / `PNL_HOMOLOGA_PROFIT`) y reparte "
     "el valor entre intermediarios según la `PARTICIPACION` de cocorretaje. "
     "Su salida se inserta en `PL_COL_DATOS_COCO` (nodo `DB Insert (#260)`)."),
    ("Written_Prem__33", "Written Prem (#33) — Prima cedida (Written Premium – Ceded)",
     "Calcula la **prima cedida al reaseguro**. Cruza las pólizas (`prod.DWH_POLIZAS_H`) con las "
     "cesiones de `reservas.CEDIDAS` y `reservas.CEDIDAS_IAXIS`, y homologa profit center. "
     "Salida → `PL_COL_DATOS_COCO` (`DB Insert (#261)`). En el grafo del workflow este componente "
     "se ejecuta **antes** de `CHANGE_IN_CA (#320)` (hay una conexión de orden entre ambos)."),
    ("PREMIUM_EARN__64", "PREMIUM EARN (#64) — Variación de prima no devengada",
     "Calcula el **Change in Unearned Premium** (prima devengada) a partir del inventario de reservas "
     "de prima `reservas.POLIZA_INTERMEDIARIO`, apoyándose en `CLAVES_POR_POLIZA`/`CLAVES_POR_POLIZA_2` "
     "y `prod.DWH_POLIZAS_H` para atribuir póliza, intermediario y profit center. "
     "Construye numerosas temporales intermedias (`#devengada_*`, `#change_devengada_*`) para directa, "
     "cedida, SOAT y terremoto. Salida → `PL_COL_DATOS` (`DB Insert (#200)`)."),
    ("PREMIUM_EARN__298", "PREMIUM EARN (#298) — Variación de prima no devengada (versión cocorretaje)",
     "Segunda versión del cálculo de **Change in Unearned Premium**, orientada a la distribución por "
     "**cocorretaje**: arma la temporal `#cocorretaje_completo` con la participación de cada "
     "intermediario y reparte el concepto por `PARTICIPACION`. "
     "Salida → `PL_COL_DATOS` (`DB Insert (#296)`)."),
    ("COMMISSIONS__216", "COMMISSIONS (#216) — Comisiones (versión conectada al flujo)",
     "Calcula el **gasto de comisiones** (`COMMISSION EXPENSE`) y la **comisión de reaseguro** "
     "(`REINSURANCE_COMMISSION`). Fuentes: `comercial.DWH_OC_REMUNERACION_TECNICO_H` (remuneración de "
     "intermediarios), `middleware.DWH_REASEGURO_H` (cesiones) y `apoyo.DWH_INTERMEDIARIOS_TOTAL`. "
     "Contiene dos subcomponentes: `OTRAS COMISI (#276)` (otras comisiones/retornos) y `PROFIT (#275)` "
     "(atribución a profit center). Salida → `PL_COL_DATOS_COCO` (`DB Insert (#218)`)."),
    ("COMMISSIONS__278", "COMMISSIONS (#278) — Comisiones (variante AMOCOM, no conectada)",
     "Variante del cálculo de comisiones basada en las tablas `amocom.DIRECTA`, `amocom.REASEGURO` y "
     "`amocom.RETORNOS`. **No tiene conexiones en el nivel superior del workflow**, por lo que parece "
     "ser una versión previa o de ejecución manual. Mantiene los mismos subcomponentes "
     "`OTRAS COMISI` y `PROFIT`."),
    ("COMMISSIONS___287", "COMMISSIONS_ (#287) — Comisiones (variante, no conectada)",
     "Tercera variante del cálculo de comisiones, estructuralmente igual a la #216 "
     "(mismas fuentes `comercial.DWH_OC_REMUNERACION_TECNICO_H` y `middleware.DWH_REASEGURO_H`). "
     "**Sin conexiones en el nivel superior**: versión de respaldo/desarrollo."),
    ("CHANGE_IN_CA__34", "CHANGE_IN_CA (#34) — Movimiento de reservas de siniestros",
     "Calcula el **Change in Case** (variación de la reserva de siniestros avisados) sobre "
     "`sini.DWH_S_MAESTRO_D` y `prod.DWH_POLIZAS_H`, generando los conceptos `CHANGE IN CASE L`, "
     "`CHANGE IN CASE V` y `REINSURANCE CHANGE IN CASE`. "
     "Salida → `PL_COL_DATOS_COCO` (`DB Insert (#203)`). Tras su ejecución se dispara "
     "`Recobros_sin (#315)`."),
    ("CHANGE_IN_CA__320", "CHANGE_IN_CA (#320) — Siniestros pagados y change in case (versión cocorretaje)",
     "Calcula el **siniestro pagado** (`sini.DWH_S_NOV_CONT_D`, novedades tipo 5 y 6) y el "
     "**change in case** directo y cedido (`middleware.DWH_REASEGURO_H`), atribuyendo profit center y "
     "SBU, y distribuyendo por cocorretaje. Se ejecuta después de `Written Prem (#33)`. "
     "Salida → `PL_COL_DATOS_COCO` (`DB Insert (#322)`)."),
    ("Recobros_sin__315", "Recobros_sin (#315) — Descuentos comerciales de siniestros",
     "Ajusta el change in case con los **descuentos comerciales de siniestros** "
     "(`PL_DESCUENTOS_COMERCIALES_SINIESTROS`). Es el único componente que además hace un "
     "`INSERT INTO` directo por SQL a `PL_COL_DATOS_COCO_UNIFICADO_RC`; su otra salida va a "
     "`PL_COL_DATOS_COCO` (`DB Insert (#312)`). Depende de `CHANGE_IN_CA (#34)`."),
    ("SALVAMENTOS__229", "SALVAMENTOS (#229) — Ingresos por salvamentos",
     "Calcula los **salvamentos** (recuperación de bienes siniestrados) y su efecto en el change in "
     "case, con atribución de profit center vía `apoyo.DWH_PROFITCENTER`. "
     "Salida → `PL_COL_DATOS_COCO` (`DB Insert (#234)`)."),
    ("RECOBROS__230", "RECOBROS (#230) — Recobros (Recovery)",
     "Calcula los **recobros** a terceros/reaseguro (concepto `RECOVERY`), con la misma mecánica de "
     "temporales y homologación de profit center. Salida → `PL_COL_DATOS_COCO` (`DB Insert (#255)`)."),
    ("LOADS__205", "LOADS (#205) — Conceptos manuales: Assistances / ALAE / ULAE (autónomo)",
     "Distribuye **conceptos cargados manualmente** en `PL_MANUALES` (Assistances, Change in ALAE, "
     "Change in ULAE) usando `PL_Distribucion_Conceptos_manuales` como llave de reparto. "
     "No tiene conexiones en el nivel superior: se ejecuta de forma autónoma con su propio conector."),
    ("GASTOS__221", "GASTOS (#221) — Gastos no asignados (autónomo)",
     "Distribuye los **gastos de suscripción no asignados** (`UNALLOCATED UWE`) desde `PL_MANUALES`. "
     "Componente autónomo (sin conexiones en el nivel superior)."),
    ("IMPUESTOS__225", "IMPUESTOS (#225) — Impuestos y contribuciones (autónomo)",
     "Distribuye **Taxes, Licenses & Fees** desde `PL_MANUALES`. Componente autónomo."),
    ("XL_Cost__73", "XL_Cost (#73) — Costo de reaseguro no proporcional (autónomo)",
     "Calcula/distribuye el **costo de los contratos XL** (`COSTOS_XL`) sobre la base de trabajo de "
     "actuaría. Componente autónomo."),
]

def fmt_list(items, cap=3):
    items = [i.replace("[", "").replace("]", "") for i in items if len(i) > 2]  # drop alias artifacts like 'a'
    items = sorted(set(items))
    if not items:
        return ""
    shown = [f"`{i}`" for i in items[:cap]]
    if len(items) > cap:
        shown.append(f"… (+{len(items)-cap})")
    return "<br>".join(shown)

def comp_table(comp):
    rows = sorted(comps[comp], key=lambda f: (f["clase"], f["archivo"]))
    out = ["| Archivo | Tipo | Operaciones | Crea (temporal) | Escribe en (permanente) | Fuentes principales |",
           "|---|---|---|---|---|---|"]
    for f in rows:
        name = f["archivo"].split("/")[-1]
        link = f"[{name}](../sql/{f['archivo'].replace(' ', '%20')})"
        perm = fmt_list([t for t in f["insert_en"] + f["update_en"] if not t.startswith("#")], cap=2)
        srcs = fmt_list([s for s in f["fuentes"] if not s.startswith("#")], cap=3)
        tmps = fmt_list(f["temp_creadas"], cap=3)
        out.append(f"| {link} | **{f['clase']}** | {', '.join(f['ops'])} | {tmps} | {perm} | {srcs} |")
    return "\n".join(out)

L = []
A = L.append
A("# Flujo del workflow KNIME `P&G_COCO` — SQL organizado en DDL y DML\n")
A("Este documento explica **cada parte del flujo** y clasifica los 475 scripts SQL extraídos "
  "en **DDL** y **DML**. Los archivos están en [`sql/`](../sql/), con una carpeta por componente "
  "del workflow y subcarpetas `DDL/` y `DML/` dentro de cada una.\n")
A("## Criterio de clasificación DDL vs DML\n")
n_ddl = sum(1 for fl in comps.values() for f in fl if f["clase"] == "DDL")
n_dml = sum(1 for fl in comps.values() for f in fl if f["clase"] == "DML")
A(f"| Clase | Archivos | Criterio |\n|---|---:|---|\n"
  f"| **DDL** | {n_ddl} | El script crea o elimina objetos: `CREATE TABLE`, `DROP TABLE`, "
  f"`ALTER`, `TRUNCATE` o `SELECT … INTO` (que en T-SQL crea la tabla temporal destino). |\n"
  f"| **DML** | {n_dml} | El script solo consulta o manipula datos: `SELECT`, `INSERT`, "
  f"`UPDATE`, `DELETE`. |\n")
A("> **Nota:** casi todos los scripts DDL contienen también DML (el `SELECT` que puebla la "
  "temporal que crean). Se clasifican como DDL porque su efecto estructural —crear/eliminar "
  "tablas— es lo que condiciona el orden de ejecución del flujo. Los `DB SQL Executor` de KNIME "
  "suelen ser DDL (preparan temporales en la sesión) y los `DB Query Reader` suelen ser DML "
  "(leen el resultado hacia KNIME).\n")

A("## Parámetro del flujo\n")
A("Todo el workflow se parametriza con **una sola variable de flujo**: `periodo_contable` "
  "(formato `YYYYMM`), definida en el nodo `Variable Expressions (#70)` (último valor guardado: "
  "`'202512'`). Aparece en los scripts como `$${Speriodo_contable}$$` (150 archivos); KNIME la "
  "sustituye en tiempo de ejecución. El nodo #70 alimenta a los 9 componentes conectados y con "
  "ello define qué mes del P&G se procesa.\n")

A("## Diagrama general del flujo\n")
A("""```mermaid
flowchart TD
    VE["Variable Expressions (#70)<br>periodo_contable"]

    subgraph CARGAS["Etapa 0 — Cargas manuales desde Excel"]
        X1["Comisiones_HDI.xlsx"] --> T1[("RETORNOS_HDI")]
        X2["Homologacion_ramos.xlsx"] --> T2[("PL_Homologacion_Contable_Ramos")]
        X3["Comision_reaseguro_HDI.xlsx"] --> T3[("PL_Comision_Reaseguro_HDI")]
        X4["Distribucion_conceptos_manuales.xlsx"] --> T4[("PL_Distribucion_Conceptos_manuales")]
        X5["Homologa_profit_center.xlsx"] --> T5[("PnL_Homologa_profit")]
    end

    VE --> GWP["Gross Writte (#43)<br>Prima emitida bruta"]
    VE --> WPC["Written Prem (#33)<br>Prima cedida"]
    VE --> PE64["PREMIUM EARN (#64)<br>Prima devengada"]
    VE --> PE298["PREMIUM EARN (#298)<br>Prima devengada (coco)"]
    VE --> COM["COMMISSIONS (#216)<br>Comisiones"]
    VE --> CIC34["CHANGE_IN_CA (#34)<br>Reserva de siniestros"]
    VE --> SAL["SALVAMENTOS (#229)"]
    VE --> REC["RECOBROS (#230)"]

    WPC --> CIC320["CHANGE_IN_CA (#320)<br>Pagados + change in case (coco)"]
    CIC34 --> RSIN["Recobros_sin (#315)<br>Descuentos comerciales"]

    GWP --> COCO[("PL_COL_DATOS_COCO")]
    WPC --> COCO
    COM --> COCO
    CIC34 --> COCO
    CIC320 --> COCO
    SAL --> COCO
    REC --> COCO
    RSIN --> COCO
    RSIN --> UNIF[("PL_COL_DATOS_COCO_UNIFICADO_RC")]
    PE64 --> PLD[("PL_COL_DATOS")]
    PE298 --> PLD

    subgraph AUTONOMOS["Componentes autónomos (sin conexión en el nivel superior)"]
        LOADS["LOADS (#205)<br>Assistances / ALAE / ULAE"]
        GAS["GASTOS (#221)<br>Unallocated UWE"]
        IMP["IMPUESTOS (#225)<br>Taxes"]
        XL["XL_Cost (#73)<br>Costos XL"]
        C278["COMMISSIONS (#278)<br>variante AMOCOM"]
        C287["COMMISSIONS_ (#287)<br>variante"]
    end
```
""")
A("**Lectura del diagrama:** la variable `periodo_contable` dispara los componentes conectados; "
  "cada componente prepara sus tablas temporales con scripts **DDL**, las consulta con scripts "
  "**DML** y KNIME inserta el resultado en las tablas `PL_COL_DATOS*` de "
  "`LIBERTY_PRUEBAS_ACTUARIA` mediante nodos `DB Insert`. Las cargas de la Etapa 0 alimentan las "
  "tablas de homologación que los componentes usan como referencia.\n")

A("## Etapa 0 — Cargas manuales desde Excel\n")
A("Antes de los cálculos, el workflow carga 5 archivos Excel de la carpeta "
  "`PROCESOS MENSUALES/Codigo PYG/Proceso PnL/Loads PnL/` a tablas auxiliares "
  "(nodos `Excel Reader` → `DB Table Creator` → `DB Insert`, sin SQL manual):\n")
A("| Archivo Excel | Tabla destino (`LIBERTY_PRUEBAS_ACTUARIA.dbo`) | Uso |\n|---|---|---|\n"
  "| `Comisiones_HDI.xlsx` | `RETORNOS_HDI` | Retornos/comisiones manuales HDI |\n"
  "| `Homologacion_ramos.xlsx` | `PL_Homologacion_Contable_Ramos` | Mapa ramo contable ↔ ramo producto |\n"
  "| `Comision_reaseguro_HDI.xlsx` | `PL_Comision_Reaseguro_HDI` | % comisión de reaseguro |\n"
  "| `Distribucion_conceptos_manuales.xlsx` | `PL_Distribucion_Conceptos_manuales` | Llaves de reparto de conceptos manuales |\n"
  "| `Homologa_profit_center_202510.xlsx` | `PnL_Homologa_profit_202510` | Homologación de profit centers (la tabla `PNL_HOMOLOGA_PROFIT` es la más usada del flujo: 117 referencias) |\n")

A("## Componentes del flujo\n")
A("Cada componente sigue el mismo patrón interno:\n\n"
  "1. **DDL** — `DB SQL Executor`: `DROP TABLE` si existe + `SELECT … INTO #temporal` "
  "(construye los datos del concepto paso a paso en `tempdb`).\n"
  "2. **DML** — `DB Query Reader`: `SELECT` final sobre las temporales, agregado por "
  "periodo/ramo/póliza/intermediario/profit center.\n"
  "3. KNIME toma ese resultado y lo inserta con un nodo `DB Insert` en la tabla permanente.\n")

for key, title, desc in SECTIONS:
    fl = comps.get(key)
    if not fl:
        continue
    n_d = sum(1 for f in fl if f["clase"] == "DDL")
    n_m = len(fl) - n_d
    A(f"### {title}\n")
    A(desc + "\n")
    A(f"**Scripts:** {len(fl)} ({n_d} DDL, {n_m} DML) — carpeta [`sql/{key}/`](../sql/{key}/)\n")
    A("<details><summary>Ver detalle de los scripts</summary>\n")
    A(comp_table(key))
    A("\n</details>\n")

A("## Resumen de tablas de salida\n")
A("| Tabla (`LIBERTY_PRUEBAS_ACTUARIA.dbo`) | Alimentada por |\n|---|---|\n"
  "| `PL_COL_DATOS_COCO` | Gross Writte #43, Written Prem #33, COMMISSIONS #216, CHANGE_IN_CA #34 y #320, SALVAMENTOS #229, RECOBROS #230, Recobros_sin #315 |\n"
  "| `PL_COL_DATOS` | PREMIUM EARN #64 y #298 |\n"
  "| `PL_COL_DATOS_COCO_UNIFICADO_RC` | Recobros_sin #315 (INSERT directo por SQL) |\n"
  "| `RETORNOS_HDI`, `PL_Homologacion_Contable_Ramos`, `PL_Comision_Reaseguro_HDI`, `PL_Distribucion_Conceptos_manuales`, `PnL_Homologa_profit_*` | Cargas Excel (Etapa 0) |\n")

with open(OUT, "w", encoding="utf-8") as f:
    f.write("\n".join(L))
print(f"Wrote {OUT} ({len(L)} blocks)")
