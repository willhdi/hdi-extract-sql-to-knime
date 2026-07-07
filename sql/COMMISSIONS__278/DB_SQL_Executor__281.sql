-- Nodo KNIME : P&G_COCO\COMMISSIONS (#278)\DB SQL Executor (#281)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#reaseguro_impuestos_1','U') is not null drop table #reaseguro_impuestos_1



select
PERIODO_CONTABLE
,SBU
,SUCURSAL_PROD
,INTERMEDIARIO_LIDE
,sum(cast(VALOR_RUBRO as bigint)) as VALOR_CONCEPTO
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
into #reaseguro_impuestos_1
from #reaseguro_impuestos
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
