-- Nodo KNIME : Detalle_comisiones\DB Query Reader (#387)
-- Clave      : sql_statement



select 
concepto_nivel_2,
sum(valor_concepto)
from #cocorretaje_sn_d
--where poliza = 515244 and certificado = 213
group by concepto_nivel_2
