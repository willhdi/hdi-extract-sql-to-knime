-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#76)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#directa','U') is not null drop table #directa

---DIRECTA


select
a.mdpek as PERIODO_CONTABLE
,b.sbu as SBU
,a.mdsul as SUCURSAL_PROD
,a.mdsuc as SUCURSAL_CONTABLE
,a.mdprt AS RAMO_PROD
,case when a.mdprt = '900753' and a.mdrc not in (322,323,324) and  t3.cod_modalidad = 1  then 361 
  	  when a.mdprt = '900753' and a.mdrc not in (322,323,324) and t3.cod_modalidad  = 2  then 361 
  	  when a.mdprt = '900753' and a.mdrc not in (322,323,324) and t3.cod_modalidad  = 3  then 361 
  	  when a.mdprt = '900753' and a.mdrc not in (322,323,324) and t3.cod_modalidad  = 4  then 361
  	  else a.mdrc end as RAMO_CONTABLE
,a.mdpza AS poliza
,a.mdctd AS certificado
,a.mdrep as recibo
,a.mdfie AS fi_documento
,a.mdffe AS ff_documento
,case when A.mdlt = 'AA' THEN A.mdagl ELSE [dbo].[F_Conv_Cod_Agente](a.mdagl) END AS INTERMEDIARIO_LIDE
--,[dbo].[F_Conv_Cod_Agente](a.mdagl) AS INTERMEDIARIO_LIDE 
,case when A.mdlt = 'AA' THEN A.mdagl ELSE [dbo].[F_Conv_Cod_Agente](a.mdagc) END AS INTERMEDIARIO_COCO
--,[dbo].[F_Conv_Cod_Agente](a.mdagc) AS INTERMEDIARIO_COCO 
,sum(cast(mdaag as FLOAT)) as VALOR_COMISION
,'Comision_intermediacion' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'COMMISSION EXPENSE' AS Concepto_nivel_1
,'COMMISSION EXPENSE' AS Concepto_nivel_0
,a.mdmod as modalidad
,mdobj as cuenta
,mdsct as subcuenta
into #directa
from liberty.[MIDDLEWARE].[BASE_H] a
--left join
--liberty.prod.dwh_polizas_h t3 on t1.llave = t3.llave Validar cruce modalidad
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.mdprt = b.ramo_prod 
left join
(SELECT DISTINCT RAMO_PROD,POLIZA,CERTIFICADO,COD_MODALIDAD,MAX(LLAVE) AS LLAVE FROM liberty.prod.dwh_polizas_h  
WHERE PERIODO_CONTABLE = @periodo_contable --AND RAMO_PROD = '900753'
GROUP BY RAMO_PROD,POLIZA,CERTIFICADO,COD_MODALIDAD ) t3  on t3.ramo_prod = a.mdprt and t3.poliza = a.mdpza and t3.certificado = a.mdctd 
WHERE a.mdpek >= @periodo_contable   and a.mdobj in (511561) and a.mdsct in (8,10,11,18,20,24,25,27,30,36,39,40,41,42,43,44,100,801,45,15,5,21)
group by
a.mdpek
,b.sbu
,a.mdsul
,A.mdsuc
,a.mdprt
,a.mdrc
,a.mdpza
,a.mdctd
,a.mdctd
,a.mdfie
,a.mdffe
,a.mdagl
,a.mdagc
,t3.cod_modalidad
,a.mdrep
,a.mdlt
,a.mdmod
,mdobj
,mdsct 
------------------------------------------------- cuenta 511570

union all

select
a.mdpek as PERIODO_CONTABLE
,b.sbu as SBU
,a.mdsul as SUCURSAL_PROD
,a.mdsuc as SUCURSAL_CONTABLE
,a.mdprt AS RAMO_PROD
,case when a.mdprt = '900753' and a.mdrc not in (322,323,324) and  t3.cod_modalidad = 1  then 361 
  	  when a.mdprt = '900753' and a.mdrc not in (322,323,324) and t3.cod_modalidad  = 2  then 361 
  	  when a.mdprt = '900753' and a.mdrc not in (322,323,324) and t3.cod_modalidad  = 3  then 361 
  	  when a.mdprt = '900753' and a.mdrc not in (322,323,324) and t3.cod_modalidad  = 4  then 361
  	  else a.mdrc end as RAMO_CONTABLE
