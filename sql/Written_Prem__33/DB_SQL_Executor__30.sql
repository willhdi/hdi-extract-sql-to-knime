-- Nodo KNIME : P&G_COCO\Written Prem (#33)\DB SQL Executor (#30)
-- Clave      : statement

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#cedidas_pyg','U') is not null drop table #cedidas_pyg

select 
periodo_contable AS PERIODO_CONTABLE,
sucursal_prod AS SUCURSAL_PROD,
SBU,
INTERMEDIARIO_LIDE
,Profit_nuevo as cod_profitcenter
,Descripcion_profit as desc_profitcenter
,SUBSTRING(LOB_SAP, 1, charindex('-', LOB_SAP)-1) COD_SBU 
,SUBSTRING(LOB_SAP, charindex('-', LOB_SAP)+1, len(LOB_SAP)) DESC_SBU
,sum(VALOR_CEDIDO)  as VALOR_CONCEPTO
, Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
into #cedidas_pyg
from #cedidas
group by
periodo_contable,
sucursal_prod,
SBU,
Profit_nuevo,
Descripcion_profit,
cod_sbu_sap,
desc_sbu_sap,
Intermediario_lide
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,LOB_SAP
