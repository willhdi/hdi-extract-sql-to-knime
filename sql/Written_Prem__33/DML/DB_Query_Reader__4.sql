-- Nodo KNIME : P&G_COCO\Written Prem (#33)\DB Query Reader (#4)
-- Clave      : sql_statement

/*select * from #primas_pyg */

select
--* 
--COUNT(*) 
periodo_contable,sum(VALOR_CEDIDO)
from #primas_ced_rea
--#cedidas
group by periodo_contable
