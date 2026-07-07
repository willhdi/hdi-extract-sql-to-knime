-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#64)\DB SQL Executor (#296)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/************************
Separamos casos  si
**************************/

if OBJECT_ID('tempdb.dbo.#si_coco','U') is not null drop table #si_coco

select *  
into #si_coco
from #cocorretaje_sn
where marca_corretaje =1



--select *  
--into #si_coco
--from #cocorretaje_sn
--where cocorretaje =1
