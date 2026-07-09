-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#368)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#directa_docu','U') is not null drop table #directa_docu



select
a.PERIODO_CONTABLE
,a.SUCURSAL_PROD
,a.RAMO_PROD
,a.poliza
,a.certificado
,a.recibo
,coalesce(b.documento,c.documento,1) as documento
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
into #directa_docu
from #directa_1 a
left join  #recibo2 b on a.ramo_prod = b.ramo_prod and a.poliza = b.poliza and a.certificado = b.certificado and a.recibo = b.recibo
left join  #pol c on a.ramo_prod = c.ramo_prod and a.poliza = c.poliza and a.certificado = c.certificado
