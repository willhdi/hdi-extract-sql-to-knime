-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#195)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#retornos_1','U') is not null drop table #retornos_1



select
PERIODO_CONTABLE
,SUCURSAL_PROD
,RAMO_PROD
,poliza
,certificado
,recibo - 1 as recibo
,SBU
,INTERMEDIARIO_LIDE
,SUM(VALOR_RETORNO) as VALOR_CONCEPTO
,cod_profitcenter
,desc_profitcenter
,SUBSTRING(LOB, 1, charindex('-', LOB)-1) as cod_sbu_sap 
,SUBSTRING(LOB, charindex('-', LOB)+1, len(LOB))  as desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
into #retornos_1
from #retorno_p
group by
PERIODO_CONTABLE
,SUCURSAL_PROD
,RAMO_PROD
,poliza
,certificado
,recibo
,SBU
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,LOB
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
