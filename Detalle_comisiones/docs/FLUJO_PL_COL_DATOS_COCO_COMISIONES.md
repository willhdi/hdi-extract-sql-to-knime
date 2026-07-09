# ¿De dónde salen los datos de `PL_COL_DATOS_COCO_Comisiones`?

## Lo más importante, en una frase

`PL_COL_DATOS_COCO_Comisiones` es la tabla (`liberty_pruebas_actuaria.dbo.PL_COL_DATOS_COCO_Comisiones`,
servidor `wdbanal-dwhp01.hdicolombia.com.co`) donde queda el **detalle de comisiones** del negocio
compartido entre intermediarios (**cocorretaje**: cuando una póliza no la vende un solo intermediario
sino que se reparte entre varios). La arma un workflow de KNIME aparte, distinto al de `P&G_COCO`, llamado
**[`Detalle_comisiones.knwf`](../../Detalle_comisiones.knwf)**.

A diferencia de `PL_COL_DATOS_COCO` (que la llenan 8 procesos independientes por concepto de negocio:
prima, siniestros, comisiones, etc.), `PL_COL_DATOS_COCO_Comisiones` la llena **un solo workflow** que por
dentro calcula **5 "conceptos" de comisión en paralelo**, los une, los cruza con dos archivos Excel de
apoyo y los inserta de una sola vez. Después de esa carga, dos pasos adicionales completan/corrigen datos
directamente sobre la tabla ya cargada.

## Antes de la tabla: ¿qué significa "#403", "nodo", "DB SQL Executor"?

En este documento vas a ver referencias como `#403`, `#410`, `DB SQL Executor (#403)` o `UPDATE #403`.
Todo eso se refiere a lo mismo: **cada "cajita" del workflow de KNIME tiene un número de identificación
único**, que KNIME le pone automáticamente (no lo elige nadie, no tiene un orden de negocio). El `#` es
solo la forma de escribir ese número. Así que "el nodo #403" y "#403" son lo mismo.

Dentro de esas cajitas hay dos tipos que aparecen mucho en este flujo:

- **`DB SQL Executor`** — una cajita que ejecuta una sentencia SQL escrita a mano tal cual, contra la
  base de datos. Puede ser un `SELECT INTO` (arma una tabla temporal), o como en `#403` y `#410`, un
  **`UPDATE`** (modifica filas que ya existen en una tabla real). No devuelve una tabla de resultado hacia
  el resto del workflow, solo ejecuta el comando.
- **`DB Query Reader`** — ejecuta un `SELECT` y sí trae el resultado como una tabla para que el workflow
  siga trabajando con él.

Entonces, cuando este documento dice **"`DB SQL Executor (#403)`: UPDATE tomador/beneficiario/cuentas"**,
quiere decir: *"la cajita número 403 del workflow contiene un `UPDATE` de SQL escrito a mano, que corrige
datos de tomador, beneficiario y cuentas contables directamente sobre la tabla `PL_COL_DATOS_COCO_Comisiones`
que ya tiene los datos cargados"*. No es un paso que inserta filas nuevas — es un paso que **corrige/completa
columnas de filas que ya están ahí** (por eso corre después de la carga, no antes).

## Tabla resumen: cómo se alimenta la tabla, paso a paso

