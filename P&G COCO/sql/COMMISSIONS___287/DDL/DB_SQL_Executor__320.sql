-- Nodo KNIME : P&G_COCO\COMMISSIONS_ (#287)\DB SQL Executor (#320)
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




if OBJECT_ID('tempdb.dbo.#cocorretaje_sucursal_i','U') is not null drop table #cocorretaje_sucursal_i

select 
a.PERIODO_CONTABLE
,a.SUCURSAL_PROD
,a.RAMO_PROD
,a.POLIZA
,a.CERTIFICADO
,a.DOCUMENTO
,a.SBU
,a.INTERMEDIARIO_LIDE
,a.cod_profitcenter
,a.desc_profitcenter
,a.cod_sbu_sap
,a.desc_sbu_sap
,a.Concepto_nivel_3
,a.Concepto_nivel_2 
,a.Concepto_nivel_1 
,a.Concepto_nivel_0 
,a.VALOR_CONCEPTO
,CASE WHEN B.LLAVE_CERT IS NULL THEN 0 ELSE 1 END as Marca_corretaje
into #cocorretaje_sucursal_i
from #retornos_docu a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje) B ON (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT)


if OBJECT_ID('tempdb.dbo.#sucursal_i','U') is not null drop table #sucursal_i


select 
--distinct
row_number() over(order by poliza,certificado,documento) as id
,a.PERIODO_CONTABLE
,a.SUCURSAL_PROD
,a.RAMO_PROD
,a.POLIZA
,a.CERTIFICADO
,a.DOCUMENTO
,a.SBU
,a.INTERMEDIARIO_LIDE
,a.cod_profitcenter
,a.desc_profitcenter
,a.cod_sbu_sap
,a.desc_sbu_sap
,a.Concepto_nivel_3
,a.Concepto_nivel_2 
,a.Concepto_nivel_1 
,a.Concepto_nivel_0 
,a.VALOR_CONCEPTO
into  #sucursal_i
from #cocorretaje_sucursal_i a
where Marca_corretaje = 0

-------------------------------------------------




if OBJECT_ID('tempdb.dbo.#cocorretaje_sn_i','U') is not null drop table #cocorretaje_sn_i

select 
a.PERIODO_CONTABLE
--,a.SUCURSAL_PROD
,a.RAMO_PROD
,a.POLIZA
,a.CERTIFICADO
,a.DOCUMENTO
,a.SBU
,a.INTERMEDIARIO_LIDE
,a.cod_profitcenter
,a.desc_profitcenter
,a.cod_sbu_sap
,a.desc_sbu_sap
,a.Concepto_nivel_3
,a.Concepto_nivel_2 
,a.Concepto_nivel_1 
,a.Concepto_nivel_0 
,a.VALOR_CONCEPTO
,CASE WHEN B.LLAVE_CERT IS NULL THEN 0 ELSE 1 END as Marca_corretaje
into #cocorretaje_sn_i
from #retornos_docu a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje) B ON (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT)

------AND A.documento>=B.documento and A.documento<B.doc_2)
