-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB Query Reader (#379)
-- Clave      : sql_statement



select
PERIODO_CONTABLE,
sum(VALOR_COncepto)
,concepto_nivel_2
from #directa_1
--where poliza = 515244 and certificado = 213
group by periodo_contable,concepto_nivel_2