,a.mdpza AS poliza
,a.mdctd AS certificado
,a.mdrep as recibo
,a.mdfie AS fi_documento
,a.mdffe AS ff_documento
,case when A.mdlt = 'AA' THEN A.mdagl ELSE [dbo].[F_Conv_Cod_Agente](a.mdagl) END AS INTERMEDIARIO_LIDE
--,[dbo].[F_Conv_Cod_Agente](a.mdagl) AS INTERMEDIARIO_LIDE 
,case when A.mdlt = 'AA' THEN A.mdagl ELSE [dbo].[F_Conv_Cod_Agente](a.mdagc) END AS INTERMEDIARIO_COCO
--,[dbo].[F_Conv_Cod_Agente](a.mdagc) AS INTERMEDIARIO_COCO 
,sum(cast(mdaag as FLOAT)) as VALOR_COMISION
,'Comision_intermediacion' AS Concepto_nivel_3
,'INTERFAZ_AUT_1' AS Concepto_nivel_2
,'COMMISSION EXPENSE' AS Concepto_nivel_1
,'COMMISSION EXPENSE' AS Concepto_nivel_0
,a.mdmod as modalidad
,mdobj as cuenta
,mdsct as subcuenta
from liberty.[MIDDLEWARE].[BASE_H] a
--left join
--liberty.prod.dwh_polizas_h t3 on t1.llave = t3.llave Validar cruce modalidad
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.mdprt = b.ramo_prod 
left join
(SELECT DISTINCT RAMO_PROD,POLIZA,CERTIFICADO,COD_MODALIDAD,MAX(LLAVE) AS LLAVE FROM liberty.prod.dwh_polizas_h  
WHERE PERIODO_CONTABLE = @periodo_contable --AND RAMO_PROD = '900753'
GROUP BY RAMO_PROD,POLIZA,CERTIFICADO,COD_MODALIDAD ) t3  on t3.ramo_prod = a.mdprt and t3.poliza = a.mdpza and t3.certificado = a.mdctd 
WHERE a.mdpek >= @periodo_contable   and a.mdobj in (511570) and a.mdsct in (2)
group by
a.mdpek
,b.sbu
,a.mdsul
,A.mdsuc
,a.mdprt
,a.mdrc
,a.mdpza
,a.mdctd
,a.mdctd
,a.mdfie
,a.mdffe
,a.mdagl
,a.mdagc
,t3.cod_modalidad
,a.mdrep
,a.mdlt
,a.mdmod
,mdobj
,mdsct 
---------------------- CUENTA 411508
union all

select
a.mdpek as PERIODO_CONTABLE
,b.sbu as SBU
,a.mdsul as SUCURSAL_PROD
,a.mdsuc as SUCURSAL_CONTABLE
,a.mdprt AS RAMO_PROD
,case when a.mdprt = '900753' and a.mdrc not in (322,323,324) and  t3.cod_modalidad = 1  then 361 
  	  when a.mdprt = '900753' and a.mdrc not in (322,323,324) and t3.cod_modalidad  = 2  then 361 
  	  when a.mdprt = '900753' and a.mdrc not in (322,323,324) and t3.cod_modalidad  = 3  then 361 
  	  when a.mdprt = '900753' and a.mdrc not in (322,323,324) and t3.cod_modalidad  = 4  then 361
  	  else a.mdrc end as RAMO_CONTABLE
,a.mdpza AS poliza
,a.mdctd AS certificado
,a.mdrep as recibo
,a.mdfie AS fi_documento
,a.mdffe AS ff_documento
,case when A.mdlt = 'AA' THEN A.mdagl ELSE [dbo].[F_Conv_Cod_Agente](a.mdagl) END AS INTERMEDIARIO_LIDE
--,[dbo].[F_Conv_Cod_Agente](a.mdagl) AS INTERMEDIARIO_LIDE 
,case when A.mdlt = 'AA' THEN A.mdagl ELSE [dbo].[F_Conv_Cod_Agente](a.mdagc) END AS INTERMEDIARIO_COCO
--,[dbo].[F_Conv_Cod_Agente](a.mdagc) AS INTERMEDIARIO_COCO 
,sum(cast(mdaag as FLOAT)) as VALOR_COMISION
,'Comision_intermediacion' AS Concepto_nivel_3
,'INTERFAZ_AUT_2' AS Concepto_nivel_2
,'COMMISSION EXPENSE' AS Concepto_nivel_1
,'COMMISSION EXPENSE' AS Concepto_nivel_0
,a.mdmod as modalidad
,mdobj as cuenta
,mdsct as subcuenta
from liberty.[MIDDLEWARE].[BASE_H] a
--left join
--liberty.prod.dwh_polizas_h t3 on t1.llave = t3.llave Validar cruce modalidad
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.mdprt = b.ramo_prod 
left join
(SELECT DISTINCT RAMO_PROD,POLIZA,CERTIFICADO,COD_MODALIDAD,MAX(LLAVE) AS LLAVE FROM liberty.prod.dwh_polizas_h  
WHERE PERIODO_CONTABLE = @periodo_contable --AND RAMO_PROD = '900753'
GROUP BY RAMO_PROD,POLIZA,CERTIFICADO,COD_MODALIDAD ) t3  on t3.ramo_prod = a.mdprt and t3.poliza = a.mdpza and t3.certificado = a.mdctd 
WHERE a.mdpek >= @periodo_contable   and a.mdobj in (411508) and a.mdsct in (1,5)
group by
a.mdpek
,b.sbu
,a.mdsul
,A.mdsuc
,a.mdprt
,a.mdrc
,a.mdpza
,a.mdctd
,a.mdctd
,a.mdfie
,a.mdffe
,a.mdagl
,a.mdagc
,t3.cod_modalidad
,a.mdrep
,a.mdlt
,a.mdmod
,mdobj
,mdsct 

