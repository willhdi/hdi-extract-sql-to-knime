-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB SQL Executor (#281)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#reaseguro_siniestros_1','U') is not null drop table #reaseguro_siniestros_1



select
PERIODO_CONTABLE
,SBU
,SUCURSAL_PROD
,INTERMEDIARIO_LIDE
,sum(VALOR_CONCEPTO) as VALOR_CONCEPTO
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
into #reaseguro_siniestros_1
from #reaseguro_siniestros
group by
PERIODO_CONTABLE
,SBU
,SUCURSAL_PROD
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
