-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#298)\DB SQL Executor (#269)
-- Clave      : statement

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#com_directa_1','U') is not null drop table #com_directa_1

declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$
	
--Directa

select 
a.PERIODO_CONTABLE
,a.LLAVE
,a.SUCURSAL_PROD 
,a.SBU
,a.RAMO_PROD
,a.RAMO_CONTABLE
,a.POLIZA
,a.CERTIFICADO
,a.documento
,a.INTERMEDIARIO_LIDE
,a.base 
,a.web
,coalesce(a.base + a.web,a.base)  as Change
,a.cod_profitcenter
,a.desc_profitcenter
,a.cod_sbu_sap
,a.desc_sbu_sap
into #com_directa_1
from #com_directa as A
