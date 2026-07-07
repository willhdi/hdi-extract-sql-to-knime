-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB SQL Executor (#254)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/************************
Separamos casos no y si
**************************/

---- Para el caso no cocorretaje se le agregan las columnas necesarias para 
---- el union al final del proceso 

if OBJECT_ID('tempdb.dbo.#no_coco','U') is not null drop table #no_coco

--select *  
--into #no_coco
--from #cocorretaje_sn
--where marca_corretaje =0
--if OBJECT_ID('tempdb.dbo.#no_coco','U') is not null drop table #no_coco

select 
c.*
,row_number() over(order by ramo_PROD) as id
,INTERMEDIARIO_LIDE AS COD_INTERMEDIARIO
,0 AS PARTICIPACION
,DOCUMENTO AS DOC
,VLR_PAGADO_REC as VLR_PAGADO_SAL_CO
,SUCURSAL_PROD AS COD_SUCURSAL
into #no_coco
from #cocorretaje_sn c
where marca_corretaje =0
