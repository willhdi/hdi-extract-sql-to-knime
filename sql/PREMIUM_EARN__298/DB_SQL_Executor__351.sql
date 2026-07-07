-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#298)\DB SQL Executor (#351)
-- Clave      : statement

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#com_directa','U') is not null drop table #com_directa

declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$
	
--Directa

select 
a.PERIODO_CONTABLE_ANALISIS AS PERIODO_CONTABLE
,a.sucursal as SUCURSAL_PROD
,t2.SBU
,a.RAMO_PROD
,a.RAMO_CONTABLE
,a.POLIZA
,a.CERTIFICADO
,a.recibo
,[dbo].[F_Conv_Cod_Agente](a.cagente) as INTERMEDIARIO_LIDE
,sum(valor_mensual_retorno) as Change
,a.profit_center
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
into #com_directa
from liberty.[RESERVAS].[RETORNOS_AMOCOM_INTERFAZ] as A

left join 
liberty.apoyo.dwh_sbu_ramo_prod t2 on a.ramo_prod = t2.ramo_prod 
left join
#profit t4 on a.profit_Center = t4.PROFITCENTER
--liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.ramo_prod and a.sucursal = t4.sucursal and a.ramo_contable = t4.ramo_contable
WHERE PERIODO_CONTABLE_ANALISIS =@periodo_contable and a.CUENTA IN (410305,410310,410315,510305,510310,510315) AND  a.libro <> 'AG'

---between @periodo_contable_i and @periodo_contable_f
group by
a.PERIODO_CONTABLE_ANALISIS
,a.SUCURSAL
,t2.SBU
,a.RAMO_PROD
,a.RAMO_CONTABLE
,a.POLIZA
,a.CERTIFICADO
,a.recibo
,A.cagente
,profit_center
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
