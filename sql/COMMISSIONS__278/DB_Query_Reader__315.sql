-- Nodo KNIME : P&G_COCO\COMMISSIONS (#278)\DB Query Reader (#315)
-- Clave      : sql_statement



select
PERIODO_CONTABLE,
sum(VALOR_CONCEPTO)
from #retornos_1 
group by periodo_contable
