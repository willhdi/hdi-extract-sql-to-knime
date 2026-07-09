-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#403)
-- Clave      : statement

USE Liberty_pruebas_actuaria




/**********************************
TOMADOR HDISC 
***********************************/



UPDATE a 
SET DOCUMENTO = b.nro_documento_tomador
from liberty_pruebas_actuaria.dbo.pl_col_datos_coco_comisiones  a
left join liberty.apoyo.dwh_tomadores b on A.RAMO_PROD = B.COD_RAMO_PROD  AND a.poliza = B.nro_poliza
where  PERIODO_CONTABLE = 202603

UPDATE a 
SET nombre_tomador = b.nombre_tomador
from liberty_pruebas_actuaria.dbo.pl_col_datos_coco_comisiones  a
left join liberty.apoyo.dwh_tomadores b on A.RAMO_PROD = B.COD_RAMO_PROD  AND a.poliza = B.nro_poliza
where  PERIODO_CONTABLE = 202603

/************************
Beneficiario retorno
*************************/

UPDATE a 
SET documento_ben = b.NRO_ID_BENEFICIARIO
from liberty_pruebas_actuaria.dbo.pl_col_datos_coco_comisiones  a
left join LIBERTY.[AMOCOM].[RETORNOS_IAXIS] b on a.RAMO_PROD = b.RAMO_PROD and a.POLIZA = b.POLIZA 
WHERE a.PERIODO_CONTABLE =202603 and  b.PERIODO_CONTABLE =202603 and A.Concepto_nivel_3 in ('Retornos','Retornos_a')

UPDATE a 
SET nombre_beneficiario = b.RAZON_SOCIAL_BENEFICIARIO
from liberty_pruebas_actuaria.dbo.pl_col_datos_coco_comisiones  a
left join LIBERTY.[AMOCOM].[RETORNOS_IAXIS] b on a.RAMO_PROD = b.RAMO_PROD and a.POLIZA = b.POLIZA 
WHERE a.PERIODO_CONTABLE =202603 and  b.PERIODO_CONTABLE =202603 and Concepto_nivel_3 in ('Retornos','Retornos_a')

/*************
cuentas
*************/


UPDATE a
set cuenta = 513095
FROM pl_col_datos_coco_comisiones a
where Concepto_nivel_3 = 'Retornos_a'

UPDATE liberty_pruebas_actuaria.dbo.pl_col_datos_coco_comisiones  
SET subcuenta = '08'
WHERE CUENTA = 513095 AND Concepto_nivel_3 = 'Retornos_a'


UPDATE pl_col_datos_coco_comisiones
set cuenta_CUIF = b.Mapped_SAPCountryGLAccount
FROM pl_col_datos_coco_comisiones a
LEFT JOIN Liberty_pruebas_actuaria.dbo.COMPANIA_CUENTAS_CUIF b on a.cuenta = b.cuenta_local  and a.subcuenta = b.subcuenta_local
WHERE B.COMPANIA =1

UPDATE pl_col_datos_coco_comisiones
set cuenta_SAP = b.Mapped_SAPGLAccount
FROM pl_col_datos_coco_comisiones a
LEFT JOIN Liberty_pruebas_actuaria.dbo.COMPANIA_CUENTAS_SAP b on a.cuenta = b.cuenta_local  and a.subcuenta = b.subcuenta_local
WHERE B.COMPANIA =1

/**********
CUENTAS SOBRECOMISIONE
***************/

UPDATE pl_col_datos_coco_comisiones
set cuenta = 511561
FROM pl_col_datos_coco_comisiones a
WHERE  Concepto_nivel_3 = 'SobreComision'


UPDATE pl_col_datos_coco_comisiones
set subcuenta = 20
FROM pl_col_datos_coco_comisiones a
WHERE  Concepto_nivel_3 = 'SobreComision'


UPDATE pl_col_datos_coco_comisiones
set cuenta_CUIF = 515210
FROM pl_col_datos_coco_comisiones a
WHERE  Concepto_nivel_3 = 'SobreComision'


UPDATE pl_col_datos_coco_comisiones
set cuenta_SAP = 5400010
FROM pl_col_datos_coco_comisiones a
WHERE  Concepto_nivel_3 = 'SobreComision'

UPDATE pl_col_datos_coco_comisiones
set cuenta_sap = 5400010,
	cuenta_cuif = 515480
FROM pl_col_datos_coco_comisiones a
WHERE  cuenta = 511677 and subcuenta = '0101'
