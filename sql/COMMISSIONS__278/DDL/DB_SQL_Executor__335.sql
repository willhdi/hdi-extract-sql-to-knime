-- Nodo KNIME : P&G_COCO\COMMISSIONS (#278)\DB SQL Executor (#335)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/************************
Separamos casos  si
**************************/

if OBJECT_ID('tempdb.dbo.#si_coco_r','U') is not null drop table #si_coco_r

select *  
into #si_coco_r
from #cocorretaje_sn_r
where marca_corretaje =1



--select *  
--into #si_coco
--from #cocorretaje_sn
--where cocorretaje =1
