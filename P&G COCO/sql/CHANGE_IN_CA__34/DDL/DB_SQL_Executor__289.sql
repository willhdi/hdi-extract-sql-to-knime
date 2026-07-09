-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#289)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#reaseguro_siniestros_1','U') is not null drop table #reaseguro_siniestros_1



select
PERIODO_CONTABLE
--,SUCURSAL_PROD
,RAMO_PROD
,POLIZA AS POLIZA
,SBU
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,SUBSTRING(LOB_SAP, 1, charindex('-', LOB_SAP)-1) as cod_sbu_sap 
,SUBSTRING(LOB_SAP, charindex('-', LOB_SAP)+1, len(LOB_SAP))  as desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,0 AS Marca_corretaje
,COD_INTERMEDIARIO AS COD_INTERMEDIARIO
,0 AS PARTICIPACION
,COD_SUCURSAL AS COD_SUCURSAL
,sum(VALOR_CONCEPTO) as VALOR_CONCEPTO
into #reaseguro_siniestros_1
from #reaseguro_siniestros
group by
PERIODO_CONTABLE
,SBU
,RAMO_PROD
,POLIZA
--,SUCURSAL_PROD
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,LOB_SAP
,COD_INTERMEDIARIO
,COD_SUCURSAL
