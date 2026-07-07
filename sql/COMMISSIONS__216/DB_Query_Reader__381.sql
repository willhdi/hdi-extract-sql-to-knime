-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB Query Reader (#381)
-- Clave      : sql_statement



select 
PERIODO_CONTABLE,
CONCEPTO_NIVEL_1,
CONCEPTO_NIVEL_2,
CONCEPTO_NIVEL_3,
sum(VALOR_CONCEPTO) as valor
from #retornos_docu
--where poliza = 515244 and certificado = 213
group by periodo_contable,
CONCEPTO_NIVEL_1,
CONCEPTO_NIVEL_2,
CONCEPTO_NIVEL_3