| Paso | Nodo(s) KNIME | Tipo de operación | ¿Qué lee? | ¿Qué hace con `PL_COL_DATOS_COCO_Comisiones`? |
|---|---|---|---|---|
| 1 | `DB SQL Executor` **#75** → … → `DB Query Reader` **#324** | `SELECT` que arma tablas temporales y las agrupa | `liberty.middleware.BASE_H` (cuentas 513095, 419595, 429595, 519585) | Calcula el concepto **Retornos**; todavía no toca la tabla final, solo prepara datos en memoria |
| 2 | `DB SQL Executor` **#76** → … → `DB Query Reader` **#325** | `SELECT` que arma tablas temporales y las agrupa | `liberty.middleware.BASE_H` (cuentas 511561, 511570, 411508, 511545) | Calcula el concepto **Comision_intermediacion**; todavía no toca la tabla final |
| 3 | `DB SQL Executor` **#77** → … → `DB Query Reader` **#207** | `SELECT` que arma tablas temporales y las agrupa | `liberty.middleware.BASE_REASEGUROS_H` (cuentas 411631, 511677) | Calcula el concepto **Comision_reaseguro**; todavía no toca la tabla final |
| 4 | `DB SQL Executor` **#214** → … → `DB Query Reader` **#216** | `SELECT` que arma tablas temporales y las agrupa | `liberty.comercial.DWH_OC_REMUNERACION_TECNICO_H` | Calcula el concepto **SobreComision**; todavía no toca la tabla final |
| 5 | `DB SQL Executor` **#231** → … → `DB Query Reader` **#311** | `SELECT` que arma tablas temporales y las agrupa | `liberty.AS400.F590475`, `liberty.AS400.REFPAGOS` | Calcula el concepto **Retornos_a**; todavía no toca la tabla final |
| 6a | `Concatenate` **#267 → #199 → #209 → #343** | Unión (UNION) de tablas, sin SQL propio | Los resultados de los pasos 1 a 5 | Junta los 5 conceptos en una sola tabla, en memoria (aún no se ha cargado nada) |
| 6b | `Joiner` **#200** y **#211** | Cruce (JOIN) con Excel, sin SQL propio | Excel `Canales y Sucursales.xlsx` (#48) y `Sucursales Andes 2023.xlsx` (#212) | Le agrega a esas filas el canal comercial y la sucursal |
| 6c | `Column Expressions` **#236**, `Row Filter` **#401** | Ajustes de columnas y filtro, sin SQL propio | — | Deja listas las columnas finales y filtra solo el `PERIODO_CONTABLE` que se va a cargar |
| 6d | `DB Insert` **#390** | **INSERT** (generado por KNIME, sin SQL escrito a mano) | El resultado del paso 6c | **Aquí se crean las filas**: inserta todo lo anterior dentro de `liberty_pruebas_actuaria.dbo.PL_COL_DATOS_COCO_Comisiones` |
| 7a | `DB SQL Executor` **#403** | **UPDATE** (SQL escrito a mano) | `liberty.apoyo.dwh_tomadores`, `LIBERTY.AMOCOM.RETORNOS_IAXIS`, `COMPANIA_CUENTAS_CUIF`, `COMPANIA_CUENTAS_SAP` | **Corrige filas que ya existen**: completa tomador, beneficiario y cuentas contables SAP/CUIF |
| 7b | `DB SQL Executor` **#410** | **UPDATE** (SQL escrito a mano) | `liberty.prod.dwh_pol_amp_h` | **Corrige filas que ya existen**: calcula el % de comisión de `Comision_intermediacion` |
| 8 | `Excel Reader` **#402/#408** → `DB Insert` **#405/#406** | INSERT (generado por KNIME) hacia otras tablas | Excel `Homologaciones_PUC_CUIF_SAP.xlsx` | No toca `PL_COL_DATOS_COCO_Comisiones` directamente — recarga `COMPANIA_CUENTAS_SAP`/`COMPANIA_CUENTAS_CUIF`, que el paso 7a necesita para funcionar |

**Para leer la tabla de un vistazo:** los pasos 1 a 6 son los que *crean* las filas (todo pasa en memoria
hasta el `DB Insert #390`, que es el único momento en que algo se escribe físicamente). Los pasos 7a y 7b
no crean filas nuevas, solo *editan* columnas de las filas que el paso 6 ya insertó. El paso 8 es un flujo
aparte que solo mantiene actualizadas dos tablas de apoyo que usa el paso 7a.

## Los 5 conceptos que se unen antes de cargar la tabla

