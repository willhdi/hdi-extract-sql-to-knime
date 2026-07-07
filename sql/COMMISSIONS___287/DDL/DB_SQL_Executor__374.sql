-- Nodo KNIME : P&G_COCO\COMMISSIONS_ (#287)\DB SQL Executor (#374)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#directa_p','U') is not null drop table #directa_p

---DIRECTA

select
a.PERIODO_CONTABLE
,a.SBU
,a.SUCURSAL_PROD
,a.SUCURSAL_CONTABLE
,a.RAMO_PROD
,a.ramo_contable
,a.poliza
,a.certificado
,a.recibo
,a.fi_documento
,a.ff_documento
,a.INTERMEDIARIO_LIDE
,a.VALOR_COMISION
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,a.Concepto_nivel_3
,a.Concepto_nivel_2
,a.Concepto_nivel_1
,a.Concepto_nivel_0
into #directa_p
from #directa a
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.RAMO_PROD and t4.sucursal = a.SUCURSAL_contable and t4.ramo_contable = a.ramo_contable
