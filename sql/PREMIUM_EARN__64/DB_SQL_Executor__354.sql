-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#64)\DB SQL Executor (#354)
-- Clave      : statement

USE Liberty_Pruebas_Actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


--if OBJECT_ID('tempdb.dbo.#RT_reserva_inicial_terremoto','U') is not null drop table #RT_reserva_inicial_terremoto_2

update a
set INTERMEDIARIO_LIDE = 9400
from #devengada_dir_ter a
where sucursal_prod = 94 



update a
set a.INTERMEDIARIO_LIDE = b.INTERMEDIARIO_LIDE
from #devengada_dir_ter a 
left join liberty_pruebas_actuaria.dbo.claves_por_poliza_2 b on a.ramo_prod = b.ramo_prod and a.poliza = b.poliza
where a.INTERMEDIARIO_LIDE is null
