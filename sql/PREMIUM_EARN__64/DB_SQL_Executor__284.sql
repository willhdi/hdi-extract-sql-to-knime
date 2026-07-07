-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#64)\DB SQL Executor (#284)
-- Clave      : statement

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#RT_reserva_inicial_cedidas','U') is not null drop table #RT_reserva_inicial_cedidas


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$

	
--Cedidas as400
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
,SUM(A.VALOR_RESERVA_CONTABLE) AS Change
--,t4.cod_profitcenter
--,t4.desc_profitcenter
--,t4.cod_sbu_sap
--,t4.desc_sbu_sap
,a.modalidad
--,concat(trim(A.RAMO_PROD),'-',A.POLIZA,'-',A.CERTIFICADO) as LLAVE 
--LAG(convert(date,concat(A.periodo_contable_analisis,'01')), 1,convert(date,concat(A.periodo_contable_analisis,'01'))) OVER (PARTITION BY A.SUCURSAL_PROD,trim(A.RAMO_PROD),A.POLIZA,A.CERTIFICADO,a.INTERMEDIARIO_LIDE ORDER BY A.SUCURSAL_PROD,trim(A.RAMO_PROD),A.POLIZA,A.CERTIFICADO,a.INTERMEDIARIO_LIDE,PERIODO_CONTABLE_ANALISIS) as fec_ant,
--datediff(month,LAG(convert(date,concat(A.periodo_contable_analisis,'01')), 1,convert(date,concat(A.periodo_contable_analisis,'01'))) OVER (PARTITION BY A.SUCURSAL_PROD,trim(A.RAMO_PROD),A.POLIZA,A.CERTIFICADO,a.INTERMEDIARIO_LIDE ORDER BY A.SUCURSAL_PROD,trim(A.RAMO_PROD),A.POLIZA,A.CERTIFICADO,a.INTERMEDIARIO_LIDE,PERIODO_CONTABLE_ANALISIS),convert(date,concat(A.periodo_contable_analisis,'01'))) diff,
--max(convert(date,concat(A.periodo_contable_analisis,'01'))) OVER (PARTITION BY A.SUCURSAL_PROD,trim(A.RAMO_PROD),A.POLIZA,A.CERTIFICADO,a.INTERMEDIARIO_LIDE) as fecha_max
into #RT_reserva_inicial_cedidas
from liberty.[RESERVAS].[CEDIDAS_RESERVA_INTERFAZ] as A
left join  
LIBERTY.RESERVAS.POLIZA_INTERMEDIARIO  inter on inter.ramo_prod = a.ramo_prod and inter.poliza = a.poliza and inter.certificado = a.certificado ---and inter.PERIODO_CONTABLE =a.periodo_contable_analisis
left join 
liberty.apoyo.dwh_sbu_ramo_prod t2 on a.ramo_prod = t2.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.ramo_prod and a.sucursal_lide = t4.sucursal and a.ramo_contable = t4.ramo_contable
WHERE PERIODO_CONTABLE_ANALISIS = @periodo_contable and a.cuenta in ('510305','410305') AND  a.libro <> 'AG'
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
--,t4.cod_profitcenter
--,t4.desc_profitcenter
--,t4.cod_sbu_sap
--,t4.desc_sbu_sap
,a.modalidad


UNION ALL

--- Cedidas Iaxis
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
,SUM(A.VALOR_RESERVA_CONTABLE) AS Change
--,t4.cod_profitcenter
--,t4.desc_profitcenter
--,t4.cod_sbu_sap
--,t4.desc_sbu_sap
,a.modalidad
--,concat(trim(A.RAMO_PROD),'-',A.POLIZA,'-',A.CERTIFICADO) as LLAVE 
from liberty.[RESERVAS].[CEDIDAS_RESERVA_INTERFAZ_IAXIS] a
left join  
LIBERTY.RESERVAS.POLIZA_INTERMEDIARIO  inter on inter.ramo_prod = a.ramo_prod and inter.poliza = a.poliza and inter.certificado = a.certificado
left join 
liberty.apoyo.dwh_sbu_ramo_prod t2 on a.ramo_prod = t2.ramo_prod 
--left join
--liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.ramo_prod  and a.sucursal_lide = t4.sucursal and a.ramo_contable = t4.ramo_contable
WHERE PERIODO_CONTABLE_ANALISIS = @periodo_contable and a.cuenta in ('510305','410305') AND  a.libro <> 'AG'
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
--,t4.cod_profitcenter
--,t4.desc_profitcenter
--,t4.cod_sbu_sap
--,t4.desc_sbu_sap
,a.modalidad
