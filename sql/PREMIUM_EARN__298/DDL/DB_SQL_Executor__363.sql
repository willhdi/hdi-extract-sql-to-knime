-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#298)\DB SQL Executor (#363)
-- Clave      : statement

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#com_directa','U') is not null drop table #com_directa

declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$

/********************
Descripción profit 
********************/
if OBJECT_ID('tempdb.dbo.#profit','U') is not null drop table #profit
SELECT distinct
MAPPED_SAPPROFITCENTER as PROFITCENTER,
DESCRIPTION as desc_profitcenter,
LEFT(LOB_G1,4) AS cod_sbu_sap,
LTRIM(SUBSTRING(LOB_G1, CHARINDEX('-', LOB_G1) + 1, LEN(LOB_G1))) as desc_sbu_sap
into #profit
FROM LIBERTY.[AMOCOM].[HOMOLOGA_PROFIT_CENTER]
where LTRIM(SUBSTRING(LOB_G1, CHARINDEX('-', LOB_G1) + 1, LEN(LOB_G1))) is not null
and   DESCRIPTION not in ('Vida Grupo Fenix','Transportes','Pesados Individual Mensual')



	
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
,sum(valor_reserva_contable_comision_bas_coa) as base
,sum(valor_reserva_contable_comision_web_coa)  as web
,a.profit_center as cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
into #com_directa
from liberty.[RESERVAS].[DIRECTA_RESERVA_INTERFAZ] as A
left join 
liberty.apoyo.dwh_sbu_ramo_prod t2 on a.ramo_prod = t2.ramo_prod 
left join
#profit t4 on a.profit_Center = t4.PROFITCENTER
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
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
