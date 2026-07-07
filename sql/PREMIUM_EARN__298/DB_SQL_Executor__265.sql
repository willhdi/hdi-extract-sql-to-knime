-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#298)\DB SQL Executor (#265)
-- Clave      : statement

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#change_comisiones_cedidas','U') is not null drop table #change_comisiones_cedidas



select 
PERIODO_CONTABLE
,CAST(SUCURSAL_PROD as int) as SUCURSAL_PROD
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
,Concepto_nivel_3
,'INTERFAZ_AUT' as Concepto_nivel_2 
,'Change in Unearned Premium' as Concepto_nivel_1 
,'PREMIUM EARNED' as Concepto_nivel_0 
,SUM(CHANGE)  as VALOR_CONCEPTO
INTO #change_comisiones_cedidas
from #Final_cedidas
group by
PERIODO_CONTABLE
,SUCURSAL_PROD
,RAMO_PROD
,POLIZA
,CERTIFICADO
,DOCUMENTO
,POLIZA
,INTERMEDIARIO_LIDE
,SBU
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
