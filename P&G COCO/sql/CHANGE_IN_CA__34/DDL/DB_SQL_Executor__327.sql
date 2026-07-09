-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#327)
-- Clave      : statement

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#sini_incurrido_v','U') is not null drop table #sini_incurrido_v


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$



/******************************************
Documento desde el radicado del siniestro
******************************************/



DROP TABLE IF EXISTS #documento_sin

SELECT RADICACION,DOCUMENTO,COUNT(*) as conteo 
INTO #documento_sin
FROM liberty.sini.dwh_s_maestro_d
WHERE SIS_ORIGEN = 'N'
GROUP BY RADICACION,DOCUMENTO


/******************************************
VARIACION BASE_H
******************************************/

DROP TABLE IF EXISTS #sini_incurrido_va

select 
a.mdpek as periodo_contable,
a.mdint as PROGRAMA_INTERFACE,
a.mddl1 as DESCRIPCION_CUENTA_SUB,
a.mdrc as ramo_contable,
a.mdsul as sucursal_prod,
a.mdsuc as cod_sucursal,
a.mdrep as documento,
null as documento_final,
a.mdlt as Libro,
b.sbu,
a.mdobj as cuenta,
a.mdsct as subcuenta,
a.mdprt as  RAMO_PROD,
a.mdpza as poliza,
a.mdctd as certificado,
a.mdnsn as numero_siniestro,
--0 AS documento,
a.mdagl as INTERMEDIARIO_LIDE,
a.mdagc as INTERMEDIARIO_CO
,a.mdmod as modalidad
,cast(a.mdaag as bigint) AS VALOR_CONCEPTO
--,case when a.mdnat = 'H'  THEN cast(a.mdaag as bigint) * -1 ELSE cast(a.mdaag as bigint) END AS VALOR_CONCEPTO
,'Siniestros_variacion' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'CHANGE IN CASE V' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
into #sini_incurrido_va
from liberty.[MIDDLEWARE].[BASE_H] a
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.mdprt = b.ramo_prod 
--left join #documentos_unicos c on a.mdpza = c.pol and a.mdctd = c.certificado and a.documento = b.recibo
where mdpek >=  202501  and mdobj in (411105)
and mdsct in (101,102,103,104,105,201,502,602,701,702,704
,706,707,708,709,1202,1301,301,302,501,501,402,402,106,202)



union all

select 
a.mdpek as periodo_contable,
a.mdint as PROGRAMA_INTERFACE,
a.mddl1 as DESCRIPCION_CUENTA_SUB,
a.mdrc as ramo_contable,
a.mdsul as sucursal_prod,
a.mdsuc as cod_sucursal,
a.mdrep as documento,
null as documento_final,
a.mdlt as Libro,
b.sbu,
a.mdobj as cuenta,
a.mdsct as subcuenta,
a.mdprt as  RAMO_PROD,
a.mdpza as poliza,
a.mdctd as certificado,
a.mdnsn as numero_siniestro,
--0 AS documento,
a.mdagl as INTERMEDIARIO_LIDE,
a.mdagc as INTERMEDIARIO_CO
,a.mdmod as modalidad
,cast(a.mdaag as bigint) AS VALOR_CONCEPTO
--,case when a.mdnat = 'H'  THEN cast(a.mdaag as bigint) * -1 ELSE cast(a.mdaag as bigint) END AS VALOR_CONCEPTO
,'Siniestros_variacion' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'CHANGE IN CASE V' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
from liberty.[MIDDLEWARE].[BASE_H] a
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.mdprt = b.ramo_prod 
--left join #documentos_unicos c on a.mdpza = c.pol and a.mdctd = c.certificado and a.documento = b.recibo
where mdpek >=  202501  and mdobj in (411110)
and mdsct in (101
,102,103,201,502,706,1202,104,202,1301
)

union all

select 
a.mdpek as periodo_contable,
a.mdint as PROGRAMA_INTERFACE,
a.mddl1 as DESCRIPCION_CUENTA_SUB,
a.mdrc as ramo_contable,
a.mdsul as sucursal_prod,
a.mdsuc as cod_sucursal,
a.mdrep as documento,
null as documento_final,
a.mdlt as Libro,
b.sbu,
a.mdobj as cuenta,
a.mdsct as subcuenta,
a.mdprt as  RAMO_PROD,
a.mdpza as poliza,
a.mdctd as certificado,
a.mdnsn as numero_siniestro,
--0 AS documento,
a.mdagl as INTERMEDIARIO_LIDE,
a.mdagc as INTERMEDIARIO_CO
,a.mdmod as modalidad
,cast(a.mdaag as bigint) AS VALOR_CONCEPTO
--,case when a.mdnat = 'H'  THEN cast(a.mdaag as bigint) * -1 ELSE cast(a.mdaag as bigint) END AS VALOR_CONCEPTO
,'Siniestros_variacion' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'CHANGE IN CASE V' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
from liberty.[MIDDLEWARE].[BASE_H] a
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.mdprt = b.ramo_prod 
--left join #documentos_unicos c on a.mdpza = c.pol and a.mdctd = c.certificado and a.documento = b.recibo
where mdpek >=  202501  and mdobj in (411115)
and mdsct in (101,102,103,104,105)

