# hdi-extract-sql-to-knime — SQL del workflow KNIME `P&G_COCO`

Este repositorio contiene **todas las sentencias SQL (475)** extraídas del workflow de KNIME
[`P&G_COCO.knwf`](P&G_COCO.knwf), organizadas por componente en la carpeta [`sql/`](sql/).

El workflow construye el **P&G técnico (Pérdidas y Ganancias) con distribución por cocorretaje**
sobre las bases de datos de HDI/Liberty en SQL Server: calcula cada concepto del estado de
resultados (prima emitida, prima devengada, siniestros, comisiones, gastos, impuestos, recobros,
salvamentos, costos XL, etc.) a nivel de póliza / intermediario / profit center y lo consolida
en tablas `PL_COL_DATOS_COCO`.

## Estructura del repositorio

```
├── P&G_COCO.knwf          # Workflow original de KNIME
├── sql/                   # SQL extraído, una carpeta por componente del workflow
│   ├── CHANGE_IN_CA__320/ # p. ej. componente "CHANGE_IN_CA (#320)"
│   │   ├── DB_Query_Reader__13.sql
│   │   ├── DB_SQL_Executor__8.sql
│   │   └── ...
│   └── ...
└── tools/
    └── extract_sql.py     # Script usado para extraer el SQL del .knwf
```

Cada archivo `.sql` corresponde a un nodo del workflow (`DB Query Reader` o `DB SQL Executor`)
e incluye en el encabezado la ruta del nodo dentro del workflow.

## Componentes del workflow

| Componente | Archivos SQL | Concepto del P&G (`Concepto_nivel_1`) | Fuentes principales |
|---|---:|---|---|
| `PREMIUM_EARN (#298)` | 70 | Change in Unearned Premium | `reservas.poliza_intermediario` |
| `PREMIUM_EARN (#64)` | 66 | Change in Unearned Premium | `reservas.poliza_intermediario`, `prod.dwh_polizas_h`, `claves_por_poliza` |
| `COMMISSIONS (#216)` | 60 | Commission Expense / Reinsurance Commission | `comercial.dwh_oc_remuneracion_tecnico_h`, `middleware.dwh_reaseguro_h`, `apoyo.dwh_intermediarios_total` |
| `COMMISSIONS (#278)` | 49 | Commission Expense | `amocom.directa`, `amocom.reaseguro`, `amocom.retornos` |
| `COMMISSIONS_ (#287)` | 48 | Commission Expense | `comercial.dwh_oc_remuneracion_tecnico_h`, `middleware.dwh_reaseguro_h` |
| `CHANGE_IN_CA (#320)` | 35 | Change in Case / Reinsurance Change in Case | `sini.dwh_s_nov_cont_d`, `sini.dwh_s_maestro_d`, `middleware.dwh_reaseguro_h` |
| `CHANGE_IN_CA (#34)` | 30 | Change in Case (L/V) / Reinsurance Change in Case | `sini.dwh_s_maestro_d`, `prod.dwh_polizas_h` |
| `SALVAMENTOS (#229)` | 24 | Salvamentos / Change in Case | `apoyo.dwh_profitcenter` |
| `RECOBROS (#230)` | 22 | Recovery | `apoyo.dwh_profitcenter` |
| `Written_Prem (#33)` | 16 | Written Premium – Ceded | `prod.dwh_polizas_h`, `reservas.cedidas`, `reservas.cedidas_iaxis` |
| `LOADS (#205)` | 15 | Assistances / Change in ALAE / Change in ULAE | `dbo.pl_manuales` |
| `Gross_Writte (#43)` | 11 | Gross Written Premium | `prod.dwh_pol_amp_h`, `puac.dwh_tipo_riesgo_puac` |
| `XL_Cost (#73)` | 9 | Costos XL | `liberty_pruebas_actuaria.dbo` |
| `GASTOS (#221)` | 8 | Unallocated UWE | `dbo.pl_manuales` |
| `IMPUESTOS (#225)` | 7 | Taxes, Licenses & Fees | `dbo.pl_manuales` |
| `Recobros_sin (#315)` | 5 | Change in Case (descuentos comerciales siniestros) | `dbo.pl_descuentos_comerciales_siniestros` |

