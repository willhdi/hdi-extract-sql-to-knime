# Acta de reunión — Retoma del proyecto "Técnico de comisiones desagregado"

> Documento generado a partir de la transcripción automática de una llamada de Microsoft Teams. Se
> corrigieron errores de transcripción, se organizó el contenido por temas y se explican los conceptos
> técnicos/de negocio para que el acta se entienda sin haber estado en la reunión. El contenido original
> es una transcripción por IA y puede contener imprecisiones puntuales frente a lo realmente dicho.

## Datos de la reunión

- **Fecha del documento:** 2026-07-09 (fecha de la transcripción; la fecha real de la reunión no queda
  registrada en el archivo original).
- **Duración registrada:** hasta el minuto ~23:53.
- **Tema:** estado y retoma del proyecto de **técnico de comisiones desagregado**, iniciado por David
  Ovalle y detenido por su salida de la compañía.

## Participantes

| Nombre | Rol en esta reunión |
|---|---|
| Paez Velandia, Santiago | Área solicitante / negocio (gestión de la demanda). Convocó la reunión y da el contexto del proyecto. |
| Carvajal Jaramillo, Karen Andrea | Jefe directo de Wilson Jerez. Lidera la parte de datos/técnica del proyecto. |
| Blanco Calderon, Johny German | Jefe de segundo orden de Wilson Jerez. Responde por el plan y los tiempos de estimación del equipo de datos. |
| Mayorga Garcia, Andrey | Equipo financiero/actuarial. Habla de P&L, validaciones y red comercial. |
| Camargo Riano, Fredy Andres | Equipo financiero. Encargado de las validaciones contables vs. técnicas (reemplaza en la explicación a Suani, quien está de vacaciones). |
| Gualdron Romero, Javier Leonardo | Asistente, sin intervenciones registradas. |
| *(Jerez Hernandez, Wilson Eduardo)* | No aparece como interlocutor en la transcripción (ver nota en "Compromisos"). |

## Resumen ejecutivo

Desde el año pasado existe un requerimiento del equipo de finanzas (elevado por el comité directivo) para
tener un **técnico de comisiones completamente desagregado**, es decir, un reporte que permita analizar el
detalle de las comisiones que paga la compañía a nivel de póliza, sponsor, sucursal, canal y producto, y no
solo en totales agregados.

Ese proyecto lo venía desarrollando **David Ovalle**, construyéndolo desde el **Data Warehouse** (no desde
el CDP, porque en su momento el CDP no tenía comisiones migradas). El trabajo para la línea **Iaxis** estaba
~90% terminado y ya validado con el equipo financiero; faltaba desarrollar la parte de **SIS**. David Ovalle
dejó de trabajar en la compañía antes de terminar, y el proyecto quedó a la mitad.

Al retomarlo, Karen Carvajal advierte un problema de fondo: **el Data Warehouse se va a dar de baja**, por lo
que la solución no debió construirse ahí desde el principio, sino sobre el **CDP**. Esto obliga a revisar
qué se puede reutilizar de lo que dejó David y a replantear el desarrollo sobre la plataforma correcta.

La reunión termina sin una fecha concreta de entrega: el equipo de Johny Blanco Calderon queda en enviar una
estimación de tiempos/plan para retomar el proyecto, y Santiago Paez Velandia queda a la espera de esa
fecha para informar al equipo financiero.

## Cronología y contexto de negocio

1. **Origen del requerimiento (min. 0:16 – 1:19):** el técnico de comisiones nace como una solicitud del
   equipo de finanzas dentro del Comité de Gestión de la Demanda. El objetivo es responder preguntas de
   cierre contable y permitir análisis más abiertos ("aperturados") sobre las comisiones que paga la
   compañía, algo que el comité directivo pidió explícitamente.
2. **Trabajo previo de David Ovalle (min. 1:19 – 2:22):** se descubrió, dentro del mismo comité, que David
   Ovalle ya venía haciendo un desarrollo muy similar. Se validó con él y se decidió continuar sobre su
   avance en lugar de empezar de cero. La parte correspondiente a **Iaxis** quedó ~90% lista y consolidada
   con el equipo financiero (Fredy Camargo y Suani); faltaba la parte de **SIS**. El proyecto quedó
   detenido cuando David dejó la compañía.
3. **Hallazgo sobre la plataforma (min. 2:22 – 2:29 y 17:35 – 17:58):** Karen Carvajal señala que el
   desarrollo se construyó sobre el Data Warehouse, plataforma que va a desaparecer, y que debió plantearse
   desde el CDP desde un inicio. Andrey Mayorga confirma que en la migración del modelo de **P&L** (el
   estado de resultados) no se incluyó nada de comisiones, así que ese flujo también hay que retomarlo
   desde cero en la plataforma nueva.
4. **Validaciones ya hechas y diferencias encontradas (min. 19:01 – 22:32):** Fredy Camargo explica que las
   diferencias detectadas en su momento eran pequeñas frente al volumen total de comisiones, pero
   difíciles de comparar porque la información contable (SAP/CUIF) usa dimensiones distintas a las del
   dato técnico. El método de validación es por niveles: primero cuadrar **totales**, luego bajar a
   **sucursal → canal → producto**. Ya se identificó que buena parte de las diferencias a nivel de sucursal
   vienen de **traslados y de la red comercial** (Andrey Mayorga: no estaba claro si el reporte debía
   actualizarse con la red comercial vigente o con la red **transaccional** de cada operación), algo que
   gerencia, producto y comercial ya tienen identificado.
