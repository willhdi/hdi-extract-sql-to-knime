-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB SQL Executor (#234)
-- Clave      : statement

USE Liberty_Pruebas_Actuaria


--declare
--@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#r_iaxis','U') is not null drop table #r_iaxis
SELECT 
a.PERIODO_CONTABLE
,a.sucursal_prod
,c.ramo_contable
,a.ramo_prod
,a.poliza
,a.certificado
,a.documento
--,a.ano_siniestro
,a.Numero_radicado as radicado
,a.Intermediario_lide
,a.VLR_PAGADO_REC
,'Recovery' AS Concepto_nivel_3
,'INTERFAZ_AUT' as Concepto_nivel_2 
,'RECOVERY' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
into #r_iaxis
FROM #recobros_iaxis a
left join #homologacion_contable c on a.ramo_prod = c.ramo_prod
