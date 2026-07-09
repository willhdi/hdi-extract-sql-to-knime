-- Nodo KNIME : Detalle_comisiones\DB Query Reader (#380)
-- Clave      : sql_statement



select 
PERIODO_CONTABLE,
CONCEPTO_NIVEL_1,
CONCEPTO_NIVEL_2,
CONCEPTO_NIVEL_3,
sum(VALOR_RETORNO) as valor
from #retorno
--where poliza = 515244 and certificado = 213
group by periodo_contable,
CONCEPTO_NIVEL_1,
CONCEPTO_NIVEL_2,
CONCEPTO_NIVEL_3
