-- Nodo KNIME : P&G_COCO\COMMISSIONS_ (#287)\DB SQL Executor (#327)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/*****************
UNION NO CORRETAJE CON LOS CASOS DE CORRETAJE
******************/

if OBJECT_ID('tempdb.dbo.#cocorretaje_completo_d','U') is not null drop table #cocorretaje_completo_d

select * 
into #cocorretaje_completo_d
from
(
SELECT * 
--,'no' as marca
FROM #no_coco_completo_d
UNION all
SELECT * FROM #caso1_d
--, 'caso1' as marca 
--union all
--SELECT * FROM #caso2_1
) a
