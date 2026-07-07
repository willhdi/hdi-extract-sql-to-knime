-- Nodo KNIME : P&G_COCO\COMMISSIONS (#278)\DB SQL Executor (#206)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#reaseguro_1','U') is not null drop table #reaseguro_1



select
cast(PERIODO_CONTABLE as int) as PERIODO_CONTABLE
,SUCURSAL_PROD
,RAMO_PROD
,POLIZA
,CERTIFICADO
,n_movimiento as DOCUMENTO
,SBU
,INTERMEDIARIO_LIDE
,sum(VALOR_REASEGURO) as VALOR_CONCEPTO
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
into #reaseguro_1
from #reaseguro
group by
PERIODO_CONTABLE
,SBU
,SUCURSAL_PROD
,RAMO_PROD
,POLIZA
,CERTIFICADO
,n_movimiento
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
