-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#298)\DB SQL Executor (#290)
-- Clave      : statement

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#devengada_ced_ter_comi','U') is not null drop table #devengada_ced_ter_comi


select 
a.PERIODO_CONTABLE_ANALISIS AS PERIODO_CONTABLE
,a.SUCURSAL_PROD
,a.RAMO_PROD
,a.POLIZA
,a.CERTIFICADO
,a.DOCUMENTO
,t2.SBU
,a.INTERMEDIARIO_LIDE
,a.RAMO_CONTABLE
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,a.VALOR_CONCEPTO AS VALOR_CONCEPTO	
into #devengada_ced_ter_comi
from #Final_tcc a
left join 
liberty.apoyo.dwh_sbu_ramo_prod t2 on a.ramo_prod = t2.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.ramo_prod and a.sucursal_prod = t4.sucursal and a.ramo_contable = t4.ramo_contable
---WHERE PERIODO_CONTABLE >= 202209
