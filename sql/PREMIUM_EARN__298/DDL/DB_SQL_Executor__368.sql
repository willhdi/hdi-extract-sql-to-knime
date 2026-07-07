-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#298)\DB SQL Executor (#368)
-- Clave      : statement

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#devengada_dir_terr2','U') is not null drop table #devengada_dir_terr2

declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$

-- Directa Terremoto

select 
a.fecha
,a.PERIODO_CONTABLE
,a.SUCURSAL_PROD
,a.sucursal_contable
,a.SBU
,a.RAMO_PROD
,a.RAMO_CONTABLE
,a.POLIZA
,a.CERTIFICADO
,a.documento
,a.INTERMEDIARIO_LIDE
,a.fi_certificado
,a.ff_certificado
,coalesce(a.base + a.web,a.base)  as Change
,a.LLAVE 
,a.cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
into #devengada_dir_terr2
from #devengada_dir_ter a
