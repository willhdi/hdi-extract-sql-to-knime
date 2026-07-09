-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB Query Reader (#375)
-- Clave      : sql_statement



select
PERIODO_CONTABLE,
concepto_nivel_2,
sum(VALOR_COMISION)
from #directa_p
--where poliza = 515244 and certificado = 213
group by periodo_contable,concepto_nivel_2
