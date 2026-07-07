-- Nodo KNIME : P&G_COCO\COMMISSIONS_ (#287)\DB SQL Executor (#322)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/************************
Separamos casos  si
**************************/

if OBJECT_ID('tempdb.dbo.#si_coco_r2','U') is not null drop table #si_coco_r2

select *  
into #si_coco_r2
from #cocorretaje_sn_i
where marca_corretaje =1



--select *  
--into #si_coco
--from #cocorretaje_sn
--where cocorretaje =1
