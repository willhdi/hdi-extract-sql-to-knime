-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB Query Reader (#378)
-- Clave      : sql_statement



select 
PERIODO_CONTABLE,
concepto_nivel_2,
sum(VALOR_COMISION) as valor
from #directa
--where poliza = 515244 and certificado = 213
group by periodo_contable
,concepto_nivel_2
