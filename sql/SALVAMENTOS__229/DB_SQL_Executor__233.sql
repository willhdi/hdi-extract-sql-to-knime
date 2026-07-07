-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB SQL Executor (#233)
-- Clave      : statement

USE Liberty_Pruebas_Actuaria


--declare
--@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#s_As400_d','U') is not null drop table #s_as400_d
SELECT 
a.PERIODO_CONTABLE
,a.sucursal_prod
,a.ramo_contable
,t2.sbu
,a.ramo_prod
,a.poliza
,a.certificado
,a.documento
,a.ano_siniestro
,a.radicado
,a.Intermediario_lide
,a.VLR_PAGADO_SAL
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,'Salvamentos' AS Concepto_nivel_3
,'INTERFAZ_AUT' as Concepto_nivel_2 
,'SALVAMENTOS' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
into #s_as400_d
FROM #s_As400 a
left join 
liberty.apoyo.dwh_sbu_ramo_prod t2 on a.RAMO_PROD = t2.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.RAMO_PROD and a.SUCURSAL_prod = t4.sucursal and a.ramo_contable = t4.ramo_contable
