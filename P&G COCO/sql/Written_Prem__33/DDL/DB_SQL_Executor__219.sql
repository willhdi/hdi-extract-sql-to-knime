-- Nodo KNIME : P&G_COCO\Written Prem (#33)\DB SQL Executor (#219)
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
,row_number() over(order by ramo_prod) as id
,INTERMEDIARIO_LIDE AS COD_INTERMEDIARIO
,0 AS PARTICIPACION
,DOCUMENTO AS DOC
,VALOR_CEDIDO as VALOR_CEDIDO_CO
,SUCURSAL_prod AS COD_SUCURSAL
into #no_coco
from #cocorretaje_sn c
where marca_corretaje =0
