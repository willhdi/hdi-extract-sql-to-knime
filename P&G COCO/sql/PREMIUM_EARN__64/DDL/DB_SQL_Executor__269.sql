-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#64)\DB SQL Executor (#269)
-- Clave      : statement

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#devengada_directa','U') is not null drop table #devengada_directa

declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$

	
--Directa

select 
a.PERIODO_CONTABLE_ANALISIS AS PERIODO_CONTABLE
,a.LLAVE
,a.SUCURSAL_PROD 
,t2.SBU
,a.RAMO_PROD
,a.RAMO_CONTABLE
,a.POLIZA
,a.CERTIFICADO
,a.documento
,a.INTERMEDIARIO_LIDE
,sum(A.valor_reserva_CONTABLE) as Change
,a.profit_center as cod_profitcenter1
,a.modalidad
into #devengada_directa
from liberty.[RESERVAS].[DIRECTA_RESERVA_INTERFAZ] as A
left join 
liberty.apoyo.dwh_sbu_ramo_prod t2 on a.ramo_prod = t2.ramo_prod 
--left join
--liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.ramo_prod and a.sucursal_prod = t4.sucursal and a.ramo_contable = t4.ramo_contable
WHERE PERIODO_CONTABLE_ANALISIS =@periodo_contable and a.CUENTA IN (410305,410310,410315,510305,510310,510315) AND  a.libro <> 'AG'
---between @periodo_contable_i and @periodo_contable_f
group by
a.PERIODO_CONTABLE_ANALISIS
,a.LLAVE
,a.SUCURSAL_PROD
,t2.SBU
,a.RAMO_PROD
,a.RAMO_CONTABLE
,a.POLIZA
,a.CERTIFICADO
,a.documento
,A.INTERMEDIARIO_LIDE
,a.profit_center
,a.modalidad
