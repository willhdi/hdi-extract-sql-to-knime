-- Nodo KNIME : P&G_COCO\XL_Cost (#73)\DB SQL Executor (#206)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#neta_xl','U') is not null drop table #neta_xl


select 
p.PERIODO_CONTABLE
,p.SUCURSAL_PROD
,p.SBU	
--,substring(m.HFM_LOB,1,4) as cod_sbu_sap_m
,p.INTERMEDIARIO_LIDE
,p.cod_profitcenter
,p.desc_profitcenter
,p.cod_sbu_sap	
,p.desc_sbu_sap
,Concepto_nivel_3	
,Concepto_nivel_2
, Concepto_nivel_1
, Concepto_nivel_0
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
,Case  when Concepto_nivel_1 ='GROSS_WRITTEN_PRIMIUM' then Valor_concepto else VALOR_CONCEPTO * -1 END AS VALOR_CONCEPTO
--,m.[Costo XL] AS load
--,'Load' origen
into #neta_xl
from liberty_pruebas_actuaria.DBO.[PL_COL_DATOS] p
left join 
		Liberty_pruebas_actuaria.dbo.PL_MANUALES m 
		on p.periodo_contable = m.periodocon and p.cod_sbu_sap = substring(m.HFM_LOB_1,1,4) and p.cod_profitcenter =m.[centro de beneficio]
where p.periodo_contable  =$${Speriodo_contable}$$  and Concepto_nivel_1 in ('GROSS_WRITTEN_PRIMIUM','WRITTEN PREMIUM-CEDED')
group by  
p.PERIODO_CONTABLE
,p.SUCURSAL_PROD
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
,p.valor_concepto
