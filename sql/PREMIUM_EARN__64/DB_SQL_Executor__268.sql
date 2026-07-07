-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#64)\DB SQL Executor (#268)
-- Clave      : statement

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#change_devengada_directa','U') is not null drop table #change_devengada_directa



select 
PERIODO_CONTABLE
,SUCURSAL_PROD
,RAMO_PROD
,POLIZA
,CERTIFICADO
,DOCUMENTO
,SBU
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,'INTERFAZ_AUT' AS Concepto_nivel_3
,'INTERFAZ_AUT' as Concepto_nivel_2 
,'Change in Unearned Premium' as Concepto_nivel_1 
,'PREMIUM EARNED' as Concepto_nivel_0 
,SUM(Change) AS VALOR_CONCEPTO
INTO #change_devengada_directa
from #Final
---WHERE PERIODO_CONTABLE=$${Speriodo_contable}$$
group by
PERIODO_CONTABLE
,SUCURSAL_PROD
,RAMO_PROD
,POLIZA
,CERTIFICADO
,DOCUMENTO
,INTERMEDIARIO_LIDE
,SBU
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
