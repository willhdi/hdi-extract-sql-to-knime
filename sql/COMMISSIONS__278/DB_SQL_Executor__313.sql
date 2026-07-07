-- Nodo KNIME : P&G_COCO\COMMISSIONS (#278)\DB SQL Executor (#313)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#retornos_docu','U') is not null drop table #retornos_docu



select
a.PERIODO_CONTABLE
,a.SUCURSAL_PROD
,a.RAMO_PROD
,a.poliza
,a.certificado
,a.recibo
,b.documento
,a.SBU
,a.INTERMEDIARIO_LIDE
,a.cod_profitcenter
,a.desc_profitcenter
,a.cod_sbu_sap
,a.desc_sbu_sap
,a.Concepto_nivel_3
,a.Concepto_nivel_2
,a.Concepto_nivel_1
,a.Concepto_nivel_0
,a.VALOR_CONCEPTO
into #retornos_docu
from #retornos_1 a
left join liberty.prod.dwh_polizas_h b
on a.ramo_prod = b.ramo_prod and a.poliza = b.poliza and a.certificado = a.certificado and a.recibo = b. recibo
