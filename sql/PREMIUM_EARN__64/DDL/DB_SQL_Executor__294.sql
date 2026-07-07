-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#64)\DB SQL Executor (#294)
-- Clave      : statement

USE Liberty_Pruebas_Actuaria

if OBJECT_ID('tempdb.dbo.#Final','U') is not null drop table #Final

select 
LLAVE
,PERIODO_CONTABLE
,SUCURSAL_PROD
,trim(RAMO_PROD) as RAMO_PROD
,RAMO_CONTABLE
,POLIZA
,CERTIFICADO
,documento
,SBU
,cod_profitcenter
,desc_profitcenter
--,cod_sbu_sap
--,desc_sbu_sap
,SUBSTRING(LOB, 1, charindex('-', LOB)-1) as cod_sbu_sap 
,SUBSTRING(LOB, charindex('-', LOB)+1, len(LOB))  as desc_sbu_sap
,INTERMEDIARIO_LIDE
,sum(Change)*-1 as Change
--,LAG(sum(isnull(RRCNC,0)), 1,0) OVER (PARTITION BY LLAVE  ORDER BY LLAVE,PERIODO_CONTABLE)-sum(isnull(RRCNC,0)) AS Change
into #Final
from  #profit
group by 
LLAVE
,PERIODO_CONTABLE
,SUCURSAL_PROD
,RAMO_CONTABLE
,trim(RAMO_PROD)
,POLIZA
,CERTIFICADO
,DOCUMENTO
,SBU
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,LOB
