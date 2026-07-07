-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB SQL Executor (#8)
-- Clave      : statement

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#sini_pagado','U') is not null drop table #sini_pagado


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$

Select 
a.periodo_contable
,a.ANNO_SINIESTRO
,a.RADICACION
,a.SUCURSAL_PROD
,a.RAMO_PROD
,b.POLIZA
,b.CERTIFICADO
,b.intermediario_lide
,t2.SBU
,a.ramo_contable
,sum(a.VR_NOVEDAD) as VR_PAGADO
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,'Pagado' AS Concepto_nivel_3
,'INTERFAZ_AUT' as Concepto_nivel_2 
,'CHANGE IN CASE' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
into #sini_pagado
from liberty.sini.DWH_S_NOV_CONT_D a
left join
liberty.sini.dwh_s_maestro_d b on  a.ANNO_SINIESTRO = b.ANNO_SINIESTRO and a.SUCURSAL_PROD = b.SUCURSAL_PROD and a.RADICACION = b.RADICACION and a.RAMO_PROD = b.RAMO_PROD
left join 
liberty.apoyo.dwh_sbu_ramo_prod t2 on a.ramo_prod = t2.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.ramo_prod and a.sucursal_prod = t4.sucursal and a.ramo_contable = t4.ramo_contable
where a.periodo_contable = @periodo_contable and TIPO_NOVEDAD in (5,6)
group by 
a.periodo_contable,
a.ANNO_SINIESTRO,
a.RADICACION,
a.SUCURSAL_PROD,
a.RAMO_PROD,
b.POLIZA,
b.CERTIFICADO,
b.intermediario_lide,
t2.SBU,
a.ramo_contable,
t4.cod_profitcenter,
t4.desc_profitcenter,
t4.cod_sbu_sap,
t4.desc_sbu_sap
