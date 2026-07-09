-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#228)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#retorno_22','U') is not null drop table #retorno_22



select
PERIODO_CONTABLE
,SUCURSAL_PROD
,ramo_prod
,poliza
,certificado
,documento
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
,SUM(VALOR_RETORNO) as VALOR_CONCEPTO
,cuenta
,subcuenta
into #retorno_22
from #retorno_p
group by
PERIODO_CONTABLE
,SUCURSAL_PROD
,ramo_prod
,poliza
,certificado
,documento
,SBU
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,LOB
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,cuenta
,subcuenta
