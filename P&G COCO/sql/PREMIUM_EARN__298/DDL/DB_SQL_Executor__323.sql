-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#298)\DB SQL Executor (#323)
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
--,'no' as marca
FROM #no_coco_completo
UNION all
SELECT * FROM #caso1
--, 'caso1' as marca 
--union all
--SELECT * FROM #caso2_1
) a
