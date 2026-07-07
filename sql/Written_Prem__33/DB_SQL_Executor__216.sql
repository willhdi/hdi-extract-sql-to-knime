-- Nodo KNIME : P&G_COCO\Written Prem (#33)\DB SQL Executor (#216)
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
ced.periodo_contable
,ced.sucursal_prod
,ced.ramo_prod
,ced.ramo_rea
,ced.ramo_contable
,ced.poliza
,ced.certificado
,ced.documento
,ced.SBU
,ced.intermediario_lide
,ced.VALOR_CEDIDO
--,ced.cod_profitcenter
--,ced.desc_profitcenter
--,ced.cod_sbu_sap
--,ced.desc_sbu_sap
,ced.Profit_nuevo as cod_profitcenter
,ced.Descripcion_profit as desc_profitcenter
,SUBSTRING(LOB_SAP, 1, charindex('-', ced.LOB_SAP)-1) as  cod_sbu_sap 
,SUBSTRING(LOB_SAP, charindex('-', ced.LOB_SAP)+1, len(ced.LOB_SAP)) as desc_sbu_sap
,ced.Concepto_nivel_3
,ced.Concepto_nivel_2
,ced.Concepto_nivel_1
,ced.Concepto_nivel_0
,ced.Fuente
--,b.LLAVE_CERT 
,CASE WHEN B.LLAVE_CERT IS NULL THEN 0 ELSE 1 END as Marca_corretaje
into #cocorretaje_sn
from #cedidas ced
LEFT JOIN (select distinct LLAVE_CERT from #corretaje) B ON (concat(ltrim(rtrim(ced.RAMO_prod)),'_',ltrim(rtrim(ced.poliza)),'_',ced.certificado)=B.LLAVE_CERT)

------AND A.documento>=B.documento and A.documento<B.doc_2)
