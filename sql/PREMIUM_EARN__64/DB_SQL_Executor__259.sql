-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#64)\DB SQL Executor (#259)
-- Clave      : statement

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#devengada_soat','U') is not null drop table #devengada_soat


select 
a.PERIODO_CONTABLE AS PERIODO_CONTABLE
,a.SUCURSAL_PROD
,A.RAMO_PROD
,POLIZA
,CERTIFICADO
--,DOCUMENTO
,T2.SBU
,INTERMEDIARIO_LIDE
,a.cod_profitcenter
,'SOAT' as desc_profitcenter
,8500 as cod_sbu_sap
,'Compulsory Auto' as  desc_sbu_sap
,a.VALOR_CONCEPTO	
INTO #devengada_soat
from #FINAL_s a
left join 
liberty.apoyo.dwh_sbu_ramo_prod t2 on a.ramo_prod = t2.ramo_prod 
--left join
--(select  distinct cod_profitcenter,	desc_profitcenter,cod_sbu_sap,desc_sbu_sap from liberty.apoyo.dwh_profitcenter) t4 on t4.cod_profitcenter = a.cod_profitcenter
