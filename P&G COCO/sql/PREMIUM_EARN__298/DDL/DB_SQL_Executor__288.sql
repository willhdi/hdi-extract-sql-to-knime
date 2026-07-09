-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#298)\DB SQL Executor (#288)
-- Clave      : statement

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#change_devengada_ced_ter','U') is not null drop table #change_devengada_ced_ter



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
,'Cedidas_terremoto_comisiones' AS Concepto_nivel_3
,'INTERFAZ_AUT' as Concepto_nivel_2 
,'Change in Unearned Premium' as Concepto_nivel_1 
,'PREMIUM EARNED' as Concepto_nivel_0
,SUM(VALOR_CONCEPTO) *-1 as VALOR_CONCEPTO 
INTO #change_devengada_ced_ter
from #devengada_ced_ter_comi
WHERE VALOR_CONCEPTO <> 0 and PERIODO_CONTABLE = $${Speriodo_contable}$$
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