| # | Concepto (`Concepto_nivel_3`) | Qué es, en palabras simples | Tabla(s) origen | SQL |
|---|---|---|---|---|
| 1 | **Retornos** | Devoluciones/reversiones de comisión ya pagada (ajustes negativos) | `liberty.middleware.BASE_H` (cuentas 513095, 419595, 429595, 519585) | [`sql/01_RETORNOS__75/`](../sql/01_RETORNOS__75/) |
| 2 | **Comision_intermediacion** | La comisión que la aseguradora le paga al intermediario por vender la póliza | `liberty.middleware.BASE_H` (cuentas 511561, 511570, 411508, 511545) | [`sql/02_COMISION_INTERMEDIACION__76/`](../sql/02_COMISION_INTERMEDIACION__76/) |
| 3 | **Comision_reaseguro** | La comisión que la aseguradora *recibe* del reasegurador (el seguro que la aseguradora le compra a otra compañía para protegerse de pérdidas grandes) como parte del contrato de reaseguro | `liberty.middleware.BASE_REASEGUROS_H` (cuentas 411631, 511677) | [`sql/03_COMISION_REASEGURO__77/`](../sql/03_COMISION_REASEGURO__77/) |
| 4 | **SobreComision** | Comisión adicional/bono que se le paga al intermediario por encima de la comisión normal | `liberty.comercial.DWH_OC_REMUNERACION_TECNICO_H` | [`sql/04_SOBRECOMISION__214/`](../sql/04_SOBRECOMISION__214/) |
| 5 | **Retornos_a** | Lo mismo que "Retornos" (devoluciones), pero viene de la interfaz contable **legado AS400** (mainframe antiguo), no del sistema actual | `liberty.AS400.F590475`, `liberty.AS400.REFPAGOS` | [`sql/05_RETORNOS_A__231/`](../sql/05_RETORNOS_A__231/) |

Los 5 conceptos usan la misma variable de KNIME `$${Speriodo_contable}$$` (periodo contable `YYYYMM`) para
filtrar desde qué mes traen datos, y todos cruzan adicionalmente con `liberty.apoyo.dwh_profitcenter` /
`liberty.apoyo.dwh_sbu_ramo_prod` para traer el profit center (unidad de negocio contable) y el SBU
(unidad estratégica de negocio).

## El flujo completo, paso a paso

```
[Conexión Liberty_pruebas_actuaria] ─┬─► RETORNOS (#75 → ... → #324)  ─────┐
                                      ├─► COMISION_INTERMEDIACION          │
                                      │   (#76 → ... → #325)         ──────┤
                                      ├─► COMISION_REASEGURO                │  UNION (Concatenate
                                      │   (#77 → #371 → #397 → #207) ───────┤   #267 → #199 → #209 → #343)
                                      ├─► SOBRECOMISION                     │
                                      │   (#214 → #215 → #216)      ───────┤
                                      └─► RETORNOS_A                        │
                                          (#231 → ... → #311)       ───────┘
                                                                             │
                        Excel "Canales y Sucursales.xlsx" (#48) ──Joiner #200
                        Excel "Sucursales Andes 2023.xlsx" (#212) ─Joiner #211
                                                                             │
                                          Column Expressions (#236, ajustes finales)
                                          Row Filter (#401, deja solo el PERIODO_CONTABLE a cargar)
                                                                             │
                                                                             ▼
                          DB Insert (#390)  ──►  liberty_pruebas_actuaria.dbo.PL_COL_DATOS_COCO_Comisiones
                                                                             │
                    (sin conexión de datos en el workflow; se asume orden lógico posterior)
                                                                             ▼
       DB SQL Executor (#403): UPDATE tomador/beneficiario/cuentas SAP-CUIF sobre la tabla ya cargada
                                                                             │
                                                                             ▼
       DB SQL Executor (#410): UPDATE que calcula el % de comisión (Comision_intermediacion)
```

Cada concepto (1 a 5) es, por dentro, una cadena de varios `DB SQL Executor` que arman tablas temporales
(`#retorno`, `#directa`, `#reaseguro`, `#sobre`, `#retorno_2`, `#cocorretaje_completo*`) sumando por
distintas combinaciones de cuenta/subcuenta contable (cada `UNION ALL` dentro de un mismo script suele
corresponder a una cuenta contable distinta del mismo concepto), y termina en un `DB Query Reader` que
agrupa (`GROUP BY`) el resultado final de ese concepto.

