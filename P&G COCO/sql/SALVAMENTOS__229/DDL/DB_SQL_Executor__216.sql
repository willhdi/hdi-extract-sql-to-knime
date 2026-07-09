-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB SQL Executor (#216)
-- Clave      : statement

USE Liberty_pruebas_actuaria


/*****************
TEMPORAL COCORRETAJE
******************/

if OBJECT_ID('tempdb.dbo.#corretaje','U') is not null drop table #corretaje

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
into #corretaje
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




if OBJECT_ID('tempdb.dbo.#cocorretaje_sucursal','U') is not null drop table #cocorretaje_sucursal


-------------------------------------------------



/*********************
Marca Corretaje
*********************/

if OBJECT_ID('tempdb.dbo.#cocorretaje_sn','U') is not null drop table #cocorretaje_sn

select 
a.*
--,b.LLAVE_CERT 
,CASE WHEN B.LLAVE_CERT IS NULL THEN 0 ELSE 1 END as Marca_corretaje
into #cocorretaje_sn
from #s_iaxis_d a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje) B ON (concat(ltrim(rtrim(a.RAMO_PROD)),'_',ltrim(rtrim(a.poliza)),'_',a.certificado)=B.LLAVE_CERT)

------AND A.documento>=B.documento and A.documento<B.doc_2)
