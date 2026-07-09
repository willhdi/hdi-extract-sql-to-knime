-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#215)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#sobre_1','U') is not null drop table #sobre_1



select
PERIODO_CONTABLE
,SBU
,SUCURSAL_PROD as SUCURSAL_PROD
,INTERMEDIARIO_LIDE AS INTERMEDIARIO_LIDE
,sum(VALOR_COMISION) as VALOR_CONCEPTO
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
into #sobre_1
from #sobre
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
