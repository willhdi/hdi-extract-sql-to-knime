-- Nodo KNIME : P&G_COCO\XL_Cost (#73)\DB SQL Executor (#66)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#costos_xl_co','U') is not null drop table #costos_xl_co


select 
p.PERIODO_CONTABLE
--,p.SUCURSAL_PROD
,p.RAMO_PROD
,p.poliza
--,p.certificado
--,p.documento
,p.SBU	
--,substring(m.HFM_LOB,1,4) as cod_sbu_sap_m
,p.INTERMEDIARIO_LIDE
,p.cod_profitcenter
,p.desc_profitcenter
,p.cod_sbu_sap	
,p.desc_sbu_sap
,'ANEXOS_MANUALES' AS Concepto_nivel_3	
,'ANEXOS_MANUALES' AS Concepto_nivel_2
,'COSTOS_XL' AS Concepto_nivel_1
,'NET_WRITTEN_PREMIUM' as Concepto_nivel_0
,Marca_corretaje
,COD_INTERMEDIARIO
,PARTICIPACION
--,DOC
,COD_SUCURSAL
,p.Suc_cont
,p.[Business Area]
,p.[Business Area_Des]
,p.Channel	
,p.Channel_Des
,p.[Tipo Canal]
,p.Canal_comercial
,p.Regional_comercial
,p.Sucursal_comercial
,p.Sucursal_plan_comercial
,sum(p.valor_concepto)*m.[Costo XL] VALOR_CONCEPTO
--,m.[Costo XL] AS load
--,'Load' origen
into #costos_xl_co
from #neta_xl_co p
left join 
		Liberty_pruebas_actuaria.dbo.PL_MANUALES m 
		on p.periodo_contable = m.periodocon and cast(p.cod_sbu_sap as varchar) = m.[centro de beneficio]
		--on p.periodo_contable = m.periodocon and cast(p.cod_profitcenter as varchar) = m.[centro de beneficio]
where p.periodo_contable  =$${Speriodo_contable}$$   --and Concepto_nivel_1 in ('GROSS_WRITTEN_PRIMIUM','WRITTEN_PREMIUM_CEDED')
group by  
p.PERIODO_CONTABLE
--,p.SUCURSAL_PROD
,p.SBU	
--,substring(m.HFM_LOB,1,4)
,p.INTERMEDIARIO_LIDE
,p.cod_profitcenter
,p.desc_profitcenter
,p.cod_sbu_sap	
,p.desc_sbu_sap
,Concepto_nivel_3	
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,p.Suc_cont
,p.[Business Area]
,p.[Business Area_Des]	
,p.Channel	
,p.[Channel_Des]
,p.[Tipo Canal]
,m.[Costo XL]
,p.Canal_comercial
,p.Regional_comercial
,p.Sucursal_comercial
,p.Sucursal_plan_comercial
,Marca_corretaje
,COD_INTERMEDIARIO
,PARTICIPACION
--,DOC
,COD_SUCURSAL
,p.RAMO_PROD
,p.poliza
--,p.certificado
--,p.documento
