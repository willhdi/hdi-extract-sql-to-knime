-- Nodo KNIME : P&G_COCO\COMMISSIONS (#278)\DB SQL Executor (#333)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/*****************
UNION NO CORRETAJE CON LOS CASOS DE CORRETAJE
******************/

if OBJECT_ID('tempdb.dbo.#no_coco_completo_r','U') is not null drop table #no_coco_completo_r

--drop table #no_coco_completo
SELECT 
a.* ,
CONVERT(int,b.SUCURSAL_PROD) as COD_SUCURSAL
into #no_coco_completo_r
FROM #no_coco_r a
left join  #sucursal_r b on a.id=b.id
--a.INTERMEDIARIO_LIDE = b.INTERMEDIARIO_LIDE and 
--a.PERIODO_CONTABLE = b.PERIODO_CONTABLE and 
--a.ramo_prod = b.ramo_prod and
--a.poliza = b.poliza and 
--a.certificado = b.certificado and 
--a.documento = b.documento and 
--a.GROSS_WRITTEN_PREMIUM = b.GROSS_WRITTEN_PREMIUM and 
--a.RAMO_TECNICO = b.RAMO_TECNICO and 
--a.RAMO_CONTABLE = b.RAMO_CONTABLE and
--a.ANEXO =	b.ANEXO	and
--a.SBU = b.SBU    and
--a.FI_CERTIFICADO   =	   b.FI_CERTIFICADO and
--a.FF_CERTIFICADO   =	   b.FF_CERTIFICADO and
--a.FI_DOCUMENTO	 =     b.FI_DOCUMENTO and
--a.FF_DOCUMENTO	 =     b.FF_DOCUMENTO and
--a.FECHA_EXPE       =     b.FECHA_EXPE   and
--a.vr_p_sucursal      =     b.vr_p_sucursal and
--a.vr_p_p_sucursal    =     b.vr_p_p_sucursal --and
--a.cod_modalidad    =     b.cod_modalidad


alter table #no_coco_completo_r drop column id
