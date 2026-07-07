-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#329)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/************************
Separamos casos  si
**************************/

if OBJECT_ID('tempdb.dbo.#si_coco_d','U') is not null drop table #si_coco_d

select *  
into #si_coco_d
from #cocorretaje_sn_d
where marca_corretaje =1



--select *  
--into #si_coco
--from #cocorretaje_sn
--where cocorretaje =1