union all 

select 
a.mdpek as periodo_contable,
a.mdint as PROGRAMA_INTERFACE,
a.mddl1 as DESCRIPCION_CUENTA_SUB,
a.mdrc as ramo_contable,
a.mdsul as sucursal_prod,
a.mdsuc as cod_sucursal,
a.mdrep as documento,
null as documento_final,
a.mdlt as Libro,
b.sbu,
a.mdobj as cuenta,
a.mdsct as subcuenta,
a.mdprt as  RAMO_PROD,
a.mdpza as poliza,
a.mdctd as certificado,
a.mdnsn as numero_siniestro,
--0 AS documento,
a.mdagl as INTERMEDIARIO_LIDE,
a.mdagc as INTERMEDIARIO_CO
,a.mdmod as modalidad
,cast(a.mdaag as bigint) AS VALOR_CONCEPTO
--,case when a.mdnat = 'H'  THEN cast(a.mdaag as bigint) * -1 ELSE cast(a.mdaag as bigint) END AS VALOR_CONCEPTO
,'Siniestros_variacion' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'CHANGE IN CASE V' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
from liberty.[MIDDLEWARE].[BASE_H] a
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.mdprt = b.ramo_prod 
--left join #documentos_unicos c on a.mdpza = c.pol and a.mdctd = c.certificado and a.documento = b.recibo
where mdpek >=  202501  
and mdobj in (511105)
and mdsct in (18
,101,102,103,104,105,106,199,201,202,701,702,704,706,708
,709,724,1201,1202,1301,502,502,703,703,701,501,501,723)




union all

select 
a.mdpek as periodo_contable,
a.mdint as PROGRAMA_INTERFACE,
a.mddl1 as DESCRIPCION_CUENTA_SUB,
a.mdrc as ramo_contable,
a.mdsul as sucursal_prod,
a.mdsuc as cod_sucursal,
a.mdrep as documento,
null as documento_final,
a.mdlt as Libro,
b.sbu,
a.mdobj as cuenta,
a.mdsct as subcuenta,
a.mdprt as  RAMO_PROD,
a.mdpza as poliza,
a.mdctd as certificado,
a.mdnsn as numero_siniestro,
--0 AS documento,
a.mdagl as INTERMEDIARIO_LIDE,
a.mdagc as INTERMEDIARIO_CO
,a.mdmod as modalidad
,cast(a.mdaag as bigint) AS VALOR_CONCEPTO
--,case when a.mdnat = 'H'  THEN cast(a.mdaag as bigint) * -1 ELSE cast(a.mdaag as bigint) END AS VALOR_CONCEPTO
,'Siniestros_variacion' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'CHANGE IN CASE V' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
from liberty.[MIDDLEWARE].[BASE_H] a
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.mdprt = b.ramo_prod 
--left join #documentos_unicos c on a.mdpza = c.pol and a.mdctd = c.certificado and a.documento = b.recibo
where mdpek >=  202501  and mdobj in (511110)
and mdsct in (18
,502,101,102,103,106,199,202,702,706
,723,1202,704,201,1201,104,105,1301
)

union all

select 
a.mdpek as periodo_contable,
a.mdint as PROGRAMA_INTERFACE,
a.mddl1 as DESCRIPCION_CUENTA_SUB,
a.mdrc as ramo_contable,
a.mdsul as sucursal_prod,
a.mdsuc as cod_sucursal,
a.mdrep as documento,
null as documento_final,
a.mdlt as Libro,
b.sbu,
a.mdobj as cuenta,
a.mdsct as subcuenta,
a.mdprt as  RAMO_PROD,
a.mdpza as poliza,
a.mdctd as certificado,
a.mdnsn as numero_siniestro,
--0 AS documento,
a.mdagl as INTERMEDIARIO_LIDE,
a.mdagc as INTERMEDIARIO_CO
,a.mdmod as modalidad
,cast(a.mdaag as bigint) AS VALOR_CONCEPTO
--,case when a.mdnat = 'H'  THEN cast(a.mdaag as bigint) * -1 ELSE cast(a.mdaag as bigint) END AS VALOR_CONCEPTO
,'Siniestros_variacion' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'CHANGE IN CASE V' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
from liberty.[MIDDLEWARE].[BASE_H] a
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.mdprt = b.ramo_prod 
--left join #documentos_unicos c on a.mdpza = c.pol and a.mdctd = c.certificado and a.documento = b.recibo
where mdpek >=  202501  and mdobj in (511115)
and mdsct in (18
,101,102,103,104,105,106
)

/*****************************************************************************
actualizar documento AL = IAXIS  AA AS400 - Cruce con  polizas_h y maestro_h
******************************************************************************/

update a
set a.documento_final = b.documento
from #sini_incurrido_va a 
left join #documento_sin b  on  convert(int,a.numero_siniestro) = b.radicacion
where libro = 'AL' and documento_final is null

update a
set a.documento_final = 0
from #sini_incurrido_va a 
where libro = 'AL' and documento_final is null



update a
set a.documento_final = a.documento
from #sini_incurrido_va a 
where libro = 'AA' and documento_final is null
