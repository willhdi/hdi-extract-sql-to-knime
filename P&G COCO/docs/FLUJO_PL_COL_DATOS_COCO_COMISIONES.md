# ¿De dónde salen los datos de `PL_COL_DATOS_COCO`?

## Lo más importante, en una frase

`PL_COL_DATOS_COCO` es una tabla donde se guarda, ya calculado, todo el resultado financiero del negocio
compartido con otros intermediarios (a esto se le llama **"cocorretaje"**: cuando una póliza no la vende
un solo intermediario, sino que se reparte entre varios según un porcentaje llamado **PARTICIPACION**).

Esa tabla **no la llena una sola consulta SQL**. La llenan **8 procesos distintos** (en KNIME, la
herramienta que orquesta todo esto, cada proceso se llama "componente"). Cada componente calcula un
pedazo del negocio (prima, comisiones, siniestros, etc.) y al final KNIME toma ese resultado y lo inserta
en la tabla `PL_COL_DATOS_COCO`.

No existe ninguna tabla llamada `pl_col_datos_coco_comisiones` — ese nombre no aparece en el proyecto. Lo
que sí existe es un componente llamado `COMMISSIONS` que calcula las **comisiones** y las guarda dentro
de `PL_COL_DATOS_COCO` junto con todo lo demás.

## Los 8 procesos que alimentan la tabla

| # | Proceso | Qué calcula (en palabras simples) | Dónde está el SQL |
|---|---|---|---|
| 1 | **Gross Writte** | Cuánta prima (el dinero que paga el cliente por la póliza) se emitió en el periodo | [`sql/Gross_Writte__43/`](../sql/Gross_Writte__43/) |
| 2 | **Written Prem** | Cuánta de esa prima se le pasa al reasegurador (**reaseguro** = un seguro que la aseguradora le compra a otra compañía para protegerse de pérdidas grandes) | [`sql/Written_Prem__33/`](../sql/Written_Prem__33/) |
| 3 | **COMMISSIONS** | Cuánto se paga en comisiones a los intermediarios, y cuánta comisión se recibe del reasegurador | [`sql/COMMISSIONS__216/`](../sql/COMMISSIONS__216/) |
| 4 | **CHANGE_IN_CA (#320)** | Cómo cambió la reserva de siniestros (el dinero apartado para pagar reclamos que ya pasaron pero aún no se han pagado del todo) | [`sql/CHANGE_IN_CA__320/`](../sql/CHANGE_IN_CA__320/) |
| 5 | **CHANGE_IN_CA (#34)** | Lo mismo que el anterior, pero incluyendo lo que ya se pagó de siniestros | [`sql/CHANGE_IN_CA__34/`](../sql/CHANGE_IN_CA__34/) |
| 6 | **SALVAMENTOS** | Dinero recuperado al vender lo que quedó de un bien siniestrado (ej: los restos de un carro chocado) | [`sql/SALVAMENTOS__229/`](../sql/SALVAMENTOS__229/) |
| 7 | **RECOBROS** | Dinero recuperado de terceros o del reasegurador después de pagar un siniestro | [`sql/RECOBROS__230/`](../sql/RECOBROS__230/) |
| 8 | **Recobros_sin** | Ajustes/descuentos comerciales que se le aplican a esos recobros | [`sql/Recobros_sin__315/`](../sql/Recobros_sin__315/) |

Cada uno de estos 8 procesos termina con un paso de KNIME llamado "DB Insert", que es el que realmente
mete los datos ya calculados dentro de `PL_COL_DATOS_COCO`. Ese paso final no tiene un archivo SQL propio
en este repositorio porque KNIME lo genera internamente (no es una consulta que alguien haya escrito a
mano); en el SQL consolidado se marca con un comentario que dice `>>> Aquí KNIME ejecuta...` para que quede
claro dónde ocurre ese paso.

El orden de la tabla de arriba es el orden en el que, según la documentación del flujo completo
([`docs/FLUJO.md`](FLUJO.md)), se van disparando estos procesos. Los pasos 2→4→5→8 tienen conexiones
explícitas documentadas (uno depende del anterior). El orden de 6 y 7 respecto al resto no se pudo
confirmar con certeza — está marcado como suposición razonable en el archivo SQL.

## Sobre las comisiones en particular

El proceso `COMMISSIONS` calcula dos cosas:
- **Gasto de comisiones**: lo que la aseguradora le paga a los intermediarios por vender.
- **Comisión de reaseguro**: lo que la aseguradora recibe del reasegurador como parte del trato de
  reaseguro.

Para esto usa información que ya está en las bases de datos de la compañía (pólizas, intermediarios,
reaseguro, etc.) — **no lee ningún archivo Excel**. El único Excel que existe con nombre parecido a
"comisiones" (`Comisiones_HDI.xlsx`) se carga en una etapa inicial del flujo a una tabla llamada
`RETORNOS_HDI`, pero ninguna consulta del proceso `COMMISSIONS` la usa. Es decir, ese Excel se sube pero
queda sin conectar a este cálculo.

## ¿Dónde está el SQL completo?

Todo el SQL real (las 203 consultas de los 8 procesos, tal cual como están en el proyecto, sin cambiar
ni una línea) está unido en un solo archivo, en su propia carpeta, para que se pueda leer de principio a
fin en orden:

📄 [`sql/CONSOLIDADO_PL_COL_DATOS_COCO/PL_COL_DATOS_COCO_completo.sql`](../sql/CONSOLIDADO_PL_COL_DATOS_COCO/PL_COL_DATOS_COCO_completo.sql)

Ese archivo tiene comentarios explicativos en español simple pegados **encima** de cada consulta (sin
tocar el código original), para que se entienda qué hace cada pedazo sin necesidad de leer el SQL línea
por línea.

⚠️ **Importante:** ese archivo es solo para **leer y entender**, no para ejecutar tal cual contra una base
de datos real. Al pegar 203 consultas una detrás de otra, varias usan el mismo nombre de tabla temporal
(las que empiezan con `#`), así que si se corre todo junto se van a pisar entre sí. Cada consulta se debe
seguir ejecutando dentro de su propio proceso, como ya está organizado en las carpetas `sql/<proceso>/`.

## Resumen para quien tenga prisa

- `PL_COL_DATOS_COCO` = tabla final con toda la plata del negocio compartido (cocorretaje): prima,
  comisiones, siniestros, salvamentos, recobros.
- La llenan **8 procesos**, cada uno con su propio SQL, no uno solo.
- Las **comisiones** las calcula el proceso `COMMISSIONS`, usando datos de las bases de datos internas,
  **no un Excel**.
- El SQL completo, comentado y sin modificar, está en
  [`sql/CONSOLIDADO_PL_COL_DATOS_COCO/PL_COL_DATOS_COCO_completo.sql`](../sql/CONSOLIDADO_PL_COL_DATOS_COCO/PL_COL_DATOS_COCO_completo.sql).

## Para profundizar
- [`docs/FLUJO.md`](FLUJO.md) — detalle técnico completo de todo el workflow (no solo esta tabla).
- [`docs/EXPLICACION_FLUJO.md`](EXPLICACION_FLUJO.md) — explicación narrada del flujo, incluyendo las
  cargas desde Excel.