------------------------------ CUENTA 511545
union all


select
a.mdpek as PERIODO_CONTABLE
,b.sbu as SBU
,a.mdsul as SUCURSAL_PROD
,a.mdsuc as SUCURSAL_CONTABLE
,a.mdprt AS RAMO_PROD
,case when a.mdprt = '900753' and a.mdrc not in (322,323,324) and  t3.cod_modalidad = 1  then 361 
  	  when a.mdprt = '900753' and a.mdrc not in (322,323,324) and t3.cod_modalidad  = 2  then 361 
  	  when a.mdprt = '900753' and a.mdrc not in (322,323,324) and t3.cod_modalidad  = 3  then 361 
  	  when a.mdprt = '900753' and a.mdrc not in (322,323,324) and t3.cod_modalidad  = 4  then 361
  	  else a.mdrc end as RAMO_CONTABLE
,a.mdpza AS poliza
,a.mdctd AS certificado
,a.mdrep as recibo
,a.mdfie AS fi_documento
,a.mdffe AS ff_documento
,case when A.mdlt = 'AA' THEN A.mdagl ELSE [dbo].[F_Conv_Cod_Agente](a.mdagl) END AS INTERMEDIARIO_LIDE
--,[dbo].[F_Conv_Cod_Agente](a.mdagl) AS INTERMEDIARIO_LIDE 
,case when A.mdlt = 'AA' THEN A.mdagl ELSE [dbo].[F_Conv_Cod_Agente](a.mdagc) END AS INTERMEDIARIO_COCO
--,[dbo].[F_Conv_Cod_Agente](a.mdagc) AS INTERMEDIARIO_COCO 
,sum(cast(mdaag as FLOAT)) as VALOR_COMISION
,'Comision_intermediacion' AS Concepto_nivel_3
,'INTERFAZ_AUT_3' AS Concepto_nivel_2
,'COMMISSION EXPENSE' AS Concepto_nivel_1
,'COMMISSION EXPENSE' AS Concepto_nivel_0
,a.mdmod as modalidad
,mdobj as cuenta
,mdsct as subcuenta
from liberty.[MIDDLEWARE].[BASE_H] a
--left join
--liberty.prod.dwh_polizas_h t3 on t1.llave = t3.llave Validar cruce modalidad
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.mdprt = b.ramo_prod 
left join
(SELECT DISTINCT RAMO_PROD,POLIZA,CERTIFICADO,COD_MODALIDAD,MAX(LLAVE) AS LLAVE FROM liberty.prod.dwh_polizas_h  
WHERE PERIODO_CONTABLE = @periodo_contable --AND RAMO_PROD = '900753'
GROUP BY RAMO_PROD,POLIZA,CERTIFICADO,COD_MODALIDAD ) t3  on t3.ramo_prod = a.mdprt and t3.poliza = a.mdpza and t3.certificado = a.mdctd 
WHERE a.mdpek >= @periodo_contable   and a.mdobj in (511545) and a.mdsct in  (1,3,5,7,16,25,36,39,40,41,42,0100)
group by
a.mdpek
,b.sbu
,a.mdsul
,A.mdsuc
,a.mdprt
,a.mdrc
,a.mdpza
,a.mdctd
,a.mdctd
,a.mdfie
,a.mdffe
,a.mdagl
,a.mdagc
,t3.cod_modalidad
,a.mdrep
,a.mdlt
,a.mdmod
,mdobj
,mdsct
