-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#312)
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
FROM #no_coco
UNION all
SELECT * FROM #caso1

) a
