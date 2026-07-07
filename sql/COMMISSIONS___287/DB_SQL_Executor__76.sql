-- Nodo KNIME : P&G_COCO\COMMISSIONS_ (#287)\DB SQL Executor (#76)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#directa','U') is not null drop table #directa

---DIRECTA

select
a.periodo_contable as PERIODO_CONTABLE
,b.sbu as SBU
,a.SUCURSAL_LIDER as SUCURSAL_PROD
,A.SUCURSAL_CONTABLE
,a.RAMO_PRODUCTO_TECNICO AS RAMO_PROD
,case when a.RAMO_PRODUCTO_TECNICO = '900753' and a.ramo_contable not in (322,323,324) and  t3.cod_modalidad = 1  then 361 
  	  when a.RAMO_PRODUCTO_TECNICO = '900753' and a.ramo_contable not in (322,323,324) and t3.cod_modalidad  = 2  then 361 
  	  when a.RAMO_PRODUCTO_TECNICO = '900753' and a.ramo_contable not in (322,323,324) and t3.cod_modalidad  = 3  then 361 
  	  when a.RAMO_PRODUCTO_TECNICO = '900753' and a.ramo_contable not in (322,323,324) and t3.cod_modalidad  = 4  then 361
  	  else a.RAMO_CONTABLE end as RAMO_CONTABLE
,a.poliza
,a.certificado
,a.documento_recibo as recibo
,a.FECHA_INICIO_POLIZA_CERTIFICADO AS fi_documento
,a.FECHA_FIN_POLIZA_CERTIFICADO AS ff_documento
,case when A.libro = 'AA' THEN A.AGENTE_LIDER ELSE [dbo].[F_Conv_Cod_Agente](a.AGENTE_LIDER) END AS INTERMEDIARIO_LIDE
,sum(cast(VALOR_APUNTE_ABSOLUTO as float)) as VALOR_COMISION
,'Comision_intermediacion' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'COMMISSION EXPENSE' AS Concepto_nivel_1
,'COMMISSION EXPENSE' AS Concepto_nivel_0
into #directa
from liberty.[MIDDLEWARE].[DWH_PRODUCCION_H] a
--left join
--liberty.prod.dwh_polizas_h t3 on t1.llave = t3.llave Validar cruce modalidad
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.RAMO_PRODUCTO_TECNICO = b.ramo_prod 
left join
(SELECT DISTINCT RAMO_PROD,POLIZA,CERTIFICADO,COD_MODALIDAD,MAX(LLAVE) AS LLAVE FROM liberty.prod.dwh_polizas_h  
WHERE PERIODO_CONTABLE = @periodo_contable AND RAMO_PROD = '900753'
GROUP BY RAMO_PROD,POLIZA,CERTIFICADO,COD_MODALIDAD ) t3  on t3.ramo_prod = a.RAMO_PRODUCTO_TECNICO and t3.poliza = a.POLIZA and t3.certificado = a.certificado 
WHERE a.periodo_contable = @periodo_contable   and cuenta_local in (511545,511561) AND SUBCUENTA_LOCAL in (1,8,20,801)
group by
a.periodo_contable
,b.sbu
,a.SUCURSAL_LIDER
,A.SUCURSAL_CONTABLE
,a.RAMO_PRODUCTO_TECNICO
,a.ramo_contable
,a.poliza
,a.certificado
,a.documento_recibo
,a.FECHA_INICIO_POLIZA_CERTIFICADO
,a.FECHA_FIN_POLIZA_CERTIFICADO
,a.AGENTE_LIDER
,A.libro
,t3.cod_modalidad
