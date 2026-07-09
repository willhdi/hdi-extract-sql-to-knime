-- Nodo KNIME : P&G_COCO\LOADS (#205)\DB SQL Executor (#208)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#neta_co','U') is not null drop table #neta_co


select 
p.PERIODO_CONTABLE
--,p.SUCURSAL_PROD
,p.RAMO_PROD
,P.POLIZA
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
,Marca_corretaje
,COD_INTERMEDIARIO
,PARTICIPACION
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
,Case  when Concepto_nivel_1 ='GROSS_WRITTEN_PRIMIUM' then p.VALOR_CONCEPTO 
	   when Concepto_nivel_1 ='WRITTEN PREMIUM-CEDED' THEN p.VALOR_CONCEPTO * -1 
	   ELSE valor_concepto END AS VALOR_CONCEPTO
into #neta_co
from liberty_pruebas_actuaria.DBO.[PL_COL_DATOS_COCO] p
left join 
		Liberty_pruebas_actuaria.dbo.PL_MANUALES m 
		on p.periodo_contable = m.periodocon and p.cod_sbu_sap = substring(m.HFM_LOB_1,1,4) and p.cod_profitcenter =m.[centro de beneficio]
where p.periodo_contable = $${Speriodo_contable}$$ and Concepto_nivel_1 in ('GROSS_WRITTEN_PRIMIUM','WRITTEN PREMIUM-CEDED')
