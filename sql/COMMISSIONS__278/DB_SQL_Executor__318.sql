-- Nodo KNIME : P&G_COCO\COMMISSIONS (#278)\DB SQL Executor (#318)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/*****************
UNION NO CORRETAJE CON LOS CASOS DE CORRETAJE
******************/

if OBJECT_ID('tempdb.dbo.#cocorretaje_completo_i','U') is not null drop table #cocorretaje_completo_i

select * 
into #cocorretaje_completo_i
from
(
SELECT * 
--,'no' as marca
FROM #no_coco_completo_i
UNION all
SELECT * FROM #caso1_i
--, 'caso1' as marca 
--union all
--SELECT * FROM #caso2_1
) a
