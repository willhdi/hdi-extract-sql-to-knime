-- Nodo KNIME : Detalle_comisiones\DB Query Reader (#361)
-- Clave      : sql_statement



select
PERIODO_CONTABLE,
sum(VALOR_CONCEPTO)
from #no_coco_completo_d 
--where sucursal_prod is null
group by periodo_contable


---select
--*
--from  #retornos_docu