## Después de la carga: dos actualizaciones adicionales

Estos dos pasos **no están conectados en el grafo del workflow al `DB Insert (#390)`** — solo comparten la
misma conexión de base de datos (nodo `Microsoft SQL Server Connector #391`). Es decir, **KNIME no
garantiza el orden entre la carga y estas actualizaciones**; que corran después del insert es una
suposición razonable de negocio (no se puede completar el tomador o el % de comisión de filas que aún no
existen), pero no algo verificable en el propio workflow. Revísalo contra la ejecución real (log de
ejecución de KNIME) antes de asumirlo como definitivo.

- **`DB SQL Executor (#403)`** — [`sql/07_ACTUALIZACION_POST_CARGA__403_410/DML/DB_SQL_Executor__403.sql`](../sql/07_ACTUALIZACION_POST_CARGA__403_410/DML/DB_SQL_Executor__403.sql)
  Hace `UPDATE` directo sobre `pl_col_datos_coco_comisiones` para completar:
  - `DOCUMENTO` / `nombre_tomador` del tomador de la póliza, cruzando con `liberty.apoyo.dwh_tomadores`.
  - `documento_ben` / `nombre_beneficiario` del beneficiario de un retorno, cruzando con
    `LIBERTY.AMOCOM.RETORNOS_IAXIS` (solo para `Concepto_nivel_3 in ('Retornos','Retornos_a')`).
  - `cuenta`, `subcuenta`, `cuenta_CUIF`, `cuenta_SAP` — homologación de la cuenta contable local a los
    catálogos CUIF y SAP, cruzando con las tablas de referencia `COMPANIA_CUENTAS_CUIF` /
    `COMPANIA_CUENTAS_SAP` (ver más abajo), más algunos valores fijos para `SobreComision`.

- **`DB SQL Executor (#410)`** — [`sql/07_ACTUALIZACION_POST_CARGA__403_410/DDL/DB_SQL_Executor__410.sql`](../sql/07_ACTUALIZACION_POST_CARGA__403_410/DDL/DB_SQL_Executor__410.sql)
  Calcula el porcentaje de comisión (`porcentaje = comisión / prima`) para las filas de
  `Concepto_nivel_3 = 'Comision_intermediacion'`, usando `liberty.prod.dwh_pol_amp_h`. Lo hace en dos
  pasadas: primero con todos los movimientos, y para las pólizas que quedan sin porcentaje, repite el
  cálculo filtrando solo `tipo_transaccion in (1,2,9)`.

## Las tablas de referencia que usa el paso anterior

`COMPANIA_CUENTAS_SAP` y `COMPANIA_CUENTAS_CUIF` (ambas en `liberty_pruebas_actuaria.dbo`) **no las llena
este mismo flujo de comisiones**: las recarga, por separado, otro par de `DB Insert` (`#405` y `#406`) a
partir del mismo archivo Excel manual `Homologaciones_PUC_CUIF_SAP.xlsx` (leído dos veces, por los nodos
`Excel Reader #402` y `#408`). Ver [`sql/08_TABLAS_REFERENCIA_CUENTAS/`](../sql/08_TABLAS_REFERENCIA_CUENTAS/)
(carpeta sin SQL propio: son solo Excel Reader + DB Insert, KNIME arma el INSERT internamente).

## Los dos archivos Excel que se cruzan antes de cargar

Ambos son archivos manuales que mantiene un usuario del negocio, cargados por `Excel Reader`, no por SQL:

- `Canales y Sucursales.xlsx` (nodo `#48`)
- `Sucursales Andes 2023.xlsx` (nodo `#212`, un archivo "ANTIGUOS", posiblemente legado)

