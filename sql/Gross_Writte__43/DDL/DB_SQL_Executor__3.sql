-- Nodo KNIME : P&G_COCO\Gross Writte (#43)\DB SQL Executor (#3)
-- Clave      : statement

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#primas_pyg_inter','U') is not null drop table #primas_pyg_inter


select
PERIODO_CONTABLE
,SUCURSAL_PROD
,SBU
,INTERMEDIARIO_LIDE	
--,INTERMEDIARIO VALIDAR SI SE INCLUYE PARA LA VISTA DEL TABLERO REQUIERE MODIFICAR EN TODOS LOS OCNCEPTOS Y REPROCESAR
,sum(GROSS_WRITTEN_PREMIUM) as VALOR_CONCEPTO
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
into #primas_pyg_inter
from #primas_pyg
group by
PERIODO_CONTABLE
,SUCURSAL_PROD
,SBU
,INTERMEDIARIO_LIDE	
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
