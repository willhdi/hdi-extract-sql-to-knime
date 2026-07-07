-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#342)
-- Clave      : statement

USE Liberty_pruebas_actuaria




declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


/******************************************
Documento desde el radicado del siniestro
******************************************/



DROP TABLE IF EXISTS #documento_sin

SELECT RADICACION,poliza,intermediario_lide,DOCUMENTO,COUNT(*) as conteo 
INTO #documento_sin
FROM liberty.sini.dwh_s_maestro_d
WHERE SIS_ORIGEN = 'N'
GROUP BY RADICACION,DOCUMENTO,poliza,intermediario_lide



/******************************************
VARIACION BASE_H
******************************************/
DROP TABLE IF EXISTS #sini_incurrido_v_r

select 
a.PERIODO as periodo_contable,
a.INTERFACE as PROGRAMA_INTERFACE,
a.DESCRIPCION_CUENTA_SUB,
a.RAMO_CONTABLE as ramo_contable,
a.SUCURSAL_PROD as sucursal_prod,
a.SUCURSAL_CONTABLE as cod_sucursal,
a.LIBRO as Libro,
b.sbu,
a.cuenta_local,
a.subcuenta_local,
a.CODIGO_RAMO_PRODUCTO as  RAMO_PROD,
a.mdpza as poliza,
[dbo].[F_Conv_Cod_Agente](a.AGENTE_LIDER) as INTERMEDIARIO_LIDE,
[dbo].[F_Conv_Cod_Agente](a.AGENTE_COCORRETAJE) as INTERMEDIARIO_CO
,CONVERT(INT,a.MODALIDAD) as modalidad
,a.numero_siniestro
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,case when a.NATURALEZA_CONTABLE = 'H'  THEN cast(a.VALOR_RUBRO as bigint) * -1 ELSE cast(a.VALOR_RUBRO as bigint) END AS VALOR_CONCEPTO
--,cast(a.VALOR_RUBRO as bigint)  VALOR_CONCEPTO
,'Siniestros_variacion_reaseguro' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'CHANGE IN CASE V' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
into  #sini_incurrido_v_r
from liberty.[MIDDLEWARE].[DWH_REASEGURO_H] a
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.CODIGO_RAMO_PRODUCTO = b.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.CODIGO_RAMO_PRODUCTO and t4.sucursal = a.SUCURSAL_PROD and t4.ramo_contable = a.RAMO_CONTABLE
where PERIODO >=  202501  and   cuenta_local in (411105
,511105,411110,511110
)
and subcuenta_local in (101
,102,103,104,105,106,199,201,202,502,602,
701,702,704,706,707,708
,709,301,302,405,18,724,723,101,1202,104
,1301,17,18,502,719,704,1201
)


/*****************************************************************************
actualizar documento AL = IAXIS  AA AS400 - Cruce con  polizas_h y maestro_h
******************************************************************************/
update a
set a.poliza = b.poliza,
a.intermediario_lide = b.intermediario_lide
from  #sini_incurrido_v_r a 
left join #documento_sin b  on  convert(int,a.numero_siniestro) = b.radicacion
