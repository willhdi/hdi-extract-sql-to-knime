-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#75)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('#retorno','U') is not null drop table #retorno
drop table #retorno
---- CEUNTA 513095
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
--,[dbo].[F_Conv_Cod_Agente](a.AGENTE_LIDER) AS INTERMEDIARIO_LIDE
,[dbo].[F_Conv_Cod_Agente](a.mdagl) AS INTERMEDIARIO_LIDE 
,[dbo].[F_Conv_Cod_Agente](a.mdagc) AS INTERMEDIARIO_COCO 
,sum(cast(mdaag as FLOAT)) as VALOR_RETORNO
,'Retornos' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'COMMISSION EXPENSE' AS Concepto_nivel_1
,'COMMISSION EXPENSE' AS Concepto_nivel_0
,a.mdmod as modalidad
,mdobj as cuenta
,mdsct as subcuenta
into #retorno
from liberty.[MIDDLEWARE].[BASE_H] a
--left join
--liberty.prod.dwh_polizas_h t3 on t1.llave = t3.llave Validar cruce modalidad
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.mdprt = b.ramo_prod 
left join
(SELECT DISTINCT RAMO_PROD,POLIZA,CERTIFICADO,COD_MODALIDAD,MAX(LLAVE) AS LLAVE FROM liberty.prod.dwh_polizas_h  
WHERE PERIODO_CONTABLE >= @periodo_contable --AND RAMO_PROD = '900753'
GROUP BY RAMO_PROD,POLIZA,CERTIFICADO,COD_MODALIDAD ) t3  on t3.ramo_prod = a.mdprt and t3.poliza = a.mdpza and t3.certificado = a.mdctd 
WHERE a.mdpek >= @periodo_contable   and mdobj in (513095)  AND a.mdsct IN  (6,13,14,22,23,26,27,804,808) 
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
,a.mdmod
,mdobj
,mdsct

--------------CUENTA  419595

UNION ALL 

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
--,[dbo].[F_Conv_Cod_Agente](a.AGENTE_LIDER) AS INTERMEDIARIO_LIDE
,[dbo].[F_Conv_Cod_Agente](a.mdagl) AS INTERMEDIARIO_LIDE 
,[dbo].[F_Conv_Cod_Agente](a.mdagc) AS INTERMEDIARIO_COCO 
,sum(cast(mdaag as FLOAT)) as VALOR_RETORNO
,'Retornos' AS Concepto_nivel_3
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
WHERE PERIODO_CONTABLE >= @periodo_contable --AND RAMO_PROD = '900753'
GROUP BY RAMO_PROD,POLIZA,CERTIFICADO,COD_MODALIDAD ) t3  on t3.ramo_prod = a.mdprt and t3.poliza = a.mdpza and t3.certificado = a.mdctd 
WHERE a.mdpek >= @periodo_contable   and mdobj in (419595)  AND a.mdsct IN   (1,31)--,100,90,96)  

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
,a.mdmod
,mdobj
,mdsct

--------------- 429595

UNION ALL 

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
--,[dbo].[F_Conv_Cod_Agente](a.AGENTE_LIDER) AS INTERMEDIARIO_LIDE
,[dbo].[F_Conv_Cod_Agente](a.mdagl) AS INTERMEDIARIO_LIDE 
,[dbo].[F_Conv_Cod_Agente](a.mdagc) AS INTERMEDIARIO_COCO 
,sum(cast(mdaag as FLOAT)) as VALOR_RETORNO
,'Retornos' AS Concepto_nivel_3
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
WHERE PERIODO_CONTABLE >= @periodo_contable --AND RAMO_PROD = '900753'
GROUP BY RAMO_PROD,POLIZA,CERTIFICADO,COD_MODALIDAD ) t3  on t3.ramo_prod = a.mdprt and t3.poliza = a.mdpza and t3.certificado = a.mdctd 
WHERE a.mdpek >= @periodo_contable   and mdobj in (429595)  AND a.mdsct IN   (96,90,100)  

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
,a.mdmod
,mdobj
,mdsct 


------- 519585 

UNION ALL 

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
--,[dbo].[F_Conv_Cod_Agente](a.AGENTE_LIDER) AS INTERMEDIARIO_LIDE
,[dbo].[F_Conv_Cod_Agente](a.mdagl) AS INTERMEDIARIO_LIDE 
,[dbo].[F_Conv_Cod_Agente](a.mdagc) AS INTERMEDIARIO_COCO 
,sum(cast(mdaag as FLOAT)) as VALOR_RETORNO
,'Retornos' AS Concepto_nivel_3
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
WHERE PERIODO_CONTABLE >= @periodo_contable --AND RAMO_PROD = '900753'
GROUP BY RAMO_PROD,POLIZA,CERTIFICADO,COD_MODALIDAD ) t3  on t3.ramo_prod = a.mdprt and t3.poliza = a.mdpza and t3.certificado = a.mdctd 
WHERE a.mdpek >= @periodo_contable   and mdobj in (519585)  AND a.mdsct IN   (5,7)  

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
,a.mdmod
,mdobj
,mdsct
