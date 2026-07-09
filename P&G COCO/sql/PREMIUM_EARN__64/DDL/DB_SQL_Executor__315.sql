-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#64)\DB SQL Executor (#315)
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
,row_number() over(order by poliza,certificado,documento) as id
,INTERMEDIARIO_LIDE AS COD_INTERMEDIARIO,
0 AS PARTICIPACION,
DOCUMENTO AS DOC,
--SUCURSAL_PROD AS COD_SUCURSAL,
VALOR_CONCEPTO as VALOR_CONCEPTO_CO
into #no_coco
from #cocorretaje_sn c
where marca_corretaje =0
