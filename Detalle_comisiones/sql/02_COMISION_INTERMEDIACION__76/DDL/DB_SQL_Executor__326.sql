-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#326)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/*****************
UNION NO CORRETAJE CON LOS CASOS DE CORRETAJE
******************/

if OBJECT_ID('tempdb.dbo.#no_coco_completo_d','U') is not null drop table #no_coco_completo_d

--drop table #no_coco_completo
SELECT 
a.* ,
CONVERT(int,b.SUCURSAL_PROD) as COD_SUCURSAL
into #no_coco_completo_d
FROM #no_coco_d a
left join  #sucursal_d b on a.id=b.id


alter table #no_coco_completo_d drop column id
