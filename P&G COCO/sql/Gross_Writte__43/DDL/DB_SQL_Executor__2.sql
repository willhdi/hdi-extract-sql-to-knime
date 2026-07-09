-- Nodo KNIME : P&G_COCO\Gross Writte (#43)\DB SQL Executor (#2)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#primas_pyg','U') is not null drop table #primas_pyg

select
t1.PERIODO_CONTABLE
,t1.SSEGURO	
,t1.SUCURSAL_PROD
,t1.RAMO_PROD
,t1.RAMO_TECNICO
,case when t1.ramo_prod = '900753' and t1.ramo_contable not in (322,323,324) and  t3.cod_modalidad = 1  then 345 
	  when t1.ramo_prod = '900753' and t1.ramo_contable not in (322,323,324) and t3.cod_modalidad  = 2  then 335 
	  when t1.ramo_prod = '900753' and t1.ramo_contable not in (322,323,324) and t3.cod_modalidad  = 3  then 346 
	  when t1.ramo_prod = '900753' and t1.ramo_contable not in (322,323,324) and t3.cod_modalidad  = 4  then 343
	  else t1.RAMO_CONTABLE end as RAMO_CONTABLE
,t1.POLIZA	
,t1.CERTIFICADO	
,t1.DOCUMENTO	
,t1.ANEXO	
,SUM(t1.VR_PRIMA_DOCUMENTO) AS VR_PRIMA_DOCUMENTO --- Prima al 100%
,SUM(t1.VR_PRIMA_MN_ORIG) AS VR_PRIMA_MN_ORIG     --- Prima Contribución SOAT , para lo demas es la misma vr_prima_documento
,t2.SBU
,t1.FI_CERTIFICADO	
,t1.FF_CERTIFICADO	
,t1.FI_DOCUMENTO	
,t1.FF_DOCUMENTO	
,t1.FECHA_EXPE	
,t1.INTERMEDIARIO_LIDE
,t1.vr_p_p_sucursal as vr_p_sucursal
,t3.vr_p_p_sucursal	
,t1.FI_ANEXO	
,t1.FF_ANEXO
,case when t2.sbu = 'AUT' THEN t5.cod_uso_vehic else t3.COD_MODALIDAD end as modalidad	
,t3.cod_modalidad
,t1.TIPO_RIESGO
,t6.COD_TIPO_RIESGO
,sum(isnull(t1.vr_prima_documento, 0) - iif(t1.ramo_prod = 'AO', isnull(t1.vr_prima_mn_orig,0), 0) - iif(t1.ramo_prod = '900730',isnull(t1.vr_contribucion, 0), 0))  as VR_PRIMA_EMITIDA_DIRECTA
,sum(isnull(t1.vr_prima_documento, 0) - isnull(t1.vr_prima_documento_coa, 0)  - iif(t1.ramo_prod = 'AO', isnull(t1.vr_prima_mn_orig, 0), 0) - iif(t1.ramo_prod = '900730', isnull(t1.vr_contribucion, 0), 0)) as vlr_prima_cedida
,sum(isnull(t1.vr_prima_documento_coa, 0)  - iif(t1.ramo_prod = 'AO', isnull(t1.vr_prima_mn_orig, 0), 0) - iif(t1.ramo_prod = '900730', isnull(t1.vr_contribucion, 0), 0)) as GROSS_WRITTEN_PREMIUM
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,'INTERFAZ_AUT' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'GROSS_WRITTEN_PRIMIUM' AS Concepto_nivel_1
,'NET_WRITTEN_PREMIUM' AS Concepto_nivel_0
into #primas_pyg
from  liberty.prod.dwh_pol_amp_h t1
left join
liberty.prod.dwh_polizas_h t3 on t1.llave = t3.llave
left join 
liberty.apoyo.dwh_sbu_ramo_prod t2 on t1.ramo_prod = t2.ramo_prod
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = t1.ramo_prod and t4.sucursal = t1.sucursal_prod and t4.ramo_contable = t1.ramo_contable
left join 
liberty.[DT].[DWH_DT_AUT_AUTOS] t5 on t1.llave = t5.LLAVE_POL
left join 
(select * from liberty.puac.dwh_tipo_riesgo_puac where desc_tipo_riesgo is not null) t6 on t1.sseguro = t6.sseguro  and t1.documento = t6.documento
WHERE 
--t1.periodo_contable BETWEEN 202210 AND 202408
t1.periodo_contable >= @periodo_contable
group by
t1.PERIODO_CONTABLE
,t1.SSEGURO	
,t1.SUCURSAL_PROD
,t1.RAMO_PROD
,t1.RAMO_TECNICO
,t1.RAMO_CONTABLE
,t1.POLIZA	
,t1.CERTIFICADO	
,t1.DOCUMENTO	
,t1.ANEXO	
,t2.SBU
,t1.FI_CERTIFICADO	
,t1.FF_CERTIFICADO	
,t1.FI_DOCUMENTO	
,t1.FF_DOCUMENTO	
,t1.FECHA_EXPE	
,t1.INTERMEDIARIO_LIDE
,t1.vr_p_p_sucursal
,t3.vr_p_p_sucursal		
,t1.FI_ANEXO	
,t1.FF_ANEXO
,t3.cod_modalidad
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,t5.cod_uso_vehic
,t1.TIPO_RIESGO
,t6.cod_tipo_riesgo
