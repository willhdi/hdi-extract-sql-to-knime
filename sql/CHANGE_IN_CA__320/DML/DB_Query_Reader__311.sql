-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB Query Reader (#311)
-- Clave      : sql_statement

select 
*
--sum(vr_incurrido)
from #sini_incurrido
where ramo_prod = 'BO'
