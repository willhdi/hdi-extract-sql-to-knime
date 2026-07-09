-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB SQL Executor (#235)
-- Clave      : statement

USE Liberty_Pruebas_Actuaria


--declare
--@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#r_iaxis_d','U') is not null drop table #r_iaxis_d

SELECT 
a.PERIODO_CONTABLE
,a.sucursal_prod
,a.ramo_contable
,t2.sbu
,a.ramo_prod
,a.poliza
,a.certificado
,a.documento
--,a.ano_siniestro
,a.radicado
,a.Intermediario_lide
,a.VLR_PAGADO_REC
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2 
,Concepto_nivel_1 
,Concepto_nivel_0 
into #r_iaxis_d
FROM #r_iaxis a
left join 
liberty.apoyo.dwh_sbu_ramo_prod t2 on a.RAMO_PROD = t2.ramo_prod 
--left join
--liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.RAMO_PROD and a.SUCURSAL_prod = t4.sucursal and a.ramo_contable = t4.ramo_contable
left join
(select distinct ramo_prod,ramo_contable,cod_profitcenter,desc_profitcenter,cod_sbu_sap,desc_sbu_sap from liberty.apoyo.dwh_profitcenter) t4 on t4.ramo_prod = a.RAMO_PROD and a.ramo_contable = t4.ramo_contable
