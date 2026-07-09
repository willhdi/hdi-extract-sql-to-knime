-- Nodo KNIME : P&G_COCO\Gross Writte (#43)\DB SQL Executor (#219)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/************************
Separamos casos no y si
**************************/

---- Para el caso no cocorretaje se le agregan las columnas necesarias para 
---- el union al final del proceso 

if OBJECT_ID('tempdb.dbo.#no_coco','U') is not null drop table #no_coco

--select *  
--into #no_coco
--from #cocorretaje_sn
--where marca_corretaje =0
--if OBJECT_ID('tempdb.dbo.#no_coco','U') is not null drop table #no_coco

select 
a.PERIODO_CONTABLE
,a.SSEGURO	
--,a.SUCURSAL_PROD
,a.RAMO_PROD
,a.RAMO_TECNICO
,a.RAMO_CONTABLE
,a.POLIZA	
,a.CERTIFICADO	
,a.DOCUMENTO	
,a.ANEXO	
,a.SBU
,a.FI_CERTIFICADO	
,a.FF_CERTIFICADO	
,a.FI_DOCUMENTO	
,a.FF_DOCUMENTO	
,a.FECHA_EXPE	
,a.INTERMEDIARIO_LIDE
,a.vr_p_sucursal
,a.vr_p_p_sucursal	
,a.FI_ANEXO	
,a.FF_ANEXO
,a.cod_modalidad
,a.GROSS_WRITTEN_PREMIUM	
,a.cod_profitcenter
,a.desc_profitcenter
,a.cod_sbu_sap
,a.desc_sbu_sap
,a.Concepto_nivel_3
,a.Concepto_nivel_2
,a.Concepto_nivel_1
,a.Concepto_nivel_0
,a.Marca_corretaje
,INTERMEDIARIO_LIDE AS COD_INTERMEDIARIO,
VR_P_P_SUCURSAL AS PARTICIPACION,
DOCUMENTO AS DOC,
GROSS_WRITTEN_PREMIUM as GROSS_WRITTEN_PREMIUM_CO,
a.SUCURSAL_PROD AS COD_SUCURSAL
into #no_coco
from #cocorretaje_sucursal a
where marca_corretaje =0
