-- Nodo KNIME : P&G_COCO\Written Prem (#33)\DB SQL Executor (#29)
-- Clave      : statement

USE Liberty_pruebas_actuaria

declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$

if OBJECT_ID('tempdb.dbo.#primas_ced_rea','U') is not null drop table #primas_ced_rea


select 
ced.periodo_contable,
ced.sucursal as sucursal_prod,
sbu.SBU,
ced.ramo as ramo_prod,
ced.ramo_rea,
case when ced.ramo = '900753' and ced.ramo_contable not in (322,323,324) and  t3.modalidad = 1  then 345 
	  when ced.ramo = '900753' and ced.ramo_contable not in (322,323,324) and t3.modalidad  = 2  then 335 
	  when ced.ramo = '900753' and ced.ramo_contable not in (322,323,324) and t3.modalidad  = 3  then 346 
	  when ced.ramo = '900753' and ced.ramo_contable not in (322,323,324) and t3.modalidad  = 4  then 343
	  else ced.RAMO_CONTABLE end as RAMO_CONTABLE,
ced.poliza,
ced.certificado,
ced.documento,
t3.modalidad as cod_modalidad,
--SUM(ced.valor_cesion) AS VALOR_CESION,
sum(ced.valor_cedido) as VALOR_CEDIDO,
pro.cod_profitcenter,
pro.desc_profitcenter,
pro.cod_sbu_sap,
pro.desc_sbu_sap
,'INTERFAZ_AUT' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'WRITTEN PREMIUM-CEDED' AS Concepto_nivel_1
,'NET_WRITTEN_PREMIUM' AS Concepto_nivel_0
,'Iaxis' as Fuente
into #primas_ced_rea
from liberty.reservas.CEDIDAS_IAXIS ced
left join 
liberty.apoyo.dwh_sbu_ramo_prod sbu on ced.ramo = sbu.ramo_prod 
--left join
--liberty.prod.dwh_polizas_h t3 on ced.ramo = t3.ramo_prod and ced.poliza = t3.poliza and ced.certificado = t3.certificado and ced.documento = t3.documento
left join  liberty.[RESERVAS].[POLIZA_MODALIDAD] t3 on ced.ramo = t3.ramo_prod and ced.poliza = t3.poliza and ced.certificado = t3.certificado
left join
liberty.apoyo.dwh_profitcenter pro on pro.ramo_prod = ced.ramo and pro.sucursal = ced.sucursal and pro.ramo_contable = ced.ramo_contable
where ced.periodo_contable >= @periodo_contable 
group by
ced.periodo_contable,
ced.sucursal,
sbu.SBU,
ced.ramo,
ced.ramo_rea,
ced.ramo_contable,
ced.poliza,
ced.certificado,
ced.documento,
--p.intermediario_lide
pro.cod_profitcenter,
pro.desc_profitcenter,
pro.cod_sbu_sap,
pro.desc_sbu_sap,
t3.modalidad

union all 


select 
ced.peco as periodo_contable,
ced.suli as  sucursal_prod,
sbu.sbu,
ced.ramo as ramo_prod,
ced.reas as ramo_rea,
ced.raco as ramo_contable,
ced.poli as poliza,
ced.cert as certificado,
ced.anex as documento,
'' as cod_modalidad,
sum(vces) as VALOR_CEDIDO,
pro.cod_profitcenter,
pro.desc_profitcenter,
pro.cod_sbu_sap,
pro.desc_sbu_sap
,'INTERFAZ_AUT' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'WRITTEN PREMIUM-CEDED' AS Concepto_nivel_1
,'NET_WRITTEN_PREMIUM' AS Concepto_nivel_0
,'AS400' as Fuente
from liberty.reservas.cedidaS ced
left join 
liberty.apoyo.dwh_sbu_ramo_prod sbu on ced.ramo = sbu.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter pro on pro.ramo_prod = ced.ramo and pro.sucursal = ced.suli and pro.ramo_contable = ced.raco
where ced.PECO >= @periodo_contable 
group by 
ced.peco ,
ced.suli,
sbu.sbu,
ced.ramo,
ced.reas,
ced.raco,
ced.poli,
ced.cert,
ced.anex,
--p.intermediario_lide
pro.cod_profitcenter,
pro.desc_profitcenter,
pro.cod_sbu_sap,
pro.desc_sbu_sap
