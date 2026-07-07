-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#298)\DB SQL Executor (#286)
-- Clave      : statement

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#devengada_dir_ter','U') is not null drop table #devengada_dir_ter

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



-- Directa Terremoto

select 
convert(date,concat(A.periodo_contable_analisis,'01')) as fecha
,a.PERIODO_CONTABLE_ANALISIS AS PERIODO_CONTABLE
,a.SUCURSAL_PROD
,a.sucursal_contable
,t2.SBU
,a.RAMO_PROD
,a.RAMO_CONTABLE
,a.POLIZA
,a.CERTIFICADO
,a.documento
,a.INTERMEDIARIO_LIDE
,a.fi_certificado
,a.ff_certificado
,sum(A.VALOR_RESERVA_CONTABLE_COMISION_BAS_COA) as base
,sum(A.VALOR_RESERVA_CONTABLE_COMISION_WEB_COA) as web
,concat(trim(A.RAMO_PROD),'-',A.POLIZA,'-',A.CERTIFICADO,'-',a.documento) as LLAVE 
,a.PROFIT_CENTER AS cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
into #devengada_dir_ter
from liberty.[RESERVAS].[DIRECTA_TERREMOTO_RESERVA_INTERFAZ] a
left join 
liberty.apoyo.dwh_sbu_ramo_prod t2 on a.ramo_prod = t2.ramo_prod 
left join
#profit t4 on a.profit_Center = t4.PROFITCENTER
--liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.ramo_prod and a.sucursal_prod = t4.sucursal and a.ramo_contable = t4.ramo_contable
WHERE PERIODO_CONTABLE_analisis = @periodo_contable and a.cuenta in ('410305','419595','510305') and fuente_interfaz ='TERR' AND  a.libro <> 'AG'
--PERIODO_CONTABLE_analisis >= 202112
group by 
a.PERIODO_CONTABLE_ANALISIS
,a.SUCURSAL_PROD
,a.sucursal_contable
,t2.SBU
,a.RAMO_PROD
,a.RAMO_CONTABLE
,a.POLIZA
,a.CERTIFICADO
,a.documento
,a.INTERMEDIARIO_LIDE	
,a.PROFIT_CENTER
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,a.fi_certificado
,a.ff_certificado
