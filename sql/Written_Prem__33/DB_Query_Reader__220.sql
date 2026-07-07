-- Nodo KNIME : P&G_COCO\Written Prem (#33)\DB Query Reader (#220)
-- Clave      : sql_statement

/*select * from #primas_pyg */

select
--* 
--COUNT(*) 
sum(VALOR_CEDIDO)
from #cocorretaje_sn
