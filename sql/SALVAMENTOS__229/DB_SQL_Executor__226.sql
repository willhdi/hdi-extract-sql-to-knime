-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB SQL Executor (#226)
-- Clave      : statement

USE Liberty_Pruebas_Actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#salvamentos_iaxis','U') is not null drop table #salvamentos_iaxis

select 
substring(cast(IVFECI as varchar(8)),0,7) AS PERIODO_CONTABLE
,IV$C9N as	Recibo_Caja 
,IVCOIV as compañia
,IVSUCL as sucursal_prod
,IVRAMO as ramo_prod
,IVPOLI as poliza
,IVCERT as certificado
,IVDOCU as documento
,IV$REC as recibo
,IVASIN as ano_siniestro
,IVNRSI as numero_radicado
,IVTIDT as Tipo_Identi_Tomador
,IVIDTO as Identificacion_Tomador
,IVTIDA as Tipo_Identi_Asegurado 
,IVIDAS as Identificacion_Asegurado   
,IVCLVI as Intermediario_lide
,IVVRIV AS VLR_PAGADO_SAL
into #salvamentos_iaxis
from liberty.[AS400].[F590475]
where substring(cast(IVFECI as varchar(8)),0,7) = @periodo_contable and IVCTIV IN (530) ---, 533, 535)
