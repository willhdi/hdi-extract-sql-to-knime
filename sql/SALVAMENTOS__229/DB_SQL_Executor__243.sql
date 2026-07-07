-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB SQL Executor (#243)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/*****************
UNION NO CORRETAJE CON LOS CASOS DE CORRETAJE
******************/

if OBJECT_ID('tempdb.dbo.#cocorretaje_completo','U') is not null drop table #cocorretaje_completo

select * 
into #cocorretaje_completo
from
(
SELECT * 
FROM #no_coco
UNION all
SELECT * FROM #caso1
) a
