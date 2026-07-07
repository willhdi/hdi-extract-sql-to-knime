-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#298)\DB SQL Executor (#292)
-- Clave      : statement

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#change_devengada_dir_ter','U') is not null drop table #change_devengada_dir_ter



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
,'Directa_terremoto_comisiones' AS Concepto_nivel_3
,'INTERFAZ_AUT' as Concepto_nivel_2 
,'Change in Unearned Premium' as Concepto_nivel_1 
,'PREMIUM EARNED' as Concepto_nivel_0 
,SUM(CHANGE)*-1  as VALOR_CONCEPTO
INTO #change_devengada_dir_ter
from #Final_dir_terr
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
