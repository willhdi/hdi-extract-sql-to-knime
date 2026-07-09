-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#298)\DB SQL Executor (#354)
-- Clave      : statement

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#change_comisiones_retorno','U') is not null drop table #change_comisiones_retorno



select 
PERIODO_CONTABLE
,SUCURSAL_PROD
,RAMO_PROD
,POLIZA
,CERTIFICADO
,RECIBO
,SBU
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,'Retornos_comisiones' AS Concepto_nivel_3
,'INTERFAZ_AUT' as Concepto_nivel_2 
,'Change in Unearned Premium' as Concepto_nivel_1 
,'PREMIUM EARNED' as Concepto_nivel_0 
,SUM(Change) AS VALOR_CONCEPTO
INTO #change_comisiones_retorno
from #Final
---WHERE PERIODO_CONTABLE=$${Speriodo_contable}$$
group by
PERIODO_CONTABLE
,SUCURSAL_PROD
,RAMO_PROD
,POLIZA
,CERTIFICADO
,recibo
,INTERMEDIARIO_LIDE
,SBU
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
