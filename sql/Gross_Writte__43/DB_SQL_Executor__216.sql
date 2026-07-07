-- Nodo KNIME : P&G_COCO\Gross Writte (#43)\DB SQL Executor (#216)
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

select 
a.PERIODO_CONTABLE
,a.SSEGURO	
,a.SUCURSAL_PROD
,a.RAMO_PROD
,a.RAMO_TECNICO
,a.RAMO_CONTABLE
,a.POLIZA	
,a.CERTIFICADO	
,a.DOCUMENTO	
,a.ANEXO	
,a.SBU
,a.FI_CERTIFICADO	
,a.FF_CERTIFICADO	
,a.FI_DOCUMENTO	
,a.FF_DOCUMENTO	
,a.FECHA_EXPE	
,a.INTERMEDIARIO_LIDE
,a.vr_p_sucursal
,a.vr_p_p_sucursal	
,a.FI_ANEXO	
,a.FF_ANEXO
,a.cod_modalidad
,a.GROSS_WRITTEN_PREMIUM	
,a.Profit_nuevo as cod_profitcenter
,a.Descripcion_profit as desc_profitcenter
,SUBSTRING(LOB_SAP, 1, charindex('-', LOB_SAP)-1) as cod_sbu_sap 
,SUBSTRING(LOB_SAP, charindex('-', LOB_SAP)+1, len(LOB_SAP))  as desc_sbu_sap
,a.Concepto_nivel_3
,a.Concepto_nivel_2
,a.Concepto_nivel_1
,a.Concepto_nivel_0
--,b.LLAVE_CERT 
,CASE WHEN B.LLAVE_CERT IS NULL THEN 0 ELSE 1 END as Marca_corretaje
into #cocorretaje_sucursal
from #profit a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje) B ON (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT)


if OBJECT_ID('tempdb.dbo.#sucursal','U') is not null drop table #sucursal


select 
--distinct
row_number() over( order by 
					a.RAMO_PROD
					,a.POLIZA	
					,a.CERTIFICADO	
					,a.DOCUMENTO
					,a.ANEXO
					,a.SUCURSAL_PROD
					,a.INTERMEDIARIO_LIDE
					,a.vr_p_sucursal
					,a.vr_p_p_sucursal	
					,a.GROSS_WRITTEN_PREMIUM
					,a.RAMO_TECNICO
					,a.RAMO_CONTABLE
					,a.FI_DOCUMENTO	
					,a.FF_DOCUMENTO) as id
,a.SSEGURO	
,a.RAMO_PROD
,a.POLIZA	
,a.CERTIFICADO	
,a.DOCUMENTO
,a.ANEXO
,a.SUCURSAL_PROD
,a.INTERMEDIARIO_LIDE
,a.vr_p_sucursal
,a.vr_p_p_sucursal	
,a.GROSS_WRITTEN_PREMIUM
,a.RAMO_TECNICO
,a.RAMO_CONTABLE
,a.FI_DOCUMENTO	
,a.FF_DOCUMENTO	
into  #sucursal
from #cocorretaje_sucursal a
where Marca_corretaje = 0

-------------------------------------------------




if OBJECT_ID('tempdb.dbo.#cocorretaje_sn','U') is not null drop table #cocorretaje_sn

select 
a.PERIODO_CONTABLE
,a.SSEGURO	
--,a.SUCURSAL_PROD
,a.RAMO_PROD
,a.RAMO_TECNICO
,a.RAMO_CONTABLE
,a.POLIZA	
,a.CERTIFICADO	
,a.DOCUMENTO	
,a.ANEXO	
,a.SBU
,a.FI_CERTIFICADO	
,a.FF_CERTIFICADO	
,a.FI_DOCUMENTO	
,a.FF_DOCUMENTO	
,a.FECHA_EXPE	
,a.INTERMEDIARIO_LIDE
,a.vr_p_sucursal
,a.vr_p_p_sucursal	
,a.FI_ANEXO	
,a.FF_ANEXO
,a.cod_modalidad
,a.GROSS_WRITTEN_PREMIUM	
,a.Profit_nuevo as cod_profitcenter
,a.Descripcion_profit as desc_profitcenter
,SUBSTRING(LOB_SAP, 1, charindex('-', LOB_SAP)-1) as cod_sbu_sap 
,SUBSTRING(LOB_SAP, charindex('-', LOB_SAP)+1, len(LOB_SAP))  as desc_sbu_sap
,a.Concepto_nivel_3
,a.Concepto_nivel_2
,a.Concepto_nivel_1
,a.Concepto_nivel_0
--,b.LLAVE_CERT 
,CASE WHEN B.LLAVE_CERT IS NULL THEN 0 ELSE 1 END as Marca_corretaje
into #cocorretaje_sn
from #profit a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje) B ON (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT)

------AND A.documento>=B.documento and A.documento<B.doc_2)
