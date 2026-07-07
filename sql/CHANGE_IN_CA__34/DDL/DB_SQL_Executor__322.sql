-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#322)
-- Clave      : statement

USE Liberty_pruebas_actuaria


/*****************
TEMPORAL COCORRETAJE
******************/

if OBJECT_ID('tempdb.dbo.#corretaje_sin','U') is not null drop table #corretaje_sin

/************
Esta tabla trae un rango de docuemnto al que le debe aplicar el corretaje 
Soluciona el punto de las cancelaciones que no distribuyen el corretaje
Incluir este proceso para tenerlo actualziado todos los meses
*************/

select
distinct 
c.llave_cert
,c.llave_pol
,c.COD_ramo_prod
,c.NRO_poliza
,c.NRO_certificado
,c.documento
,c.COD_INTERMEDIARIO
,c.PARTICIPACION
,c.DOC_2
,i.cod_sucursal
into #corretaje_sin
from [Liberty_Pruebas_Actuaria].[dbo].DWH_CORRETAJE_H_COMPLETO c
left join  
liberty.[APOYO].[DWH_INTERMEDIARIOS_TOTAL] i on c.cod_intermediario = i.cod_intermediario



/************
El siguiente codigo funciona como tabla base de cocorretaje sin tener en cuenta que las 
cancelaciones no esta abriendo el corretaje
*************/
--select  
--distinct
--c.COD_RAMO_PROD
--,c.NRO_POLIZA
--,c.NRO_CERTIFICADO
--,c.DOCUMENTO
--,c.COD_INTERMEDIARIO
----,c.COD_SUCURSAL
--,c.PARTICIPACION
--,c.TIPO_DISTRIBUCION
--,i.cod_sucursal
--into #corretaje
--from [Liberty].[PROD].[DWH_CORRETAJE_H] c
--left join  
--liberty.[APOYO].[DWH_INTERMEDIARIOS_TOTAL] i on c.cod_intermediario = i.cod_intermediario


/*********************
temporal de sucursal: Se crea esta temporal para asignar sucursal al final del proceso de asignación de corretaje 
*********************/




if OBJECT_ID('tempdb.dbo.#cocorretaje_sucursal_sini','U') is not null drop table #cocorretaje_sucursal_sini

select 
a.PERIODO_CONTABLE ,
--a.ANNO_SINIESTRO,
---a.RADICACION,
a.SUCURSAL_PROD,
a.RAMO_PROD,
a.POLIZA,
a.CERTIFICADO,
a.DOCUMENTO,
a.INTERMEDIARIO_LIDE,
a.SBU,
a.ramo_contable,
a.VALOR_CONCEPTO,
a.profit_nuevo as cod_profitcenter
,a.Descripcion_profit as desc_profitcenter
,SUBSTRING(LOB_SAP, 1, charindex('-', LOB_SAP)-1) as cod_sbu_sap 
,SUBSTRING(LOB_SAP, charindex('-', LOB_SAP)+1, len(LOB_SAP))  as desc_sbu_sap
,'Siniestros_variacion' AS Concepto_nivel_3
,'INTERFAZ_AUT' as Concepto_nivel_2 
,'CHANGE IN CASE V' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
--,b.LLAVE_CERT 
,CASE WHEN B.LLAVE_CERT IS NULL THEN 0 ELSE 1 END as Marca_corretaje
into #cocorretaje_sucursal_sini
from  #sini_incurrido_v_1 a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje_sin) B ON (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT)


if OBJECT_ID('tempdb.dbo.#sucursal_sin','U') is not null drop table #sucursal_sin


select 
--distinct
--row_number() over(order by sseguro) as id,
a.PERIODO_CONTABLE ,
--a.ANNO_SINIESTRO,
--a.RADICACION,
a.SUCURSAL_PROD,
a.RAMO_PROD,
a.POLIZA,
a.CERTIFICADO,
a.DOCUMENTO,
a.INTERMEDIARIO_LIDE
into #sucursal_sin
from #cocorretaje_sucursal_sini a
where Marca_corretaje = 0

-------------------------------------------------




if OBJECT_ID('tempdb.dbo.#cocorretaje_sn_sin','U') is not null drop table #cocorretaje_sn_sin

select 
a.PERIODO_CONTABLE ,
--a.ANNO_SINIESTRO,
---a.RADICACION,
a.SUCURSAL_PROD,
a.RAMO_PROD,
a.POLIZA,
a.CERTIFICADO,
a.DOCUMENTO_FINAL AS DOCUMENTO,
a.INTERMEDIARIO_LIDE,
a.SBU,
a.ramo_contable,
a.VALOR_CONCEPTO,
a.profit_nuevo as cod_profitcenter
,a.Descripcion_profit as desc_profitcenter
,SUBSTRING(LOB_SAP, 1, charindex('-', LOB_SAP)-1) as cod_sbu_sap 
,SUBSTRING(LOB_SAP, charindex('-', LOB_SAP)+1, len(LOB_SAP))  as desc_sbu_sap
,'Siniestros_variacion' AS Concepto_nivel_3
,'INTERFAZ_AUT' as Concepto_nivel_2 
,'CHANGE IN CASE V' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
,CASE WHEN B.LLAVE_CERT IS NULL THEN 0 ELSE 1 END as Marca_corretaje
into #cocorretaje_sn_sin
from  #sini_incurrido_v_1 a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje_sin) B ON (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT) ---AND A.documento>=B.documento and A.documento<B.doc_2