5. **Cierre y próximos pasos (min. 22:32 – 23:53):** Johny Blanco Calderon reconoce que quedó pendiente
   confirmar cuándo entregarán la estimación/plan de trabajo. Santiago Paez Velandia pide que se lo envíen
   por correo para completar la fecha en su seguimiento, cancela las reuniones periódicas de este proyecto
   hasta que haya un reemplazo para el rol de David Ovalle, y se compromete a escalar el estado actual al
   equipo financiero para mantener la transparencia sobre el proyecto.

## Conceptos técnicos y de negocio mencionados

- **Técnico de comisiones (desagregado):** reporte/tabla con el detalle de las comisiones pagadas por la
  compañía, abierto a nivel de póliza, sponsor, sucursal, canal y producto, en lugar de un dato agregado.
  Es el mismo tipo de información que documenta este repositorio (ver
  [FLUJO_PL_COL_DATOS_COCO_COMISIONES.md](FLUJO_PL_COL_DATOS_COCO_COMISIONES.md)) para el caso de
  cocorretaje.
- **Data Warehouse (DWH) vs. CDP:** el DWH es la plataforma de datos "clásica" de la compañía, sobre la
  cual se construyó el desarrollo de David Ovalle; está próxima a desaparecer. El **CDP** es la plataforma
  de datos nueva a la que hay que migrar el desarrollo; en el momento en que David empezó, el CDP todavía
  no tenía la información de comisiones migrada, por eso se construyó en el DWH.
- **Iaxis / SIS (mencionado también como "CIS" en la transcripción, probablemente por error de
  transcripción):** son los dos grandes bloques/sistemas fuente sobre los que se construye el técnico de
  comisiones. Iaxis quedó prácticamente terminado; SIS es la parte que falta por desarrollar.
- **P&L:** estado de pérdidas y ganancias de la compañía. Se migró a un modelo nuevo que reemplaza al
  anterior, pero esa migración no incluyó el detalle de comisiones, por lo que ese flujo hay que
  construirlo de nuevo.
- **Validación por niveles (totales → sucursal → canal → producto):** metodología de control usada para
  confirmar que el dato técnico de comisiones coincide con lo que efectivamente llega a contabilidad
  (interfaces a SAP/CUIF). Primero se valida que el total cuadre; solo después tiene sentido revisar
  aperturas más finas, porque un descuadre en el nivel más agregado invalida cualquier lectura a detalle.
- **Red comercial vs. red transaccional:** dos formas distintas de asignar una comisión a una sucursal —
  según la red comercial vigente al momento del reporte, o según la sucursal registrada en la transacción
  original. La diferencia entre ambos criterios es una de las causas identificadas de descuadre a nivel de
  sucursal.
- **Interfaces / dimensiones SAP y CUIF:** la información técnica no es directamente comparable con la
  contable porque esta última viaja mapeada a las dimensiones y cuentas de SAP/CUIF (ver también las
  tablas `COMPANIA_CUENTAS_SAP` y `COMPANIA_CUENTAS_CUIF` en
  [FLUJO_PL_COL_DATOS_COCO_COMISIONES.md](FLUJO_PL_COL_DATOS_COCO_COMISIONES.md)). Parte del trabajo de
  validación consiste en tender el puente entre ambas vistas.

## Compromisos y próximos pasos

| # | Compromiso | Responsable | Fecha | Estado |
|---|---|---|---|---|
| 1 | Enviar plan/estimación de tiempos para retomar el proyecto de técnico de comisiones sobre la plataforma correcta (CDP) | Blanco Calderon, Johny German (equipo de datos) | Sin fecha definida; queda pendiente de comunicar | Pendiente |
| 2 | Enviar correo con la fecha de entrega una vez esté definida, para actualizar el seguimiento del proyecto | Paez Velandia, Santiago (a completar por el equipo de datos) | Sin fecha definida | Pendiente |
| 3 | Cancelar las reuniones periódicas de seguimiento de este proyecto hasta contar con reemplazo para el rol de David Ovalle | Paez Velandia, Santiago | Inmediato | En curso |
| 4 | Escalar/comunicar al equipo financiero el estado actual del proyecto (transparencia sobre lo encontrado y lo pendiente) | Paez Velandia, Santiago | Sin fecha definida | Pendiente |
| 5 | Recertificar que los datos de Iaxis se comportan igual que lo certificado con David Ovalle, con corte a junio | Mayorga Garcia, Andrey / equipo financiero (Camargo Riano, Fredy Andres) | A definir (mencionan "cierre de junio" como corte de referencia) | Pendiente |
| 6 | Retomar y documentar las diferencias encontradas en el primer análisis Iaxis (técnico vs. interfaces SAP) | Camargo Riano, Fredy Andres, con el dato que tiene Suani (pendiente su regreso de vacaciones) | Sin fecha definida | Pendiente |

### Nota sobre compromisos de Wilson Jerez / su equipo

En la transcripción **no hay ninguna intervención registrada a nombre de Jerez Hernandez, Wilson Eduardo**,
por lo que no se le asigna ningún compromiso explícito por nombre. Sin embargo, dado que tanto Karen
Carvajal (jefe directo) como Johny Blanco Calderon (jefe de segundo orden) son quienes representan al
equipo de datos y quedan comprometidos con el **compromiso #1** (plan/estimación para retomar el proyecto
sobre CDP), es razonable esperar que ese trabajo recaiga, total o parcialmente, sobre el equipo de Wilson.
Se recomienda confirmar directamente con Karen Carvajal qué parte de ese plan le corresponde a él.
