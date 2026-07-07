-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#197)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#directa_1','U') is not null drop table #directa_1



select
PERIODO_CONTABLE
,SUCURSAL_PROD
,RAMO_PROD
,POLIZA
,CERTIFICADO
,recibo - 1 as recibo
,SBU
,INTERMEDIARIO_LIDE
,sum(VALOR_COMISION) as VALOR_CONCEPTO
,cod_profitcenter
,desc_profitcenter
,SUBSTRING(LOB, 1, charindex('-', LOB)-1) as cod_sbu_sap 
,SUBSTRING(LOB, charindex('-', LOB)+1, len(LOB))  as desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
into #directa_1
from #directa_p
group by
PERIODO_CONTABLE
,SBU
,SUCURSAL_PROD
,RAMO_PROD
,POLIZA
,CERTIFICADO
,recibo
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,LOB
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