## Bases de datos y tablas

- **`LIBERTY`** — data warehouse corporativo (solo lectura). Esquemas usados: `prod`, `sini`,
  `apoyo`, `comercial`, `middleware`, `reservas`, `amocom`, `puac`.
  Tablas más consultadas: `prod.DWH_POLIZAS_H`, `sini.DWH_S_NOV_CONT_D`, `sini.DWH_S_MAESTRO_D`,
  `apoyo.DWH_PROFITCENTER`, `amocom.HOMOLOGA_PROFIT_CENTER`, `middleware.DWH_REASEGURO_H`.
- **`LIBERTY_PRUEBAS_ACTUARIA`** — base de trabajo/staging de actuaría (lectura y escritura).
  Tablas clave: `PNL_HOMOLOGA_PROFIT` (homologación de profit centers, la más referenciada:
  117 usos), `PL_MANUALES`, `CLAVES_POR_POLIZA`, `PL_DESCUENTOS_COMERCIALES_SINIESTROS`.

**Tablas de salida** (cargadas vía nodos `DB Insert` / `DB Table Creator` e `INSERT INTO`):
`PL_COL_DATOS_COCO`, `PL_COL_DATOS`, `PL_COL_DATOS_COCO_UNIFICADO_RC`,
`PL_Comision_Reaseguro_HDI`, `PL_Distribucion_Conceptos_manuales`,
`PL_Homologacion_Contable_Ramos`, `PnL_Homologa_profit`, `RETORNOS_HDI`.

## Convenciones del SQL

- Dialecto: **T-SQL (Microsoft SQL Server)**; casi todos los scripts inician con
  `USE Liberty_pruebas_actuaria`.
- **Variable de flujo de KNIME**: `$${Speriodo_contable}$$` (periodo contable `YYYYMM`) aparece
  en 150 scripts; KNIME la reemplaza en tiempo de ejecución. Para ejecutar un script fuera de
  KNIME, sustitúyela por un literal, p. ej. `'202506'`.
- Uso intensivo de **tablas temporales** (`#sini_pagado`, `#cocorretaje_completo`,
  `#change_devengada_*`, …): los nodos `DB SQL Executor` crean las temporales dentro de una
  misma sesión y los `DB Query Reader` posteriores las leen. El orden de ejecución del
  workflow es, por tanto, significativo.
- Clasificación del P&G mediante columnas `Concepto_nivel_0` … `Concepto_nivel_3`
  (p. ej. `TOTAL_CLAIMS` → `CHANGE IN CASE` → `INTERFAZ_AUT` → `Pagado`).
- Dimensiones comunes de agregación: `PERIODO_CONTABLE`, `RAMO_PROD`, `POLIZA`, `SBU`,
  `INTERMEDIARIO_LIDE`, `COD_PROFITCENTER`, `COD_SUCURSAL`, `PARTICIPACION` (cocorretaje).

## Cómo se extrajo el SQL

Un archivo `.knwf` es un ZIP con un `settings.xml` por nodo. El script
[`tools/extract_sql.py`](tools/extract_sql.py):

1. Descomprime el workflow y recorre todos los `settings.xml`.
2. Toma las claves `sql_statement` / `statement` / `query` de la sección `model`.
3. Decodifica los escapes de KNIME (`%%00010` = salto de línea, `%%000NN` = carácter NN).
4. Escribe un `.sql` por nodo, agrupado por componente.

Para regenerar los archivos:

```bash
unzip P&G_COCO.knwf -d /tmp/knwf
python tools/extract_sql.py /tmp/knwf sql
```
