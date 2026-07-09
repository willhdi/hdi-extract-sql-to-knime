-- Nodo KNIME : Detalle_comisiones\DB Query Reader (#369)
-- Clave      : sql_statement



select  
PERIODO_CONTABLE,
concepto_nivel_2,
sum(VALOR_CONCEPTO)
from #directa_docu
--where poliza = 515244 and certificado = 213
group by periodo_contable,concepto_nivel_2
