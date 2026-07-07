-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#371)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#reaseguro_1','U') is not null drop table #reaseguro_1



select
PERIODO_CONTABLE
,RAMO_PROD
,'' AS POLIZA
,SBU
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,SUBSTRING(LOB, 1, charindex('-', LOB)-1) as cod_sbu_sap 
,SUBSTRING(LOB, charindex('-', LOB)+1, len(LOB))  as desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,0 AS Marca_corretaje
,INTERMEDIARIO_LIDE AS COD_INTERMEDIARIO
,0 AS PARTICIPACION
,SUCURSAL_PROD AS COD_SUCURSAL
,sum(VALOR_REASEGURO) as VALOR_CONCEPTO
into #reaseguro_1
from #reaseguro_P
group by
PERIODO_CONTABLE
,SBU
,SUCURSAL_PROD
,RAMO_PROD
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,LOB
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
