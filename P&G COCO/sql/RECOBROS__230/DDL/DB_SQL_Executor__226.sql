-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB SQL Executor (#226)
-- Clave      : statement

USE Liberty_Pruebas_Actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#recobros_iaxis','U') is not null drop table #recobros_iaxis

SELECT 
	substring(cast(IVFECI as varchar(8)),0,7) AS PERIODO_CONTABLE
	,IV$C9N AS Recibo_Caja
	,IVCOIV AS Compañia
	,IVRAMO AS Ramo_prod
	,IVASIN AS Año_Siniestro
	,IVSUCL AS Sucursal_prod
	,IVNRSI AS Numero_Radicado
	,T02.POLIZA AS Poliza
	,T02.CERTIFICADO AS Certificado
	,IVDOCU AS Documento
	,IVNRPA AS Numero_Pagare
	,IVCLVI AS Intermediario_lide
	,IVVRIV AS VLR_PAGADO_REC
	,T02.FECHA_SINIESTRO
	,T02.SBU
into #recobros_iaxis
FROM [LIBERTY].[AS400].[F590475] T01
LEFT JOIN (
SELECT 
	 LLAVE_SIN
	,CAST(CAST(FECHA_SINIESTRO AS VARCHAR (8)) AS DATE) AS FECHA_SINIESTRO
	,POLIZA
	,CERTIFICADO
	,SBU
FROM [Liberty].[SINI].[DWH_S_MAESTRO_D] T1
LEFT JOIN [Liberty].[APOYO].[DWH_SBU_RAMO_PROD] T2 ON T1.RAMO_PROD = T2.RAMO_PROD
WHERE T1.SIS_ORIGEN = 'N') T02 ON CAST(T01.IVNRSI AS INT) = CAST(T02.LLAVE_SIN AS INT)
WHERE IVCTIV IN (531, 539, 532, 540)
AND substring(cast(IVFECI as varchar(8)),0,7) =  @periodo_contable
