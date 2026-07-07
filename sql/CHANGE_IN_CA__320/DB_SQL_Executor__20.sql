-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB SQL Executor (#20)
-- Clave      : statement

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#sini_incurrido_pyg','U') is not null drop table #sini_incurrido_pyg

Select 
periodo_contable AS PERIODO_CONTABLE
,SUCURSAL_PROD
,intermediario_lide AS INTERMEDIARIO_LIDE
,SBU
,sum(VR_INCURRIDO_NETO) AS VALOR_CONCEPTO
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,'Incurrido' AS Concepto_nivel_3
,'INTERFAZ_AUT' as Concepto_nivel_2 
,'CHANGE IN CASE' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
into #sini_incurrido_pyg
from #sini_incurrido
group by 
periodo_contable,
SUCURSAL_PROD,
intermediario_lide,
SBU,
cod_profitcenter,
desc_profitcenter,
cod_sbu_sap,
desc_sbu_sap
