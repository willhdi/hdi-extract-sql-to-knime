-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#16)
-- Clave      : statement

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#sini_incurrido','U') is not null drop table #sini_incurrido


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$





/*********************************
Documento polizas_h por recibo
*********************************/



DROP TABLE IF EXISTS #documentos_unicos

SELECT * 
INTO #documentos_unicos
from (
		SELECT ramo_prod,
		       poliza AS pol,
		       certificado,
		       recibo,
		       documento,
		       ROW_NUMBER() OVER (PARTITION BY ramo_prod, poliza,certificado,recibo ORDER BY documento asc) AS rn
		FROM liberty.prod.dwh_polizas_h
		WHERE PERIODO_CONTABLE >= 200101 and sis_origen = 'N'
		) a 
where rn = 1

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
LIQUIDAOS BASE_H
******************************************/

DROP TABLE IF EXISTS #sini_incurrido

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
,'Siniestros_liquidados' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'CHANGE IN CASE L' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
into #sini_incurrido
from liberty.[MIDDLEWARE].[BASE_H] a
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.mdprt = b.ramo_prod 
--left join #documentos_unicos c on a.mdpza = c.pol and a.mdctd = c.certificado and a.documento = b.recibo
where mdpek >=  202501  and mdobj in (510205,510210,510215)
and mdsct in (102,105,101,103,1001,104,106)


/*****************************************************************************
actualizar documento AL = IAXIS  AA AS400 - Cruce con  polizas_h y maestro_h
******************************************************************************/


update a
set a.documento_final = b.documento
from #sini_incurrido a 
left join #documentos_unicos b  on  a.poliza = b.pol and a.certificado = b.certificado and a.documento = b.recibo
where libro = 'AL'

update a
set a.documento_final = b.documento
from #sini_incurrido a 
left join #documento_sin b  on  convert(int,a.numero_siniestro) = b.radicacion
where libro = 'AL' and documento_final is null

update a
set a.documento_final = 0
from #sini_incurrido a 
where libro = 'AL' and documento_final is null

update a
set a.documento_final = 0
from #sini_incurrido a 
where libro = 'AL' and documento_final is null



update a
set a.documento_final = a.documento
from #sini_incurrido a 
where libro = 'AA' and documento_final is null
