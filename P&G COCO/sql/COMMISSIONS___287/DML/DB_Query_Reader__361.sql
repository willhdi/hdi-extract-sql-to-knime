-- Nodo KNIME : P&G_COCO\COMMISSIONS_ (#287)\DB Query Reader (#361)
-- Clave      : sql_statement



select
PERIODO_CONTABLE,
sum(VALOR_CONCEPTO)
from #directa_1 
where sucursal_prod is null
group by periodo_contable


---select
--*
--from  #retornos_docu
