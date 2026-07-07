-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#298)\DB SQL Executor (#284)
-- Clave      : statement

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#com_reserva_inicial_cedidas','U') is not null drop table #com_reserva_inicial_cedidas

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



	
--comision Cedidas as400
select 
--convert(date,concat(A.periodo_contable_analisis,'01')) as fecha,
a.PERIODO_CONTABLE_ANALISIS AS PERIODO_CONTABLE
,a.SUCURSAL_LIDE AS SUCURSAL_PROD
,t2.SBU
,a.RAMO_PROD
,a.RAMO_CONTABLE
,a.POLIZA
,a.CERTIFICADO
,a.documento
,inter.INTERMEDIARIO_LIDE
--,sum(A.valor_reserva) as RRCNC
,SUM(A.VALOR_COMISION_AMORTIZADO_MES) AS Change
,'Cedidas_AS_comisiones' AS Concepto_nivel_3
,a.profit_center as cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
--,concat(trim(A.RAMO_PROD),'-',A.POLIZA,'-',A.CERTIFICADO) as LLAVE 
--LAG(convert(date,concat(A.periodo_contable_analisis,'01')), 1,convert(date,concat(A.periodo_contable_analisis,'01'))) OVER (PARTITION BY A.SUCURSAL_PROD,trim(A.RAMO_PROD),A.POLIZA,A.CERTIFICADO,a.INTERMEDIARIO_LIDE ORDER BY A.SUCURSAL_PROD,trim(A.RAMO_PROD),A.POLIZA,A.CERTIFICADO,a.INTERMEDIARIO_LIDE,PERIODO_CONTABLE_ANALISIS) as fec_ant,
--datediff(month,LAG(convert(date,concat(A.periodo_contable_analisis,'01')), 1,convert(date,concat(A.periodo_contable_analisis,'01'))) OVER (PARTITION BY A.SUCURSAL_PROD,trim(A.RAMO_PROD),A.POLIZA,A.CERTIFICADO,a.INTERMEDIARIO_LIDE ORDER BY A.SUCURSAL_PROD,trim(A.RAMO_PROD),A.POLIZA,A.CERTIFICADO,a.INTERMEDIARIO_LIDE,PERIODO_CONTABLE_ANALISIS),convert(date,concat(A.periodo_contable_analisis,'01'))) diff,
--max(convert(date,concat(A.periodo_contable_analisis,'01'))) OVER (PARTITION BY A.SUCURSAL_PROD,trim(A.RAMO_PROD),A.POLIZA,A.CERTIFICADO,a.INTERMEDIARIO_LIDE) as fecha_max
into #com_reserva_inicial_cedidas
from liberty.[RESERVAS].[CEDIDAS_RESERVA_INTERFAZ] as A
left join  
LIBERTY.RESERVAS.POLIZA_INTERMEDIARIO  inter on inter.ramo_prod = a.ramo_prod and inter.poliza = a.poliza and inter.certificado = a.certificado ---and inter.PERIODO_CONTABLE =a.periodo_contable_analisis
left join 
liberty.apoyo.dwh_sbu_ramo_prod t2 on a.ramo_prod = t2.ramo_prod 
left join
#profit t4 on a.profit_Center = t4.PROFITCENTER
--liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.ramo_prod and a.sucursal_lide = t4.sucursal and a.ramo_contable = t4.ramo_contable
WHERE PERIODO_CONTABLE_ANALISIS = @periodo_contable and a.cuenta in ('510305','410305') AND a.libro <> 'AG'
group by
a.PERIODO_CONTABLE_ANALISIS 
,a.SUCURSAL_LIDE
,t2.SBU
,a.RAMO_PROD
,a.RAMO_CONTABLE
,a.POLIZA
,a.CERTIFICADO
,a.documento
,inter.INTERMEDIARIO_LIDE
,a.profit_center
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap


UNION ALL

--- comision Cedidas Iaxis
select 
a.PERIODO_CONTABLE_ANALISIS AS PERIODO_CONTABLE
,a.SUCURSAL_LIDE AS SUCURSAL_PROD
,t2.SBU
,a.RAMO_PROD
,a.RAMO_CONTABLE
,a.POLIZA
,a.CERTIFICADO
,a.documento
,inter.INTERMEDIARIO_LIDE
--,sum(A.valor_reserva) as RRCNC
,sum(valor_comision_amortizado_mes) AS Change
,'Cedidas_Iaxis_comisiones' AS Concepto_nivel_3
,a.profit_center as cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
--,concat(trim(A.RAMO_PROD),'-',A.POLIZA,'-',A.CERTIFICADO) as LLAVE 
from liberty.[RESERVAS].[CEDIDAS_RESERVA_INTERFAZ_IAXIS] a

left join  
LIBERTY.RESERVAS.POLIZA_INTERMEDIARIO  inter on inter.ramo_prod = a.ramo_prod and inter.poliza = a.poliza and inter.certificado = a.certificado
left join 
liberty.apoyo.dwh_sbu_ramo_prod t2 on a.ramo_prod = t2.ramo_prod 
left join
#profit t4 on a.profit_Center = t4.PROFITCENTER
--liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.ramo_prod  and a.sucursal_lide = t4.sucursal and a.ramo_contable = t4.ramo_contable
WHERE PERIODO_CONTABLE_ANALISIS = @periodo_contable and a.cuenta in ('510305','410305') AND a.libro <> 'AG'
group by
a.PERIODO_CONTABLE_ANALISIS 
,a.SUCURSAL_LIDE
,t2.SBU
,a.RAMO_PROD
,a.RAMO_CONTABLE
,a.POLIZA
,a.CERTIFICADO
,a.documento
,inter.INTERMEDIARIO_LIDE
,a.profit_center
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
