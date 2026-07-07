-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB SQL Executor (#16)
-- Clave      : statement

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#sini_incurrido','U') is not null drop table #sini_incurrido


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$



if OBJECT_ID('dbo.intermediarios_unicos','U') is not null drop table intermediarios_unicos
SELECT * 
INTO intermediarios_unicos
from (
		SELECT ramo_prod,
		       poliza AS pol,
		       intermediario_lide,
		       ROW_NUMBER() OVER (PARTITION BY ramo_prod, poliza ORDER BY intermediario_lide) AS rn
		FROM liberty.prod.dwh_polizas_h
		WHERE PERIODO_CONTABLE >= 202001
) a 
where rn = 1




Select 
a.periodo_contable ,
a.ANNO_SINIESTRO,
a.RADICACION,
a.SUCURSAL_PROD,
a.SUCURSAL_contable,
a.RAMO_PROD,
--a.VR_P_COASEGURO as Coaseguro,                
b.POLIZA,
b.CERTIFICADO,
b.DOCUMENTO,
coalesce(b.intermediario_lide,it.intermediario_lide) as INTERMEDIARIO_LIDE,
t2.SBU,
a.ramo_contable,
sum(a.VR_NOVEDAD) as VR_INCURRIDO,
SUM(convert	(
				decimal(25,2),a.VR_NOVEDAD*	(isnull	(
													case 	when coa_aseg_temp.VR_P_COASEGURO is null or coa_aseg_temp.VR_P_COASEGURO=0 then 1
															else (100-coa_aseg_temp.VR_P_COASEGURO)/100
													end,	case	when COA.[GDPJVR] is null or COA.[GDPJVR]=0 or COA.[GDPJVR]=100 then 1
																		else (COA.[GDPJVR])/100
															end
													)
											)
				)) as VR_INCURRIDO_NETO,
--case when a.SIS_ORIGEN = 'N' AND a.VR_P_COASEGURO=0 THEN a.VR_NOVEDAD
--	 when a.SIS_ORIGEN = 'N' AND a.VR_P_COASEGURO <>0 then  a.VR_NOVEDAD*1-(VR_P_COASEGURO/100)
--	 when a.SIS_ORIGEN = 'O' AND a.VR_P_COASEGURO=100 THEN a.VR_NOVEDAD
--	 when a.SIS_ORIGEN = 'O' AND a.VR_P_COASEGURO=100 THEN a.VR_NOVEDAD*(VR_P_COASEGURO/100)
--ELSE VR_NOVEDAD
--END AS VR_INCURRIDO_NETO_2,
t4.cod_profitcenter,
t4.desc_profitcenter,
t4.cod_sbu_sap,
t4.desc_sbu_sap,
b.modalidad
into #sini_incurrido
from liberty.sini.DWH_S_NOV_CONT_D a
left join
liberty.sini.dwh_s_maestro_d b on  a.ANNO_SINIESTRO = b.ANNO_SINIESTRO and a.SUCURSAL_PROD = b.SUCURSAL_PROD and a.RADICACION = b.RADICACION and a.RAMO_PROD = b.RAMO_PROD
left join 
liberty.apoyo.dwh_sbu_ramo_prod t2 on a.ramo_prod = t2.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.ramo_prod and a.sucursal_prod = t4.sucursal and a.ramo_contable = t4.ramo_contable
left join #RT_Apoyo_p_coaseg as coa_aseg_temp on	(
													coa_aseg_temp.poliza=b.POLIZA
													and coa_aseg_temp.certificado=b.CERTIFICADO
													and coa_aseg_temp.recibo=b.recibo
													and coa_aseg_temp.Id_Row=1
													and b.[SIS_ORIGEN] = 'N'
													)
left join [Liberty].[AS400].[SNLCOAC1] as COA on	(													
															b.ramo_prod = coa.GDRACG 
															and b.poliza= coa.GDPZNU 
															and b.certificado = coa.GDCTNU 
															and b.documento = coa.GDDCNU
															and b.[SIS_ORIGEN] = 'O'
															)
left join 
intermediarios_unicos it on a.RAMO_prod = it.ramo_prod and a.poliza = it.pol  		
where a.periodo_contable = @periodo_contable 
AND a.TIPO_NOVEDAD NOT IN (5,6)
group by
a.periodo_contable,
a.ANNO_SINIESTRO,
a.RADICACION,
a.SUCURSAL_PROD,
a.RAMO_PROD,
b.POLIZA,
b.CERTIFICADO,
b.documento,
--a.VR_P_COASEGURO,
b.intermediario_lide,
t2.SBU,
a.ramo_contable,
t4.cod_profitcenter,
t4.desc_profitcenter,
t4.cod_sbu_sap,
t4.desc_sbu_sap,
a.SIS_ORIGEN,
it.intermediario_lide,
b.modalidad,
a.SUCURSAL_contable




--Select 
--a.periodo_contable ,
--a.ANNO_SINIESTRO,
--a.RADICACION,
--a.SUCURSAL_PROD,
--a.RAMO_PROD,
--b.POLIZA,
--b.CERTIFICADO,
--b.DOCUMENTO,
--b.intermediario_lide,
--t2.SBU,
--a.ramo_contable,
--sum(a.VR_NOVEDAD) as VR_INCURRIDO,
--t4.cod_profitcenter,
--t4.desc_profitcenter,
--t4.cod_sbu_sap,
--t4.desc_sbu_sap
--into #sini_incurrido
--from liberty.sini.DWH_S_NOV_CONT_D a
--left join
--liberty.sini.dwh_s_maestro_d b on  a.ANNO_SINIESTRO = b.ANNO_SINIESTRO and a.SUCURSAL_PROD = b.SUCURSAL_PROD and a.RADICACION = b.RADICACION and a.RAMO_PROD = b.RAMO_PROD
--left join 
--liberty.apoyo.dwh_sbu_ramo_prod t2 on a.ramo_prod = t2.ramo_prod 
--left join
--liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.ramo_prod and a.sucursal_prod = t4.sucursal and a.ramo_contable = t4.ramo_contable
--where a.periodo_contable = @periodo_contable AND a.TIPO_NOVEDAD NOT IN (5,6)
--group by
--a.periodo_contable,
--a.ANNO_SINIESTRO,
--a.RADICACION,
--a.SUCURSAL_PROD,
--a.RAMO_PROD,
--b.POLIZA,
--b.CERTIFICADO,
--b.DOCUMENTO,
--b.intermediario_lide,
--t2.SBU,
--a.ramo_contable,
--t4.cod_profitcenter,
--t4.desc_profitcenter,
--t4.cod_sbu_sap,
--t4.desc_sbu_sap
