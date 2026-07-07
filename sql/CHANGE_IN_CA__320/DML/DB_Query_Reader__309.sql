-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB Query Reader (#309)
-- Clave      : sql_statement

select 
*
--sum(vr_incurrido)
from #profit
where ramo_prod = 'BO'