Ruta original (equipo local de un usuario, no un recurso compartido de KNIME Server):
`...\Gerencia de Datos - Documentos\BI\PROCESOS MENSUALES\Codigo PYG\Proceso PnL\Loads PnL\Archivos_manuales\`.

## Advertencias importantes (léelas antes de confiar en la tabla)

- **La carga es un `INSERT` puro, no un upsert.** El nodo `DB Insert (#390)` no está precedido por ningún
  `DELETE` ni `TRUNCATE` sobre `PL_COL_DATOS_COCO_Comisiones` dentro de este workflow. Si el proceso se
  re-ejecuta para el mismo `PERIODO_CONTABLE` sin borrar antes las filas de ese periodo (a mano o en otro
  proceso no incluido en este `.knwf`), **se duplicarían los datos**.
- **El orden `#390 → #403 → #410` es una suposición de negocio, no un hecho verificable en el grafo del
  workflow** (ver sección anterior).
- Hay **15 nodos `DB Query Reader`/`GroupBy` sueltos** (`#361, #369, #375, #378-#387, #388, #400`) que
  cuelgan de las mismas tablas temporales de los 5 conceptos, pero **no tienen ninguna conexión de salida**
  — parecen consultas de verificación/depuración que el desarrollador dejó pegadas al workflow. No
  alimentan `PL_COL_DATOS_COCO_Comisiones`. Su SQL igual se dejó extraído, en
  [`sql/99_CONSULTAS_SUELTAS_SIN_CONEXION/`](../sql/99_CONSULTAS_SUELTAS_SIN_CONEXION/), por transparencia.

## ¿Dónde está el SQL completo?

Todo el SQL real (las 56 consultas de este workflow, tal cual están en el proyecto, sin cambiar ni una
línea), unido en un solo archivo y en el orden de ejecución explicado arriba:

📄 [`sql/CONSOLIDADO_PL_COL_DATOS_COCO_COMISIONES/PL_COL_DATOS_COCO_Comisiones_completo.sql`](../sql/CONSOLIDADO_PL_COL_DATOS_COCO_COMISIONES/PL_COL_DATOS_COCO_Comisiones_completo.sql)

⚠️ **Importante:** ese archivo es solo para **leer y entender**, no para ejecutar tal cual contra una base
de datos real. Varias consultas de distintos conceptos reutilizan los mismos nombres de tabla temporal
(las que empiezan con `#`), así que si se corre todo junto se van a pisar entre sí. Cada consulta se debe
seguir ejecutando dentro de su propio grupo, como está organizado en las carpetas `sql/<grupo>/DDL|DML/`.

## Resumen para quien tenga prisa

- `PL_COL_DATOS_COCO_Comisiones` = tabla con el detalle de comisiones (pagadas, recibidas de reaseguro,
  sobrecomisión y devoluciones) del negocio de cocorretaje.
- La alimenta **un solo workflow de KNIME** (`Detalle_comisiones.knwf`), que calcula **5 conceptos en
  paralelo** (Retornos, Comision_intermediacion, Comision_reaseguro, SobreComision, Retornos_a), los une,
  los cruza con 2 Excel manuales de sucursales, filtra por periodo y hace un solo `DB Insert`.
- Después del insert, **dos `UPDATE` adicionales** completan tomador/beneficiario, cuentas contables
  SAP/CUIF y el porcentaje de comisión — pero **sin garantía de orden** dentro del workflow.
- Es un `INSERT` puro (no hay `DELETE`/`TRUNCATE` previo en este flujo): cuidado con re-ejecuciones que
  dupliquen el periodo.
- El SQL completo, comentado y sin modificar, está en
  [`sql/CONSOLIDADO_PL_COL_DATOS_COCO_COMISIONES/PL_COL_DATOS_COCO_Comisiones_completo.sql`](../sql/CONSOLIDADO_PL_COL_DATOS_COCO_COMISIONES/PL_COL_DATOS_COCO_Comisiones_completo.sql).

## Para profundizar
- [`sql/`](../sql/) — SQL extraído, organizado por grupo (`00`…`08`) y clasificado en `DDL/`/`DML/`.
- Referencia del workflow hermano (`P&G_COCO.knwf`, la tabla `PL_COL_DATOS_COCO` sin comisiones detalladas):
  [`../../P&G COCO/docs/GUIA_COMPLETA.md`](<../../P&G COCO/docs/GUIA_COMPLETA.md>).
