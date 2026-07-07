-- Nodo KNIME : P&G_COCO\COMMISSIONS_ (#287)\DB SQL Executor (#373)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#retorno_p','U') is not null drop table #retorno_p

select
a.PERIODO_CONTABLE
,a.SBU
,a.SUCURSAL_PROD
,A.SUCURSAL_CONTABLE
,a.RAMO_PROD
,a.RAMO_CONTABLE
,a.poliza
,a.certificado
,a.recibo
,a.fi_documento
,a.ff_documento
,a.INTERMEDIARIO_LIDE
,a.INTERMEDIARIO_COCO
,a.VALOR_RETORNO
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,a.Concepto_nivel_3
,a.Concepto_nivel_2
,a.Concepto_nivel_1
,a.Concepto_nivel_0
into #retorno_p
from #retorno a
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.RAMO_PROD and t4.sucursal = a.SUCURSAL_PROD and t4.ramo_contable = a.ramo_contable
