-- ========================================================================================
-- PL_COL_DATOS_COCO_Comisiones_completo.sql
-- ========================================================================================
-- Archivo CONSOLIDADO de referencia (solo lectura), armado automaticamente a partir
-- de los scripts DDL/DML extraidos del workflow KNIME 'Detalle_comisiones.knwf', en el
-- orden real de ejecucion (orden topologico de las conexiones del workflow.knime) hacia
-- la tabla liberty_pruebas_actuaria.dbo.PL_COL_DATOS_COCO_Comisiones.
--
-- La tabla se alimenta de 5 'conceptos' de comision calculados por separado y unidos
-- (UNION) antes de la carga: RETORNOS, COMISION_INTERMEDIACION, COMISION_REASEGURO,
-- SOBRECOMISION y RETORNOS_A. Despues de la carga (DB Insert #390), dos DB SQL Executor
-- (#403 y #410) hacen UPDATE directo sobre la tabla ya insertada para completar datos
-- del tomador/beneficiario, cuentas contables (SAP/CUIF) y el porcentaje de comision.
--
-- IMPORTANTE (orden #390 vs #403/#410): en el grafo del workflow, #403 y #410 NO estan
-- conectados por flujo de datos al DB Insert (#390) -- solo comparten la misma conexion
-- de base de datos (#391). KNIME no garantiza que corran despues del insert; el orden
-- aqui asumido (390 -> 403 -> 410) es el logico/de negocio, no uno verificable en el
-- grafo. Confirmalo contra la ejecucion real antes de asumirlo como definitivo.
--
-- IMPORTANTE (no ejecutar tal cual): al pegar todos los scripts uno detras de otro,
-- varios reutilizan los mismos nombres de tabla temporal (#...), asi que si se corre
-- todo junto se van a pisar entre si. Cada script se debe seguir ejecutando dentro de
-- su propio grupo, como esta organizado en las carpetas sql/<grupo>/DDL|DML/.
--
-- El grupo 99_CONSULTAS_SUELTAS_SIN_CONEXION (ver carpeta aparte) NO se incluye aqui:
-- son consultas de verificacion/depuracion que el desarrollador dejo pegadas a las
-- tablas temporales intermedias, sin conexion de salida hacia ningun lado -- no alimentan
-- PL_COL_DATOS_COCO_Comisiones.
-- ========================================================================================


-- ----------------------------------------------------------------------------------------
-- PASO 0: Conexion y parametro de periodo contable
-- ----------------------------------------------------------------------------------------
-- ---- Nodo KNIME sin SQL: Variable Expressions _legacy_ (#192) ----
-- Define/ajusta la variable de flujo 'periodo_contable' que KNIME sustituye en cada $${Speriodo_contable}$$ de los scripts.

-- ---- Nodo KNIME sin SQL: Microsoft SQL Server Connector (#74) ----
-- Conexion de solo lectura a Liberty_pruebas_actuaria. La reutilizan las 5 ramas de calculo (RETORNOS, COMISION_INTERMEDIACION, COMISION_REASEGURO, SOBRECOMISION, RETORNOS_A).


-- ----------------------------------------------------------------------------------------
-- PASO 1: Concepto RETORNOS -- devoluciones/reversiones de comision (cuentas 513095, 419595, 429595, 519585 de liberty.middleware.BASE_H)
-- ----------------------------------------------------------------------------------------
-- ==== [01_RETORNOS__75] sql/01_RETORNOS__75/DDL/DB_SQL_Executor__75.sql ====
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

-- ==== [01_RETORNOS__75] sql/01_RETORNOS__75/DDL/DB_SQL_Executor__373.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#373)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#retorno_p','U') is not null drop table #retorno_p

select
a.PERIODO_CONTABLE
,a.SBU
,a.SUCURSAL_PROD
,A.SUCURSAL_CONTABLE
,a.RAMO_PROD
,a.RAMO_CONTABLE
,a.poliza
,a.certificado
,a.recibo
,a.fi_documento
,a.ff_documento
,a.INTERMEDIARIO_LIDE
,a.INTERMEDIARIO_COCO
,a.VALOR_RETORNO
,coalesce(/*pc1.mapped_sapprofitcenter,*/ pc2.mapped_sapprofitcenter, pc3.mapped_sapprofitcenter, pc4.mapped_sapprofitcenter, pc5.mapped_sapprofitcenter, pc6.mapped_sapprofitcenter, pc7.mapped_sapprofitcenter, pc8.mapped_sapprofitcenter, pc9.mapped_sapprofitcenter) as cod_profitcenter
,coalesce(/*pc1.[description],*/ pc2.[description], pc3.[description], pc4.[description], pc5.[description], pc6.[description], pc7.[description], pc8.[description], pc9.[description]) as desc_profitcenter
,coalesce(/*pc1.[description],*/ pc2.lob_g1, pc3.lob_g1, pc4.lob_g1, pc5.lob_g1, pc6.lob_g1, pc7.lob_g1, pc8.lob_g1, pc9.lob_g1) as  LOB
,a.Concepto_nivel_3
,a.Concepto_nivel_2
,a.Concepto_nivel_1
,a.Concepto_nivel_0
,cuenta
,subcuenta
into #retorno_p
from #retorno a
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 1) pc1
	on a.ramo_contable = pc1.ramo_contable
	and a.ramo_prod = pc1.ramo_producto_tecnico
	and a.sucursal_prod = pc1.sucursal_contable
	and a.modalidad = pc1.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 2) pc2
	on a.ramo_contable = pc2.ramo_contable
	and a.ramo_prod = pc2.ramo_producto_tecnico
	and a.sucursal_prod = pc2.sucursal_contable
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 3) pc3
	on a.ramo_contable = pc3.ramo_contable
	and a.ramo_prod = pc3.ramo_producto_tecnico
	and a.modalidad = pc3.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 4) pc4
	on a.ramo_contable = pc4.ramo_contable
	and a.sucursal_prod = pc4.sucursal_contable
	and a.modalidad = pc4.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 5) pc5
	on a.ramo_contable = pc5.ramo_contable
	and a.modalidad = pc5.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 6) pc6
	on a.ramo_contable = pc6.ramo_contable
	and a.sucursal_prod = pc6.sucursal_contable
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 7) pc7
	on a.ramo_contable = pc7.ramo_contable
	and a.ramo_prod = pc7.ramo_producto_tecnico
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 8) pc8
	on a.ramo_contable = pc8.ramo_contable
cross join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 9) pc9

-- ==== [01_RETORNOS__75] sql/01_RETORNOS__75/DDL/DB_SQL_Executor__195.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#195)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#retornos_1','U') is not null drop table #retornos_1



select
PERIODO_CONTABLE
,SUCURSAL_PROD
,RAMO_PROD
,poliza
,certificado
,recibo - 1 as recibo
,SBU
,INTERMEDIARIO_LIDE
,SUM(VALOR_RETORNO) as VALOR_CONCEPTO
,cod_profitcenter
,desc_profitcenter
,SUBSTRING(LOB, 1, charindex('-', LOB)-1) as cod_sbu_sap 
,SUBSTRING(LOB, charindex('-', LOB)+1, len(LOB))  as desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,cuenta
,subcuenta
into #retornos_1
from #retorno_p
group by
PERIODO_CONTABLE
,SUCURSAL_PROD
,RAMO_PROD
,poliza
,certificado
,recibo
,SBU
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,LOB
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,cuenta
,subcuenta

-- ==== [01_RETORNOS__75] sql/01_RETORNOS__75/DDL/DB_SQL_Executor__366.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#366)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#pol','U') is not null drop table #pol

SELECT DISTINCT *
into #pol
FROM 
(
select 
ramo_prod,
poliza,
certificado,
max(documento) as documento 

from  liberty.prod.dwh_polizas_h 
where periodo_contable >=202001
group by ramo_prod,poliza,certificado
) a


if OBJECT_ID('#recibo','U') is not null drop table #recibo

SELECT DISTINCT *
into #recibo
FROM 
(
select 
ramo_prod,
poliza,
certificado,
recibo,
max(documento) as documento 

from  liberty.prod.dwh_polizas_h 
where periodo_contable >=202001
group by ramo_prod,poliza,certificado,recibo
) b

-- ==== [01_RETORNOS__75] sql/01_RETORNOS__75/DDL/DB_SQL_Executor__313.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#313)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#retornos_docu','U') is not null drop table #retornos_docu



select
a.PERIODO_CONTABLE
,a.SUCURSAL_PROD
,a.RAMO_PROD
,a.poliza
,a.certificado
--,a.recibo
,coalesce(b.documento,c.documento) as documento
,a.SBU
,a.INTERMEDIARIO_LIDE
,a.cod_profitcenter
,a.desc_profitcenter
,a.cod_sbu_sap
,a.desc_sbu_sap
,a.Concepto_nivel_3
,a.Concepto_nivel_2
,a.Concepto_nivel_1
,a.Concepto_nivel_0
,a.VALOR_CONCEPTO
,cuenta
,subcuenta
into #retornos_docu
from #retornos_1 a
left join #recibo b on a.ramo_prod = b.ramo_prod and a.poliza = b.poliza and a.certificado = b.certificado and a.recibo = b.recibo
--left join  liberty.prod.dwh_polizas_h b on a.ramo_prod = b.ramo_prod and a.poliza = b.poliza and a.certificado = b.certificado and a.recibo = b.recibo
left join  #pol c on a.ramo_prod = c.ramo_prod and a.poliza = c.poliza and a.certificado = c.certificado

-- ==== [01_RETORNOS__75] sql/01_RETORNOS__75/DDL/DB_SQL_Executor__320.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#320)
-- Clave      : statement

USE Liberty_pruebas_actuaria


/*****************
TEMPORAL COCORRETAJE
******************/

if OBJECT_ID('tempdb.dbo.#corretaje','U') is not null drop table #corretaje

/************
Esta tabla trae un rango de docuemnto al que le debe aplicar el corretaje 
Soluciona el punto de las cancelaciones que no distribuyen el corretaje
Incluir este proceso para tenerlo actualziado todos los meses
*************/

select
distinct 
c.llave_cert
,c.llave_pol
,c.COD_ramo_prod
,c.NRO_poliza
,c.NRO_certificado
,c.documento
,c.COD_INTERMEDIARIO
,c.PARTICIPACION
,c.DOC_2
,i.cod_sucursal
into #corretaje
from [Liberty_Pruebas_Actuaria].[dbo].DWH_CORRETAJE_H_COMPLETO c
left join  
liberty.[APOYO].[DWH_INTERMEDIARIOS_TOTAL] i on c.cod_intermediario = i.cod_intermediario



/************
El siguiente codigo funciona como tabla base de cocorretaje sin tener en cuenta que las 
cancelaciones no esta abriendo el corretaje
*************/
--select  
--distinct
--c.COD_RAMO_PROD
--,c.NRO_POLIZA
--,c.NRO_CERTIFICADO
--,c.DOCUMENTO
--,c.COD_INTERMEDIARIO
----,c.COD_SUCURSAL
--,c.PARTICIPACION
--,c.TIPO_DISTRIBUCION
--,i.cod_sucursal
--into #corretaje
--from [Liberty].[PROD].[DWH_CORRETAJE_H] c
--left join  
--liberty.[APOYO].[DWH_INTERMEDIARIOS_TOTAL] i on c.cod_intermediario = i.cod_intermediario


/*********************
temporal de sucursal: Se crea esta temporal para asignar sucursal al final del proceso de asignación de corretaje 
*********************/




if OBJECT_ID('tempdb.dbo.#cocorretaje_sucursal_i','U') is not null drop table #cocorretaje_sucursal_i

select 
a.PERIODO_CONTABLE
,a.SUCURSAL_PROD
,a.RAMO_PROD
,a.POLIZA
,a.CERTIFICADO
,a.DOCUMENTO
,a.SBU
,a.INTERMEDIARIO_LIDE
,a.cod_profitcenter
,a.desc_profitcenter
,a.cod_sbu_sap
,a.desc_sbu_sap
,a.Concepto_nivel_3
,a.Concepto_nivel_2 
,a.Concepto_nivel_1 
,a.Concepto_nivel_0 
,a.VALOR_CONCEPTO
,CASE WHEN B.LLAVE_CERT IS NULL THEN 0 ELSE 1 END as Marca_corretaje
,cuenta
,subcuenta
into #cocorretaje_sucursal_i
from #retornos_docu a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje) B ON (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT)


if OBJECT_ID('tempdb.dbo.#sucursal_i','U') is not null drop table #sucursal_i


select 
--distinct
row_number() over(order by poliza,certificado,documento) as id
,a.PERIODO_CONTABLE
,a.SUCURSAL_PROD
,a.RAMO_PROD
,a.POLIZA
,a.CERTIFICADO
,a.DOCUMENTO
,a.SBU
,a.INTERMEDIARIO_LIDE
,a.cod_profitcenter
,a.desc_profitcenter
,a.cod_sbu_sap
,a.desc_sbu_sap
,a.Concepto_nivel_3
,a.Concepto_nivel_2 
,a.Concepto_nivel_1 
,a.Concepto_nivel_0 
,a.VALOR_CONCEPTO
,cuenta
,subcuenta
into  #sucursal_i
from #cocorretaje_sucursal_i a
where Marca_corretaje = 0

-------------------------------------------------




if OBJECT_ID('tempdb.dbo.#cocorretaje_sn_i','U') is not null drop table #cocorretaje_sn_i

select 
a.PERIODO_CONTABLE
--,a.SUCURSAL_PROD
,a.RAMO_PROD
,a.POLIZA
,a.CERTIFICADO
,a.DOCUMENTO
,a.SBU
,a.INTERMEDIARIO_LIDE
,a.cod_profitcenter
,a.desc_profitcenter
,a.cod_sbu_sap
,a.desc_sbu_sap
,a.Concepto_nivel_3
,a.Concepto_nivel_2 
,a.Concepto_nivel_1 
,a.Concepto_nivel_0 
,a.VALOR_CONCEPTO
,CASE WHEN B.LLAVE_CERT IS NULL THEN 0 ELSE 1 END as Marca_corretaje
,cuenta
,subcuenta
into #cocorretaje_sn_i
from #retornos_docu a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje) B ON (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT)

------AND A.documento>=B.documento and A.documento<B.doc_2)

-- ==== [01_RETORNOS__75] sql/01_RETORNOS__75/DDL/DB_SQL_Executor__321.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#321)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/************************
Separamos casos no y si
**************************/

---- Para el caso no cocorretaje se le agregan las columnas necesarias para 
---- el union al final del proceso 

if OBJECT_ID('tempdb.dbo.#no_coco_r2','U') is not null drop table #no_coco_r2

--select *  
--into #no_coco
--from #cocorretaje_sn
--where marca_corretaje =0
--if OBJECT_ID('tempdb.dbo.#no_coco','U') is not null drop table #no_coco

select 
c.*
,row_number() over(order by poliza,certificado,documento) as id
,INTERMEDIARIO_LIDE AS COD_INTERMEDIARIO,
0 AS PARTICIPACION,
DOCUMENTO AS DOC,
--SUCURSAL_PROD AS COD_SUCURSAL,
VALOR_CONCEPTO as VALOR_CONCEPTO_CO
into #no_coco_r2
from #cocorretaje_sn_i c
where marca_corretaje =0

-- ==== [01_RETORNOS__75] sql/01_RETORNOS__75/DDL/DB_SQL_Executor__322.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#322)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/************************
Separamos casos  si
**************************/

if OBJECT_ID('tempdb.dbo.#si_coco_r2','U') is not null drop table #si_coco_r2

select *  
into #si_coco_r2
from #cocorretaje_sn_i
where marca_corretaje =1



--select *  
--into #si_coco
--from #cocorretaje_sn
--where cocorretaje =1

-- ==== [01_RETORNOS__75] sql/01_RETORNOS__75/DDL/DB_SQL_Executor__317.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#317)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/*****************
CASO 1 DE COCORRETAJE interemdiario misma sucursal 
******************/

if OBJECT_ID('tempdb.dbo.#caso1_i','U') is not null drop table #caso1_i

select
a.*,
CASE WHEN b.COD_INTERMEDIARIO IS NULL THEN A.INTERMEDIARIO_LIDE ELSE b.COD_INTERMEDIARIO END AS COD_INTERMEDIARIO,
CASE WHEN b.PARTICIPACION IS NULL THEN 0 ELSE b.PARTICIPACION END  AS PARTICIPACION,
CASE WHEN b.DOCUMENTO IS NULL THEN A.DOCUMENTO ELSE b.DOCUMENTO END AS DOC,
CASE WHEN b.PARTICIPACION IS NULL THEN a.VALOR_CONCEPTO
	 ELSE a.VALOR_CONCEPTO * (b.PARTICIPACION/100) 
END as VALOR_CONCEPTO_CO,
b.COD_SUCURSAL
into #caso1_i
from  #si_coco_r2 a
left join #corretaje b 
on (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT AND A.documento>=B.documento and A.documento<B.doc_2)
where
b.PARTICIPACION is not null

-- ==== [01_RETORNOS__75] sql/01_RETORNOS__75/DDL/DB_SQL_Executor__319.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#319)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/*****************
UNION NO CORRETAJE CON LOS CASOS DE CORRETAJE
******************/

if OBJECT_ID('tempdb.dbo.#no_coco_completo_i','U') is not null drop table #no_coco_completo_i

--drop table #no_coco_completo
SELECT 
a.* ,
CONVERT(int,b.SUCURSAL_PROD) as COD_SUCURSAL
into #no_coco_completo_i
FROM #no_coco_r2 a
left join  #sucursal_i b on a.id=b.id
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


alter table #no_coco_completo_i drop column id

-- ==== [01_RETORNOS__75] sql/01_RETORNOS__75/DDL/DB_SQL_Executor__318.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#318)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/*****************
UNION NO CORRETAJE CON LOS CASOS DE CORRETAJE
******************/

if OBJECT_ID('tempdb.dbo.#cocorretaje_completo_i','U') is not null drop table #cocorretaje_completo_i

select * 
into #cocorretaje_completo_i
from
(
SELECT * 
--,'no' as marca
FROM #no_coco_completo_i
UNION all
SELECT * FROM #caso1_i
--, 'caso1' as marca 
--union all
--SELECT * FROM #caso2_1
) a

-- ==== [01_RETORNOS__75] sql/01_RETORNOS__75/DML/DB_Query_Reader__324.sql ====
-- Nodo KNIME : Detalle_comisiones\DB Query Reader (#324)
-- Clave      : sql_statement

USE Liberty_pruebas_actuaria


select 
PERIODO_CONTABLE
,RAMO_PROD
,POLIZA
,SBU
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,Marca_corretaje
,COD_INTERMEDIARIO
,PARTICIPACION
,COD_SUCURSAL
,sum(valor_concepto_co) as VALOR_CONCEPTO
,cuenta
,subcuenta
from #cocorretaje_completo_i
--where poliza = 515244
group by 
PERIODO_CONTABLE
,RAMO_PROD
,POLIZA
,SBU
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,Marca_corretaje
,COD_INTERMEDIARIO
,PARTICIPACION
,COD_SUCURSAL
,cuenta
,subcuenta


-- ----------------------------------------------------------------------------------------
-- PASO 2: Concepto COMISION_INTERMEDIACION -- comision pagada a intermediarios (cuentas 511561, 511570, 411508, 511545 de liberty.middleware.BASE_H)
-- ----------------------------------------------------------------------------------------
-- ==== [02_COMISION_INTERMEDIACION__76] sql/02_COMISION_INTERMEDIACION__76/DDL/DB_SQL_Executor__76.sql ====
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

-- ==== [02_COMISION_INTERMEDIACION__76] sql/02_COMISION_INTERMEDIACION__76/DDL/DB_SQL_Executor__374.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#374)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#directa_p','U') is not null drop table #directa_p

---DIRECTA

select
a.PERIODO_CONTABLE
,a.SBU
,a.SUCURSAL_PROD
,a.SUCURSAL_CONTABLE
,a.RAMO_PROD
,a.ramo_contable
,a.poliza
,a.certificado
,a.recibo
,a.fi_documento
,a.ff_documento
,a.INTERMEDIARIO_LIDE
,a.VALOR_COMISION
,coalesce(/*pc1.mapped_sapprofitcenter,*/ pc2.mapped_sapprofitcenter, pc3.mapped_sapprofitcenter, pc4.mapped_sapprofitcenter, pc5.mapped_sapprofitcenter, pc6.mapped_sapprofitcenter, pc7.mapped_sapprofitcenter, pc8.mapped_sapprofitcenter, pc9.mapped_sapprofitcenter) as cod_profitcenter
,coalesce(/*pc1.[description],*/ pc2.[description], pc3.[description], pc4.[description], pc5.[description], pc6.[description], pc7.[description], pc8.[description], pc9.[description]) as desc_profitcenter
,coalesce(/*pc1.[description],*/ pc2.lob_g1, pc3.lob_g1, pc4.lob_g1, pc5.lob_g1, pc6.lob_g1, pc7.lob_g1, pc8.lob_g1, pc9.lob_g1) as  LOB
,a.Concepto_nivel_3
,a.Concepto_nivel_2
,a.Concepto_nivel_1
,a.Concepto_nivel_0
,cuenta
,subcuenta
into #directa_p
from #directa a
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 1) pc1
	on a.ramo_contable = pc1.ramo_contable
	and a.ramo_prod = pc1.ramo_producto_tecnico
	and a.sucursal_prod = pc1.sucursal_contable
	and a.modalidad = pc1.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 2) pc2
	on a.ramo_contable = pc2.ramo_contable
	and a.ramo_prod = pc2.ramo_producto_tecnico
	and a.sucursal_prod = pc2.sucursal_contable
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 3) pc3
	on a.ramo_contable = pc3.ramo_contable
	and a.ramo_prod = pc3.ramo_producto_tecnico
	and a.modalidad = pc3.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 4) pc4
	on a.ramo_contable = pc4.ramo_contable
	and a.sucursal_prod = pc4.sucursal_contable
	and a.modalidad = pc4.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 5) pc5
	on a.ramo_contable = pc5.ramo_contable
	and a.modalidad = pc5.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 6) pc6
	on a.ramo_contable = pc6.ramo_contable
	and a.sucursal_prod = pc6.sucursal_contable
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 7) pc7
	on a.ramo_contable = pc7.ramo_contable
	and a.ramo_prod = pc7.ramo_producto_tecnico
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 8) pc8
	on a.ramo_contable = pc8.ramo_contable
cross join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 9) pc9

-- ==== [02_COMISION_INTERMEDIACION__76] sql/02_COMISION_INTERMEDIACION__76/DDL/DB_SQL_Executor__197.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#197)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#directa_1','U') is not null drop table #directa_1



select
PERIODO_CONTABLE
,SUCURSAL_PROD
,RAMO_PROD
,POLIZA
,CERTIFICADO
,recibo - 1 as recibo
,SBU
,INTERMEDIARIO_LIDE
,sum(VALOR_COMISION) as VALOR_CONCEPTO
,cod_profitcenter
,desc_profitcenter
,SUBSTRING(LOB, 1, charindex('-', LOB)-1) as cod_sbu_sap 
,SUBSTRING(LOB, charindex('-', LOB)+1, len(LOB))  as desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,cuenta
,subcuenta
into #directa_1
from #directa_p
group by
PERIODO_CONTABLE
,SBU
,SUCURSAL_PROD
,RAMO_PROD
,POLIZA
,CERTIFICADO
,recibo
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,LOB
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,cuenta
,subcuenta

-- ==== [02_COMISION_INTERMEDIACION__76] sql/02_COMISION_INTERMEDIACION__76/DDL/DB_SQL_Executor__367.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#367)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#pol','U') is not null drop table #pol


SELECT DISTINCT *
into #pol
FROM 
(
select 
ramo_prod,
poliza,
certificado,
max(documento) as documento 

from  liberty.prod.dwh_polizas_h 
where periodo_contable >=202001
group by ramo_prod,poliza,certificado
) a


if OBJECT_ID('#recibo2','U') is not null drop table #recibo2

SELECT DISTINCT *
into #recibo2
FROM 
(
select 
ramo_prod,
poliza,
certificado,
recibo,
max(documento) as documento 

from  liberty.prod.dwh_polizas_h 
where periodo_contable >=202001
group by ramo_prod,poliza,certificado,recibo
) b

-- ==== [02_COMISION_INTERMEDIACION__76] sql/02_COMISION_INTERMEDIACION__76/DDL/DB_SQL_Executor__368.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#368)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#directa_docu','U') is not null drop table #directa_docu



select
a.PERIODO_CONTABLE
,a.SUCURSAL_PROD
,a.RAMO_PROD
,a.poliza
,a.certificado
,a.recibo
,coalesce(b.documento,c.documento,1) as documento
,a.SBU
,a.INTERMEDIARIO_LIDE
,a.cod_profitcenter
,a.desc_profitcenter
,a.cod_sbu_sap
,a.desc_sbu_sap
,a.Concepto_nivel_3
,a.Concepto_nivel_2
,a.Concepto_nivel_1
,a.Concepto_nivel_0
,a.VALOR_CONCEPTO
,cuenta
,subcuenta
into #directa_docu
from #directa_1 a
left join  #recibo2 b on a.ramo_prod = b.ramo_prod and a.poliza = b.poliza and a.certificado = b.certificado and a.recibo = b.recibo
left join  #pol c on a.ramo_prod = c.ramo_prod and a.poliza = c.poliza and a.certificado = c.certificado

-- ==== [02_COMISION_INTERMEDIACION__76] sql/02_COMISION_INTERMEDIACION__76/DDL/DB_SQL_Executor__331.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#331)
-- Clave      : statement

USE Liberty_pruebas_actuaria


/*****************
TEMPORAL COCORRETAJE
******************/

if OBJECT_ID('tempdb.dbo.#corretaje','U') is not null drop table #corretaje

/************
Esta tabla trae un rango de docuemnto al que le debe aplicar el corretaje 
Soluciona el punto de las cancelaciones que no distribuyen el corretaje
Incluir este proceso para tenerlo actualziado todos los meses
*************/

select
distinct 
c.llave_cert
,c.llave_pol
,c.COD_ramo_prod
,c.NRO_poliza
,c.NRO_certificado
,c.documento
,c.COD_INTERMEDIARIO
,c.PARTICIPACION
,c.DOC_2
,i.cod_sucursal
into #corretaje
from [Liberty_Pruebas_Actuaria].[dbo].DWH_CORRETAJE_H_COMPLETO c
left join  
liberty.[APOYO].[DWH_INTERMEDIARIOS_TOTAL] i on c.cod_intermediario = i.cod_intermediario



/************
El siguiente codigo funciona como tabla base de cocorretaje sin tener en cuenta que las 
cancelaciones no esta abriendo el corretaje
*************/
--select  
--distinct
--c.COD_RAMO_PROD
--,c.NRO_POLIZA
--,c.NRO_CERTIFICADO
--,c.DOCUMENTO
--,c.COD_INTERMEDIARIO
----,c.COD_SUCURSAL
--,c.PARTICIPACION
--,c.TIPO_DISTRIBUCION
--,i.cod_sucursal
--into #corretaje
--from [Liberty].[PROD].[DWH_CORRETAJE_H] c
--left join  
--liberty.[APOYO].[DWH_INTERMEDIARIOS_TOTAL] i on c.cod_intermediario = i.cod_intermediario


/*********************
temporal de sucursal: Se crea esta temporal para asignar sucursal al final del proceso de asignación de corretaje 
*********************/




if OBJECT_ID('tempdb.dbo.#cocorretaje_sucursal_d','U') is not null drop table #cocorretaje_sucursal_d

select 
a.PERIODO_CONTABLE
,a.SUCURSAL_PROD
,a.RAMO_PROD
,a.POLIZA
,a.CERTIFICADO
,a.DOCUMENTO
,a.SBU
,a.INTERMEDIARIO_LIDE
,a.cod_profitcenter
,a.desc_profitcenter
,a.cod_sbu_sap
,a.desc_sbu_sap
,a.Concepto_nivel_3
,a.Concepto_nivel_2 
,a.Concepto_nivel_1 
,a.Concepto_nivel_0 
,a.VALOR_CONCEPTO
,CASE WHEN B.LLAVE_CERT IS NULL THEN 0 ELSE 1 END as Marca_corretaje
into #cocorretaje_sucursal_d
from #directa_docu a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje) B ON (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT)


if OBJECT_ID('tempdb.dbo.#sucursal_d','U') is not null drop table #sucursal_d


select 
--distinct
row_number() over(order by poliza,certificado,documento) as id
,a.PERIODO_CONTABLE
,a.SUCURSAL_PROD
,a.RAMO_PROD
,a.POLIZA
,a.CERTIFICADO
,a.DOCUMENTO
,a.SBU
,a.INTERMEDIARIO_LIDE
,a.cod_profitcenter
,a.desc_profitcenter
,a.cod_sbu_sap
,a.desc_sbu_sap
,a.Concepto_nivel_3
,a.Concepto_nivel_2 
,a.Concepto_nivel_1 
,a.Concepto_nivel_0 
,a.VALOR_CONCEPTO
into  #sucursal_d
from #cocorretaje_sucursal_d a
where Marca_corretaje = 0

-------------------------------------------------




if OBJECT_ID('tempdb.dbo.#cocorretaje_sn_d','U') is not null drop table #cocorretaje_sn_d

select 
a.PERIODO_CONTABLE
--,a.SUCURSAL_PROD
,a.RAMO_PROD
,a.POLIZA
,a.CERTIFICADO
,a.DOCUMENTO
,a.SBU
,a.INTERMEDIARIO_LIDE
,a.cod_profitcenter
,a.desc_profitcenter
,a.cod_sbu_sap
,a.desc_sbu_sap
,a.Concepto_nivel_3
,a.Concepto_nivel_2 
,a.Concepto_nivel_1 
,a.Concepto_nivel_0 
,a.VALOR_CONCEPTO
,CASE WHEN B.LLAVE_CERT IS NULL THEN 0 ELSE 1 END as Marca_corretaje
,cuenta
,subcuenta
into #cocorretaje_sn_d
from #directa_docu a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje) B ON (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT)

------AND A.documento>=B.documento and A.documento<B.doc_2)

-- ==== [02_COMISION_INTERMEDIACION__76] sql/02_COMISION_INTERMEDIACION__76/DDL/DB_SQL_Executor__330.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#330)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/************************
Separamos casos no y si
**************************/

---- Para el caso no cocorretaje se le agregan las columnas necesarias para 
---- el union al final del proceso 

if OBJECT_ID('tempdb.dbo.#no_coco_d','U') is not null drop table #no_coco_d

--select *  
--into #no_coco
--from #cocorretaje_sn
--where marca_corretaje =0
--if OBJECT_ID('tempdb.dbo.#no_coco','U') is not null drop table #no_coco

select 
c.*
,row_number() over(order by poliza,certificado,documento) as id
,INTERMEDIARIO_LIDE AS COD_INTERMEDIARIO,
0 AS PARTICIPACION,
DOCUMENTO AS DOC,
--SUCURSAL_PROD AS COD_SUCURSAL,
VALOR_CONCEPTO as VALOR_CONCEPTO_CO
into #no_coco_d
from #cocorretaje_sn_d c
where marca_corretaje =0

-- ==== [02_COMISION_INTERMEDIACION__76] sql/02_COMISION_INTERMEDIACION__76/DDL/DB_SQL_Executor__329.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#329)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/************************
Separamos casos  si
**************************/

if OBJECT_ID('tempdb.dbo.#si_coco_d','U') is not null drop table #si_coco_d

select *  
into #si_coco_d
from #cocorretaje_sn_d
where marca_corretaje =1



--select *  
--into #si_coco
--from #cocorretaje_sn
--where cocorretaje =1

-- ==== [02_COMISION_INTERMEDIACION__76] sql/02_COMISION_INTERMEDIACION__76/DDL/DB_SQL_Executor__328.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#328)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/*****************
CASO 1 DE COCORRETAJE interemdiario misma sucursal 
******************/

if OBJECT_ID('tempdb.dbo.#caso1_d','U') is not null drop table #caso1_d

select
a.*,
CASE WHEN b.COD_INTERMEDIARIO IS NULL THEN A.INTERMEDIARIO_LIDE ELSE b.COD_INTERMEDIARIO END AS COD_INTERMEDIARIO,
CASE WHEN b.PARTICIPACION IS NULL THEN 0 ELSE b.PARTICIPACION END  AS PARTICIPACION,
CASE WHEN b.DOCUMENTO IS NULL THEN A.DOCUMENTO ELSE b.DOCUMENTO END AS DOC,
CASE WHEN b.PARTICIPACION IS NULL THEN a.VALOR_CONCEPTO
	 ELSE a.VALOR_CONCEPTO * (b.PARTICIPACION/100) 
END as VALOR_CONCEPTO_CO,
b.COD_SUCURSAL
into #caso1_d
from  #si_coco_d a
left join #corretaje b 
on (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT AND A.documento>=B.documento and A.documento<B.doc_2)
where
b.PARTICIPACION is not null

-- ==== [02_COMISION_INTERMEDIACION__76] sql/02_COMISION_INTERMEDIACION__76/DDL/DB_SQL_Executor__326.sql ====
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

-- ==== [02_COMISION_INTERMEDIACION__76] sql/02_COMISION_INTERMEDIACION__76/DDL/DB_SQL_Executor__327.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#327)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/*****************
UNION NO CORRETAJE CON LOS CASOS DE CORRETAJE
******************/

if OBJECT_ID('tempdb.dbo.#cocorretaje_completo_d','U') is not null drop table #cocorretaje_completo_d

select * 
into #cocorretaje_completo_d
from
(
SELECT * 
--,'no' as marca
FROM #no_coco_completo_d
UNION all
SELECT * FROM #caso1_d
--, 'caso1' as marca 
--union all
--SELECT * FROM #caso2_1
) a

-- ==== [02_COMISION_INTERMEDIACION__76] sql/02_COMISION_INTERMEDIACION__76/DML/DB_Query_Reader__325.sql ====
-- Nodo KNIME : Detalle_comisiones\DB Query Reader (#325)
-- Clave      : sql_statement

USE Liberty_pruebas_actuaria


select 
PERIODO_CONTABLE
,RAMO_PROD
,POLIZA
,SBU
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,Marca_corretaje
,COD_INTERMEDIARIO
,PARTICIPACION
,COD_SUCURSAL
,sum(valor_concepto_co) as VALOR_CONCEPTO
,cuenta
,subcuenta
from #cocorretaje_completo_d
group by 
PERIODO_CONTABLE
,RAMO_PROD
,POLIZA
,SBU
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,Marca_corretaje
,COD_INTERMEDIARIO
,PARTICIPACION
,COD_SUCURSAL
,cuenta
,subcuenta


-- ----------------------------------------------------------------------------------------
-- PASO 3: Concepto COMISION_REASEGURO -- comision recibida del reasegurador (cuentas 411631, 511677 de liberty.middleware.BASE_REASEGUROS_H)
-- ----------------------------------------------------------------------------------------
-- ==== [03_COMISION_REASEGURO__77] sql/03_COMISION_REASEGURO__77/DDL/DB_SQL_Executor__77.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#77)
-- Clave      : statement

USE Liberty_pruebas_actuaria



declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#reaseguro','U') is not null drop table #reaseguro



select
a.MDPEK as PERIODO_CONTABLE
,b.sbu as SBU
,a.MDSUL as SUCURSAL_PROD
,A.MDSUC AS sucursal_contable
,a.MDPRT AS RAMO_PROD
,a.MDRC AS ramo_contable
,a.MDPZA AS poliza
,a.MDCTD AS certificado 
,a.MDOBJ AS cuenta_LOCAL
,a.MDSCT AS subcuenta_local
,a.MDDL1 AS DESCRIPCION_CUENTA_SUB
,case when A.MDLT = 'AA' THEN A.MDAGL ELSE [dbo].[F_Conv_Cod_Agente](a.MDAGL) END AS INTERMEDIARIO_LIDE
,sum(case when MDNAT = 'H' THEN cast(MDAAG as float)*-1 ELSE MDAAG END)   as VALOR_REASEGURO
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,'Comision_reaseguro' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'REINSURANCE_COMMISSION' AS Concepto_nivel_1
,'COMMISSION EXPENSE' AS Concepto_nivel_0
,a.mdmod as modalidad
,mdobj as cuenta
,mdsct as subcuenta
into #reaseguro
from liberty.[MIDDLEWARE].[BASE_REASEGUROS_H] a
--left join
--liberty.prod.dwh_polizas_h t3 on t1.llave = t3.llave Validar cruce modalidad
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.MDPRT = b.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.MDPRT and t4.sucursal = a.MDSUL and t4.ramo_contable = a.MDRC
WHERE a.MDPEK>= @periodo_contable   and MDOBJ in (411631) AND MDSCT in (0101,0102,0108,0301,0302,0303,0304,0305,0306,0307,0308,0310,0315,0317,0325,0327
,0401,0402,0403,0404,405,0405,406,0406,408,0408,0411,0412,0418,425,0425,0107,400,0400,0324,0106,0115,0322,0309,0312,0407)
group by
a.MDPEK
,b.sbu
,a.MDSUL 
,A.MDSUC
,a.MDPRT 
,a.MDRC 
,a.MDPZA
,a.MDCTD 
,a.MDAGL
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,a.MDOBJ
,a.MDSCT 
,a.MDDL1
,a.MDLT
,a.MDNAT
,a.MDAAG
,a.mdmod
,mdobj 
,mdsct 


union all




select
a.MDPEK as PERIODO_CONTABLE
,b.sbu as SBU
,a.MDSUL as SUCURSAL_PROD
,A.MDSUC AS sucursal_contable
,a.MDPRT AS RAMO_PROD
,a.MDRC AS ramo_contable
,a.MDPZA AS poliza
,a.MDCTD AS certificado 
,a.MDOBJ AS cuenta_LOCAL
,a.MDSCT AS subcuenta_local
,a.MDDL1 AS DESCRIPCION_CUENTA_SUB
,case when A.MDLT = 'AA' THEN A.MDAGL ELSE [dbo].[F_Conv_Cod_Agente](a.MDAGL) END AS INTERMEDIARIO_LIDE
,/*sum(case when MDNAT = 'H' THEN cast(MDAAG as float)*-1 ELSE MDAAG END)*/ 
sum(cast(MDAAG as float)) as VALOR_REASEGURO
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,'Comision_reaseguro' AS Concepto_nivel_3
,'INTERFAZ_AUT_4' AS Concepto_nivel_2
,'REINSURANCE_COMMISSION' AS Concepto_nivel_1
,'COMMISSION EXPENSE' AS Concepto_nivel_0
,a.mdmod as modalidad
,mdobj as cuenta
,mdsct as subcuenta
from liberty.[MIDDLEWARE].[BASE_REASEGUROS_H] a
--left join
--liberty.prod.dwh_polizas_h t3 on t1.llave = t3.llave Validar cruce modalidad
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.MDPRT = b.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.MDPRT and t4.sucursal = a.MDSUL and t4.ramo_contable = a.MDRC
WHERE a.MDPEK>= @periodo_contable   and a.MDOBJ  in (511677) and  a.MDSCT  in (0102,0104,0303,0317,0413,0418,0435,0111,0313,0315,0322,101,108)
group by
a.MDPEK
,b.sbu
,a.MDSUL 
,A.MDSUC
,a.MDPRT 
,a.MDRC 
,a.MDPZA
,a.MDCTD 
,a.MDAGL
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,a.MDOBJ
,a.MDSCT 
,a.MDDL1
,a.MDLT
,a.MDNAT
,a.MDAAG
,a.mdmod
,mdobj 
,mdsct 
---------


----select a.fuente,
----			rtrim(ltrim(cast(a.MDSS   as nvarchar(500)))) as SISTEMA --MDSS
----			,rtrim(ltrim(cast(a.MDINT  as nvarchar(500)))) as INTERFACE --MDINT
----			,rtrim(ltrim(cast(a.MDPEK  as nvarchar(500)))) as PERIODO --MDPEK
----			,rtrim(ltrim(cast(a.MDCNT  as nvarchar(500)))) as FECHA --MDCNT
----			,rtrim(ltrim(cast(a.MDCO   as nvarchar(500)))) as COMPANIA --MDCO
----			,rtrim(ltrim(cast(a.MDRC   as nvarchar(500)))) as RAMO_CONTABLE --MDRC
----			,rtrim(ltrim(cast(a.MDSUL  as nvarchar(500)))) as SUCURSAL_PROD --MDSUL
----			,rtrim(ltrim(cast(a.MDSUC  as nvarchar(500)))) as SUCURSAL_CONTABLE --MDSUC
----			,rtrim(ltrim(cast(a.MDMCU  as nvarchar(500)))) as UNIDAD_NEGOCIOS --MDMCU
----			,rtrim(ltrim(cast(a.MDDCT  as nvarchar(500)))) as TIPO_DOC_CONTABLE --MDDCT
----			,rtrim(ltrim(cast(a.MDICUT as nvarchar(500)))) as TIPO_BATCH_CONT --MDICUT
----			,rtrim(ltrim(cast(a.MDLT   as nvarchar(500)))) as LIBRO --MDLT
----			,rtrim(ltrim(cast(a.MDOBJ  as nvarchar(500)))) as CUENTA_LOCAL --MDOBJ
----			,rtrim(ltrim(cast(a.MDSCT  as nvarchar(500)))) as SUBCUENTA_LOCAL --MDSCT
----			,rtrim(ltrim(cast(a.MDDL1  as nvarchar(500)))) as DESCRIPCION_CUENTA_SUB --MDDL1
----			,rtrim(ltrim(cast(a.MDARE  as nvarchar(500)))) as AFILIADO_REASEGUROS --MDARE
----			,rtrim(ltrim(cast(a.MDCEN  as nvarchar(500)))) as CODIGO_ENTIDAD --MDCEN
----			,rtrim(ltrim(cast(a.MDREA  as nvarchar(500)))) as CODIGO_REASEGURADOR --MDREA
----			,rtrim(ltrim(cast(a.MDNAT  as nvarchar(500)))) as NATURALEZA_CONTABLE --MDNAT
----			,rtrim(ltrim(cast(a.MDORR  as nvarchar(500)))) as ORIGEN_REASEGUROS --MDORR
----			,rtrim(ltrim(cast(a.MDPRT  as nvarchar(500)))) as CODIGO_RAMO_PRODUCTO --MDPRT
----			,rtrim(ltrim(cast(a.MDPRR  as nvarchar(500)))) as RAMO_PRODUCTO_REASEGUROS --MDPRR
----			,rtrim(ltrim(cast(a.MDCOR  as nvarchar(500)))) as CONCEPTO_RECAUDO --MDCOR
----			,rtrim(ltrim(cast(a.MDCIR  as nvarchar(500)))) as CIA_REASEGUROS --MDCIR
----			,rtrim(ltrim(cast(a.MDPZA  as nvarchar(500)))) as NUMERO_POLIZA --MDPZA
----			,rtrim(ltrim(cast(a.MDCTD  as nvarchar(500)))) as CERTIFICADO_POLIZA --MDCTD
----			,rtrim(ltrim(cast(a.MDREP  as nvarchar(500)))) as DOC_RECIBO_POLIZA --MDREP
----			,rtrim(ltrim(cast(a.MDMTR  as nvarchar(500)))) as TERCERO_REQUERIDO_SAP --MDMTR
----			,rtrim(ltrim(cast(a.MDTXP  as nvarchar(500)))) as TIPO_ID_TERCERO --MDTXP
----			,rtrim(ltrim(cast(a.MDTXN  as nvarchar(500)))) as NUM_ID_TERCERO --MDTXN
----			,rtrim(ltrim(cast(a.MDDV   as nvarchar(500)))) as DIGITO_VERIFICACION --MDDV
----			,rtrim(ltrim(cast(a.MDTCO  as nvarchar(500)))) as TIPO_CONTRATO --MDTCO
----			,rtrim(ltrim(cast(a.MDACO  as nvarchar(500)))) as ANO_CONTRATO --MDACO
----			,rtrim(ltrim(cast(a.MDCON  as nvarchar(500)))) as NUMERO_CONTRATO --MDCON
----			,rtrim(ltrim(cast(a.MDVCT  as nvarchar(500)))) as VERSION_CONTRATO --MDVCT
----			,rtrim(ltrim(cast(a.MDTMP  as nvarchar(500)))) as TIPO_MOV_POLIZA --MDTMP
----			,rtrim(ltrim(cast(a.MDAGL  as nvarchar(500)))) as AGENTE_LIDER --MDAGL
----			,rtrim(ltrim(cast(a.MDAGC  as nvarchar(500)))) as AGENTE_COCORRETAJE --MDAGC
----			,rtrim(ltrim(cast(a.MDDIV  as nvarchar(500)))) as FECHA_EXPEDICION --MDDIV
----			,rtrim(ltrim(cast(a.MDFIE  as nvarchar(500)))) as FECHA_VIGENCIA --MDFIE
----			,rtrim(ltrim(cast(a.MDFFE  as nvarchar(500)))) as FECHA_FIN_VIG --MDFFE
----			,rtrim(ltrim(cast(a.MDFIC  as nvarchar(500)))) as FECHA_INICIO_DOC --MDFIC
----			,rtrim(ltrim(cast(a.MDFFC  as nvarchar(500)))) as FECHA_FIN_DOC --MDFFC
----			,rtrim(ltrim(cast(a.MDFFS  as nvarchar(500)))) as FECHA_SINIESTRO --MDFFS
----			,rtrim(ltrim(cast(a.MDFMV  as nvarchar(500)))) as FECHA_MOVIMIENTO --MDFMV
----			,rtrim(ltrim(cast(a.MDNSN  as nvarchar(500)))) as NUMERO_SINIESTRO --MDNSN
----			,rtrim(ltrim(cast(a.MDMOD  as nvarchar(500)))) as MODALIDAD --MDMOD
----			,rtrim(ltrim(cast(a.MDTNV  as nvarchar(500)))) as TIPO_NOV_SINIESTRO --MDTNV
----			,rtrim(ltrim(cast(a.MDTRS  as nvarchar(500)))) as TIPO_RESERVA_SINIES --MDTRS
----			,rtrim(ltrim(cast(a.MDOPG  as nvarchar(500)))) as ORDEN_PAGO_SINIEST --MDOPG
----			,rtrim(ltrim(cast(a.MDCPG  as nvarchar(500)))) as CONCEPTO_PAGO_SINIEST --MDCPG
----			,rtrim(ltrim(cast(a.MDMCT  as nvarchar(500)))) as MARCA_CATAST_SINIEST --MDMCT
----			,rtrim(ltrim(cast(a.MDCRCD as nvarchar(500)))) as MONEDA --MDCRCD
----			,rtrim(ltrim(cast(a.MDAAG  as nvarchar(500)))) as VALOR_RUBRO --MDAAG
----			,rtrim(ltrim(cast(a.MDTCP  as nvarchar(500)))) as TIPO_ID --MDTCP
----			,rtrim(ltrim(cast(a.MDTCN  as nvarchar(500)))) as NUMERO_ID --MDTCN
----			,rtrim(ltrim(cast(a.MDFUT1 as nvarchar(500)))) as FUTURO_1 --MDFUT1
----			,rtrim(ltrim(cast(a.MDFUT2 as nvarchar(500)))) as FUTURO_2 --MDFUT2
----			,rtrim(ltrim(cast(a.MDFUT3 as nvarchar(500)))) as FUTURO_3 --MDFUT3
----			,rtrim(ltrim(cast(a.MDFUT4 as nvarchar(500)))) as FUTURO_4 --MDFUT4
----			,rtrim(ltrim(cast(a.MDFGN  as nvarchar(500)))) as FECHA_GENERA_INTERFACE --MDFGN
----			,rtrim(ltrim(cast(a.MDHGN  as nvarchar(500)))) as HORA_GENERA_INTERFACE --MDHGN
----			,rtrim(ltrim(cast(a.MDPID  as nvarchar(500)))) as PROGRAMA_INTERFACE --MDPID
----			,rtrim(ltrim(cast(a.MDUSU  as nvarchar(500)))) as USUARIO_INTERFACE --MDUSU
----			,rtrim(ltrim(cast(a.MDFCG  as nvarchar(500)))) as FECHA_CARGUE_DWH --MDFCG
----			,rtrim(ltrim(cast(a.MDHCG  as nvarchar(500)))) as HORA_CARGUE_DWH --MDHCG
----from liberty.[MIDDLEWARE].[BASE_REASEGUROS_H] a
----where MDPEK = 202504 and MDOBJ  in (411631) and  MDSCT in (0101,0102,0108,0301,0302,0303,0304,0305,0306,0307,0308,0310,0315,0317,0325,0327,0401,0402,0403
----,0404,405,0405,406,0406,408,0408,0411,0412,0418,425,0425,0107,400,0400,0324,0106,0115,0322,0309,0312,0

-- ==== [03_COMISION_REASEGURO__77] sql/03_COMISION_REASEGURO__77/DDL/DB_SQL_Executor__397.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#397)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#directa_p','U') is not null drop table #directa_p

---DIRECTA

select
a.PERIODO_CONTABLE
,a.SBU
,a.SUCURSAL_PROD
,a.SUCURSAL_CONTABLE
,a.RAMO_PROD
,a.ramo_contable
,a.poliza
,a.certificado
--,a.recibo
--,a.fi_documento
--,a.ff_documento
,a.INTERMEDIARIO_LIDE
,a.VALOR_REASEGURO
,coalesce(/*pc1.mapped_sapprofitcenter,*/ pc2.mapped_sapprofitcenter, pc3.mapped_sapprofitcenter, pc4.mapped_sapprofitcenter, pc5.mapped_sapprofitcenter, pc6.mapped_sapprofitcenter, pc7.mapped_sapprofitcenter, pc8.mapped_sapprofitcenter, pc9.mapped_sapprofitcenter) as cod_profitcenter
,coalesce(/*pc1.[description],*/ pc2.[description], pc3.[description], pc4.[description], pc5.[description], pc6.[description], pc7.[description], pc8.[description], pc9.[description]) as desc_profitcenter
,coalesce(/*pc1.[description],*/ pc2.lob_g1, pc3.lob_g1, pc4.lob_g1, pc5.lob_g1, pc6.lob_g1, pc7.lob_g1, pc8.lob_g1, pc9.lob_g1) as  LOB
,a.Concepto_nivel_3
,a.Concepto_nivel_2
,a.Concepto_nivel_1
,a.Concepto_nivel_0
,cuenta
,subcuenta
into #reaseguro_p
from #reaseguro a
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 1) pc1
	on a.ramo_contable = pc1.ramo_contable
	and a.ramo_prod = pc1.ramo_producto_tecnico
	and a.sucursal_prod = pc1.sucursal_contable
	and a.modalidad = pc1.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 2) pc2
	on a.ramo_contable = pc2.ramo_contable
	and a.ramo_prod = pc2.ramo_producto_tecnico
	and a.sucursal_prod = pc2.sucursal_contable
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 3) pc3
	on a.ramo_contable = pc3.ramo_contable
	and a.ramo_prod = pc3.ramo_producto_tecnico
	and a.modalidad = pc3.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 4) pc4
	on a.ramo_contable = pc4.ramo_contable
	and a.sucursal_prod = pc4.sucursal_contable
	and a.modalidad = pc4.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 5) pc5
	on a.ramo_contable = pc5.ramo_contable
	and a.modalidad = pc5.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 6) pc6
	on a.ramo_contable = pc6.ramo_contable
	and a.sucursal_prod = pc6.sucursal_contable
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 7) pc7
	on a.ramo_contable = pc7.ramo_contable
	and a.ramo_prod = pc7.ramo_producto_tecnico
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 8) pc8
	on a.ramo_contable = pc8.ramo_contable
cross join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 9) pc9

-- ==== [03_COMISION_REASEGURO__77] sql/03_COMISION_REASEGURO__77/DDL/DB_SQL_Executor__371.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#371)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#reaseguro_1','U') is not null drop table #reaseguro_1



select
PERIODO_CONTABLE
,RAMO_PROD
,'' AS POLIZA
,SBU
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,SUBSTRING(LOB, 1, charindex('-', LOB)-1) as cod_sbu_sap 
,SUBSTRING(LOB, charindex('-', LOB)+1, len(LOB))  as desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,0 AS Marca_corretaje
,INTERMEDIARIO_LIDE AS COD_INTERMEDIARIO
,0 AS PARTICIPACION
,SUCURSAL_PROD AS COD_SUCURSAL
,sum(VALOR_REASEGURO) as VALOR_CONCEPTO
,cuenta
,subcuenta
into #reaseguro_1
from #reaseguro_P
group by
PERIODO_CONTABLE
,SBU
,SUCURSAL_PROD
,RAMO_PROD
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,LOB
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,cuenta
,subcuenta

-- ==== [03_COMISION_REASEGURO__77] sql/03_COMISION_REASEGURO__77/DML/DB_Query_Reader__207.sql ====
-- Nodo KNIME : Detalle_comisiones\DB Query Reader (#207)
-- Clave      : sql_statement

SELECT
*
FROM #REASEGURO_1


-- ----------------------------------------------------------------------------------------
-- PASO 4: Concepto SOBRECOMISION -- comision adicional/bono (liberty.comercial.DWH_OC_REMUNERACION_TECNICO_H)
-- ----------------------------------------------------------------------------------------
-- ==== [04_SOBRECOMISION__214] sql/04_SOBRECOMISION__214/DDL/DB_SQL_Executor__214.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#214)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=(year(dateadd(month,-1,convert(date,concat(convert(int,$${Speriodo_contable}$$),'01'))))*100)+month(dateadd(month,-1,convert(date,concat(convert(int,$${Speriodo_contable}$$),'01'))))



if OBJECT_ID('tempdb.dbo.#sobre','U') is not null drop table #sobre



select case when len(mes) = 1 then concat(ano,'0',mes) else concat(ano,mes) end as PERIODO_CONTABLE
,a.* 
into #sobre
from (
select 
a.PERIODO_CONTABLE as perido,
month(convert(varchar,dateadd(month,1,convert(date,concat(a.PERIODO_CONTABLE,'01'))))) as Mes,
year(convert(varchar,dateadd(month,1,convert(date,concat(a.PERIODO_CONTABLE,'01'))))) as Ano
,a.SBU
,a.RAMO_CONTABLE
,a.RAMO_PROD	
,a.COD_SUCURSAL AS SUCURSAL_PROD
,a.COD_INTERMEDIARIO_LIDER	 AS INTERMEDIARIO_LIDE
,sum(a.VR_SOBRECOMISION) as VALOR_COMISION
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,'SobreComision' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'COMMISSION EXPENSE' AS Concepto_nivel_1
,'COMMISSION EXPENSE' AS Concepto_nivel_0
,0 as cuenta
,0 as subcuenta
--from liberty.[COMERCIAL].[DWH_OC_REMUNERACION_CONTABLE_H] a
from liberty.comercial.DWH_OC_REMUNERACION_TECNICO_H a
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.ramo_prod and t4.sucursal = a.cod_sucursal and t4.ramo_contable = a.ramo_contable
WHERE a.periodo_contable >= @periodo_contable
group by
a.PERIODO_CONTABLE
,a.SBU
,a.RAMO_CONTABLE
,a.RAMO_PROD	
,a.COD_SUCURSAL
,a.COD_INTERMEDIARIO_LIDER	
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
) a


----- consulta contable solo la cuenta 511561

--select * from liberty.[COMERCIAL].[DWH_OC_REMUNERACION_CONTABLE_H]
--select periodo_contable,cuenta,subcuenta,sum(valores) as sobre from liberty.[COMERCIAL].[DWH_OC_REMUNERACION_CONTABLE_H]
--where periodo_contable=202210 and cuenta in (236005,251595,253500,255505,511561) and subcuenta in (1,2,4,504,8,1704,20)
--group by periodo_contable,cuenta,subcuenta
--order by 1

-- ==== [04_SOBRECOMISION__214] sql/04_SOBRECOMISION__214/DDL/DB_SQL_Executor__215.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#215)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#sobre_1','U') is not null drop table #sobre_1



select
PERIODO_CONTABLE
,SBU
,SUCURSAL_PROD as SUCURSAL_PROD
,INTERMEDIARIO_LIDE AS INTERMEDIARIO_LIDE
,sum(VALOR_COMISION) as VALOR_CONCEPTO
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
into #sobre_1
from #sobre
group by
PERIODO_CONTABLE
,SBU
,SUCURSAL_PROD
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0

-- ==== [04_SOBRECOMISION__214] sql/04_SOBRECOMISION__214/DML/DB_Query_Reader__216.sql ====
-- Nodo KNIME : Detalle_comisiones\DB Query Reader (#216)
-- Clave      : sql_statement

SELECT * FROM #SOBRE_1


-- ----------------------------------------------------------------------------------------
-- PASO 5: Concepto RETORNOS_A -- devoluciones de comision via interfaz legado AS400 (liberty.AS400.F590475 y liberty.AS400.REFPAGOS)
-- ----------------------------------------------------------------------------------------
-- ==== [05_RETORNOS_A__231] sql/05_RETORNOS_A__231/DDL/DB_SQL_Executor__231.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#231)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#retorno_2','U') is not null drop table #retorno_2

----liberty.[AS400].[F590475]

select 
SUBSTRING(cast(a.IVFECI as varchar),0,7) AS PERIODO_CONTABLE
,b.SBU
,a.IVSUCL as sucursal_prod
,a.IVRAMO as ramo_prod
,a.IV$RAC AS RAMO_CONTABLE
,a.IVPOLI as poliza
,a.IVCERT as certificado
,a.IVDOCU as documento
--,a.IVCTIV AS CODIGO
,a.IVCLVI AS INTERMEDIARIO_LIDE
,SUM(a.IVIA15)*-1 AS VALOR_RETORNO
--,t4.cod_profitcenter
--,t4.desc_profitcenter
--,t4.cod_sbu_sap
--,t4.desc_sbu_sap
,case when a.IVRAMO = 'E1' AND a.IV$RAC = 149 THEN 'RCO3130004' ELSE t4.cod_profitcenter end as cod_profitcenter
,case when a.IVRAMO = 'E1' AND a.IV$RAC = 149 THEN 'Eventos Criticos Individual' ELSE t4.desc_profitcenter end as desc_profitcenter
,case when a.IVRAMO = 'E1' AND a.IV$RAC = 149 THEN '7150' ELSE t4.cod_sbu_sap end as cod_sbu_sap
,case when a.IVRAMO = 'E1' AND a.IV$RAC = 149 THEN ' Individual Health, Dental, Disabi' ELSE t4.desc_sbu_sap end as desc_sbu_sap
,'Retornos_a' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'COMMISSION EXPENSE' AS Concepto_nivel_1
,'COMMISSION EXPENSE' AS Concepto_nivel_0
,0 as modalidad
,IVCTIV as cuenta 
,0 as subcuenta
into #retorno_2
FROM liberty.[AS400].[F590475] a
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.IVRAMO = b.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.IVRAMO and t4.sucursal = a.IVSUCL and t4.ramo_contable = a.IV$RAC
WHERE IVCTIV = 181 and SUBSTRING(cast(a.IVFECI as varchar),0,7) >=  @periodo_contable
GROUP BY 
a.IVSUCL 
,a.IVRAMO 
,a.IVPOLI 
,a.IVCERT
,a.IVDOCU
,a.IVCTIV
,a.IVFECI
,a.IV$RAC
,a.IVCLVI
,b.SBU
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,IVCTIV


union all

--liberty.[AS400].[REFPAGOS]

select 
b.DCPEKN as periodo_contable
,c.SBU
,b.DCSCLD AS SUCURSAL_PROD
,b.DCRACG as RAMO_PROD
,b.ramo_contable
,b.DCPZNU AS POLIZA
,b.DCCTNU AS CERTIFICADO
,b.DCDCNU AS DOCUMENTO
,b.DCITCG AS INTERMEDIARIO_LIDE
,SUM(b.DCCMPO) AS VALOR_RETORNO
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,'Retornos_a' AS Concepto_nivel_3
,'INTERFAZ_AUT_1' AS Concepto_nivel_2
,'COMMISSION EXPENSE' AS Concepto_nivel_1
,'COMMISSION EXPENSE' AS Concepto_nivel_0
,0 as modalidad
,DCTNNU as cuenta
,0 as subcuenta
from
(
select DCRACG,DCPZNU,	DCCTNU,	DCDCNU,	DCVRPO	,DCCASK	,DCSCLD,DCC9NU,DCFCPO,DCTNNU,DCPIPO,DCIVPO,DCGSPO,DCCMDD,DCS3FB,DCIVAC,DCIVCR,DCICCR,DCRTEF,
DCIBOM,DCNFRA,DCNTMK,DCNTNU,DCRENU,DCPEKN,DCPGNU,DCITCG,DCUNIT,DCP4NU,DCP4CM,DCLTNU,DCCMPO,DCCMQA,DCFCCM,DCFC1C,DCSCTN,DCTPPO,DCUSNB,DCPNNB,DCFCHR,DER_SIS_ORIGEN,
case when a.DCRACG = '462' then '748' 
	 when a.DCRACG = '463' then '735' 	
	 when a.DCRACG = '411' then '411'
	 when a.DCRACG = '410' then '3'
	 when a.DCRACG = 'Z1' then '237'
	 when a.DCRACG = 'ADU' then '267'
	 ELSE '' END AS RAMO_CONTABLE
	 , max(fecha_ejecucion_dwh) as fecha 
from liberty.[AS400].[REFPAGOS] a
where DCPEKN >=  @periodo_contable and DCTNNU = 181 
group by 
DCRACG,DCPZNU,	DCCTNU,	DCDCNU,	DCVRPO	,DCCASK	,DCSCLD,DCC9NU,DCFCPO,DCTNNU,DCPIPO,DCIVPO,DCGSPO,DCCMDD,DCS3FB,DCIVAC,DCIVCR,DCICCR,DCRTEF,
DCIBOM,DCNFRA,DCNTMK,DCNTNU,DCRENU,DCPEKN,DCPGNU,DCITCG,DCUNIT,DCP4NU,DCP4CM,DCLTNU,DCCMPO,DCCMQA,DCFCCM,DCFC1C,DCSCTN,DCTPPO,DCUSNB,DCPNNB,DCFCHR,DER_SIS_ORIGEN
) b
left join 
liberty.apoyo.dwh_sbu_ramo_prod c on b.DCRACG = c.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = b.DCRACG and t4.sucursal = b.DCSCLD and t4.ramo_contable = b.ramo_contable

group by
b.DCPEKN
,c.SBU
,b.DCRACG
,b.ramo_contable
,b.DCPZNU
,b.DCCTNU
,b.DCDCNU
,b.DCSCLD
,b.DCITCG
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,DCTNNU

-- ==== [05_RETORNOS_A__231] sql/05_RETORNOS_A__231/DDL/DB_SQL_Executor__398.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#398)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#retorno_p','U') is not null drop table #retorno_p

select
a.PERIODO_CONTABLE
,a.SBU
,a.SUCURSAL_PROD
--,A.SUCURSAL_CONTABLE
,a.RAMO_PROD
,a.RAMO_CONTABLE
,a.poliza
,a.certificado
,a.documento
--,a.fi_documento
--,a.ff_documento
,a.INTERMEDIARIO_LIDE
--,a.INTERMEDIARIO_COCO
,a.VALOR_RETORNO
,coalesce(/*pc1.mapped_sapprofitcenter,*/ pc2.mapped_sapprofitcenter, pc3.mapped_sapprofitcenter, pc4.mapped_sapprofitcenter, pc5.mapped_sapprofitcenter, pc6.mapped_sapprofitcenter, pc7.mapped_sapprofitcenter, pc8.mapped_sapprofitcenter, pc9.mapped_sapprofitcenter) as cod_profitcenter
,coalesce(/*pc1.[description],*/ pc2.[description], pc3.[description], pc4.[description], pc5.[description], pc6.[description], pc7.[description], pc8.[description], pc9.[description]) as desc_profitcenter
,coalesce(/*pc1.[description],*/ pc2.lob_g1, pc3.lob_g1, pc4.lob_g1, pc5.lob_g1, pc6.lob_g1, pc7.lob_g1, pc8.lob_g1, pc9.lob_g1) as  LOB
,a.Concepto_nivel_3
,a.Concepto_nivel_2
,a.Concepto_nivel_1
,a.Concepto_nivel_0
,cuenta
,subcuenta
into #retorno_p
from #retorno_2 a
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 1) pc1
	on a.ramo_contable = pc1.ramo_contable
	and a.ramo_prod = pc1.ramo_producto_tecnico
	and a.sucursal_prod = pc1.sucursal_contable
	and a.modalidad = pc1.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 2) pc2
	on a.ramo_contable = pc2.ramo_contable
	and a.ramo_prod = pc2.ramo_producto_tecnico
	and a.sucursal_prod = pc2.sucursal_contable
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 3) pc3
	on a.ramo_contable = pc3.ramo_contable
	and a.ramo_prod = pc3.ramo_producto_tecnico
	and a.modalidad = pc3.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 4) pc4
	on a.ramo_contable = pc4.ramo_contable
	and a.sucursal_prod = pc4.sucursal_contable
	and a.modalidad = pc4.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 5) pc5
	on a.ramo_contable = pc5.ramo_contable
	and a.modalidad = pc5.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 6) pc6
	on a.ramo_contable = pc6.ramo_contable
	and a.sucursal_prod = pc6.sucursal_contable
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 7) pc7
	on a.ramo_contable = pc7.ramo_contable
	and a.ramo_prod = pc7.ramo_producto_tecnico
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 8) pc8
	on a.ramo_contable = pc8.ramo_contable
cross join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 9) pc9

-- ==== [05_RETORNOS_A__231] sql/05_RETORNOS_A__231/DDL/DB_SQL_Executor__228.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#228)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#retorno_22','U') is not null drop table #retorno_22



select
PERIODO_CONTABLE
,SUCURSAL_PROD
,ramo_prod
,poliza
,certificado
,documento
,SBU
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,SUBSTRING(LOB, 1, charindex('-', LOB)-1) as cod_sbu_sap 
,SUBSTRING(LOB, charindex('-', LOB)+1, len(LOB))  as desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,SUM(VALOR_RETORNO) as VALOR_CONCEPTO
,cuenta
,subcuenta
into #retorno_22
from #retorno_p
group by
PERIODO_CONTABLE
,SUCURSAL_PROD
,ramo_prod
,poliza
,certificado
,documento
,SBU
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,LOB
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,cuenta
,subcuenta

-- ==== [05_RETORNOS_A__231] sql/05_RETORNOS_A__231/DDL/DB_SQL_Executor__288.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#288)
-- Clave      : statement

USE Liberty_pruebas_actuaria


/*****************
TEMPORAL COCORRETAJE
******************/

if OBJECT_ID('tempdb.dbo.#corretaje','U') is not null drop table #corretaje

/************
Esta tabla trae un rango de docuemnto al que le debe aplicar el corretaje 
Soluciona el punto de las cancelaciones que no distribuyen el corretaje
Incluir este proceso para tenerlo actualziado todos los meses
*************/

select
distinct 
c.llave_cert
,c.llave_pol
,c.COD_ramo_prod
,c.NRO_poliza
,c.NRO_certificado
,c.documento
,c.COD_INTERMEDIARIO
,c.PARTICIPACION
,c.DOC_2
,i.cod_sucursal
into #corretaje
from [Liberty_Pruebas_Actuaria].[dbo].DWH_CORRETAJE_H_COMPLETO c
left join  
liberty.[APOYO].[DWH_INTERMEDIARIOS_TOTAL] i on c.cod_intermediario = i.cod_intermediario



/************
El siguiente codigo funciona como tabla base de cocorretaje sin tener en cuenta que las 
cancelaciones no esta abriendo el corretaje
*************/
--select  
--distinct
--c.COD_RAMO_PROD
--,c.NRO_POLIZA
--,c.NRO_CERTIFICADO
--,c.DOCUMENTO
--,c.COD_INTERMEDIARIO
----,c.COD_SUCURSAL
--,c.PARTICIPACION
--,c.TIPO_DISTRIBUCION
--,i.cod_sucursal
--into #corretaje
--from [Liberty].[PROD].[DWH_CORRETAJE_H] c
--left join  
--liberty.[APOYO].[DWH_INTERMEDIARIOS_TOTAL] i on c.cod_intermediario = i.cod_intermediario


/*********************
temporal de sucursal: Se crea esta temporal para asignar sucursal al final del proceso de asignación de corretaje 
*********************/




if OBJECT_ID('tempdb.dbo.#cocorretaje_sucursal','U') is not null drop table #cocorretaje_sucursal

select 
a.PERIODO_CONTABLE
,a.SUCURSAL_PROD
,a.RAMO_PROD
,a.POLIZA
,a.CERTIFICADO
,a.DOCUMENTO
,a.SBU
,a.INTERMEDIARIO_LIDE
,a.cod_profitcenter
,a.desc_profitcenter
,a.cod_sbu_sap
,a.desc_sbu_sap
,a.Concepto_nivel_3
,a.Concepto_nivel_2 
,a.Concepto_nivel_1 
,a.Concepto_nivel_0 
,a.VALOR_CONCEPTO
,CASE WHEN B.LLAVE_CERT IS NULL THEN 0 ELSE 1 END as Marca_corretaje
,cuenta
,subcuenta
into #cocorretaje_sucursal
from #retorno_22 a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje) B ON (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT)


if OBJECT_ID('tempdb.dbo.#sucursal','U') is not null drop table #sucursal


select 
--distinct
row_number() over(order by poliza,certificado,documento) as id
,a.PERIODO_CONTABLE
,a.SUCURSAL_PROD
,a.RAMO_PROD
,a.POLIZA
,a.CERTIFICADO
,a.DOCUMENTO
,a.SBU
,a.INTERMEDIARIO_LIDE
,a.cod_profitcenter
,a.desc_profitcenter
,a.cod_sbu_sap
,a.desc_sbu_sap
,a.Concepto_nivel_3
,a.Concepto_nivel_2 
,a.Concepto_nivel_1 
,a.Concepto_nivel_0 
,a.VALOR_CONCEPTO
,cuenta
,subcuenta
into  #sucursal
from #cocorretaje_sucursal a
where Marca_corretaje = 0

-------------------------------------------------




if OBJECT_ID('tempdb.dbo.#cocorretaje_sn','U') is not null drop table #cocorretaje_sn

select 
a.PERIODO_CONTABLE
--,a.SUCURSAL_PROD
,a.RAMO_PROD
,a.POLIZA
,a.CERTIFICADO
,a.DOCUMENTO
,a.SBU
,a.INTERMEDIARIO_LIDE
,a.cod_profitcenter
,a.desc_profitcenter
,a.cod_sbu_sap
,a.desc_sbu_sap
,a.Concepto_nivel_3
,a.Concepto_nivel_2 
,a.Concepto_nivel_1 
,a.Concepto_nivel_0 
,a.VALOR_CONCEPTO
,CASE WHEN B.LLAVE_CERT IS NULL THEN 0 ELSE 1 END as Marca_corretaje
,cuenta
,subcuenta
into #cocorretaje_sn
from #retorno_22 a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje) B ON (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT)

------AND A.documento>=B.documento and A.documento<B.doc_2)

-- ==== [05_RETORNOS_A__231] sql/05_RETORNOS_A__231/DDL/DB_SQL_Executor__287.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#287)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/************************
Separamos casos no y si
**************************/

---- Para el caso no cocorretaje se le agregan las columnas necesarias para 
---- el union al final del proceso 

if OBJECT_ID('tempdb.dbo.#no_coco','U') is not null drop table #no_coco

--select *  
--into #no_coco
--from #cocorretaje_sn
--where marca_corretaje =0
--if OBJECT_ID('tempdb.dbo.#no_coco','U') is not null drop table #no_coco

select 
c.*
,row_number() over(order by poliza,certificado,documento) as id
,INTERMEDIARIO_LIDE AS COD_INTERMEDIARIO,
0 AS PARTICIPACION,
DOCUMENTO AS DOC,
--SUCURSAL_PROD AS COD_SUCURSAL,
VALOR_CONCEPTO as VALOR_CONCEPTO_CO
into #no_coco
from #cocorretaje_sn c
where marca_corretaje =0

-- ==== [05_RETORNOS_A__231] sql/05_RETORNOS_A__231/DDL/DB_SQL_Executor__286.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#286)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/************************
Separamos casos  si
**************************/

if OBJECT_ID('tempdb.dbo.#si_coco','U') is not null drop table #si_coco

select *  
into #si_coco
from #cocorretaje_sn
where marca_corretaje =1



--select *  
--into #si_coco
--from #cocorretaje_sn
--where cocorretaje =1

-- ==== [05_RETORNOS_A__231] sql/05_RETORNOS_A__231/DDL/DB_SQL_Executor__291.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#291)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/*****************
CASO 1 DE COCORRETAJE interemdiario misma sucursal 
******************/

if OBJECT_ID('tempdb.dbo.#caso1','U') is not null drop table #caso1

select
a.*,
CASE WHEN b.COD_INTERMEDIARIO IS NULL THEN A.INTERMEDIARIO_LIDE ELSE b.COD_INTERMEDIARIO END AS COD_INTERMEDIARIO,
CASE WHEN b.PARTICIPACION IS NULL THEN 0 ELSE b.PARTICIPACION END  AS PARTICIPACION,
CASE WHEN b.DOCUMENTO IS NULL THEN A.DOCUMENTO ELSE b.DOCUMENTO END AS DOC,
CASE WHEN b.PARTICIPACION IS NULL THEN a.VALOR_CONCEPTO
	 ELSE a.VALOR_CONCEPTO * (b.PARTICIPACION/100) 
END as VALOR_CONCEPTO_CO,
b.COD_SUCURSAL
into #caso1
from  #si_coco a
left join #corretaje b 
on (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT AND A.documento>=B.documento and A.documento<B.doc_2)
where
b.PARTICIPACION is not null

-- ==== [05_RETORNOS_A__231] sql/05_RETORNOS_A__231/DDL/DB_SQL_Executor__289.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#289)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/*****************
UNION NO CORRETAJE CON LOS CASOS DE CORRETAJE
******************/

if OBJECT_ID('tempdb.dbo.#no_coco_completo','U') is not null drop table #no_coco_completo

--drop table #no_coco_completo
SELECT 
a.* ,
CONVERT(int,b.SUCURSAL_PROD) as COD_SUCURSAL
into #no_coco_completo
FROM #no_coco a
left join  #sucursal b on a.id=b.id
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


alter table #no_coco_completo drop column id

-- ==== [05_RETORNOS_A__231] sql/05_RETORNOS_A__231/DDL/DB_SQL_Executor__290.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#290)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/*****************
UNION NO CORRETAJE CON LOS CASOS DE CORRETAJE
******************/

if OBJECT_ID('tempdb.dbo.#cocorretaje_completo','U') is not null drop table #cocorretaje_completo

select * 
into #cocorretaje_completo
from
(
SELECT * 
--,'no' as marca
FROM #no_coco_completo
UNION all
SELECT * FROM #caso1
--, 'caso1' as marca 
--union all
--SELECT * FROM #caso2_1
) a

-- ==== [05_RETORNOS_A__231] sql/05_RETORNOS_A__231/DML/DB_Query_Reader__311.sql ====
-- Nodo KNIME : Detalle_comisiones\DB Query Reader (#311)
-- Clave      : sql_statement

USE Liberty_pruebas_actuaria


select 
cast(PERIODO_CONTABLE as int) as PERIODO_CONTABLE
,RAMO_PROD
,POLIZA
,SBU
,CAST(INTERMEDIARIO_LIDE AS VARCHAR) AS INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,Marca_corretaje
,COD_INTERMEDIARIO
,PARTICIPACION
,COD_SUCURSAL
,sum(valor_concepto_co) as VALOR_CONCEPTO
,cuenta
,subcuenta
from #cocorretaje_completo
group by 
PERIODO_CONTABLE
,RAMO_PROD
,POLIZA
,SBU
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,Marca_corretaje
,COD_INTERMEDIARIO
,PARTICIPACION
,COD_SUCURSAL
,cuenta
,subcuenta


-- ----------------------------------------------------------------------------------------
-- PASO 6: Union de los 5 conceptos, cruce con Excel de sucursales/canales, filtro de periodo y carga (DB Insert) en PL_COL_DATOS_COCO_Comisiones
-- ----------------------------------------------------------------------------------------
-- ---- Nodo KNIME sin SQL: Excel Reader (#48) ----
-- Excel Reader: carga el archivo manual 'Canales y Sucursales.xlsx' (mapeo de canal/sucursal).

-- ---- Nodo KNIME sin SQL: Column Expressions _legacy_ (#208) ----
-- Column Expressions: ajustes de columnas sobre el resultado de COMISION_REASEGURO (#207) antes de concatenar.

-- ---- Nodo KNIME sin SQL: Excel Reader (#212) ----
-- Excel Reader: carga el archivo manual 'Sucursales Andes 2023.xlsx' (mapeo de sucursales heredado).

-- ---- Nodo KNIME sin SQL: Column Expressions _legacy_ (#217) ----
-- Column Expressions: ajustes de columnas sobre el resultado de SOBRECOMISION (#216).

-- ---- Nodo KNIME sin SQL: Column Filter (#341) ----
-- Column Filter: recorta columnas del bloque SOBRECOMISION para que su estructura calce con las demas ramas.

-- ---- Nodo KNIME sin SQL: Column Resorter (#342) ----
-- Column Resorter: reordena columnas del bloque SOBRECOMISION para que calcen antes de concatenar.

-- ---- Nodo KNIME sin SQL: Column Expressions _legacy_ (#355) ----
-- Column Expressions: ajustes de columnas sobre el resultado de COMISION_INTERMEDIACION (#325) antes de concatenar.

-- ---- Nodo KNIME sin SQL: Column Expressions _legacy_ (#356) ----
-- Column Expressions: ajustes de columnas sobre el resultado de RETORNOS (#324) antes de concatenar con las demas ramas.

-- ---- Nodo KNIME sin SQL: Column Expressions _legacy_ (#357) ----
-- Column Expressions: ajustes de columnas sobre el resultado de RETORNOS_A (#311) antes de concatenar.

-- ---- Nodo KNIME sin SQL: Concatenate (#267) ----
-- Concatenate (UNION): junta RETORNOS (#324/#356) + RETORNOS_A (#311/#357).

-- ---- Nodo KNIME sin SQL: Concatenate (#199) ----
-- Concatenate (UNION): junta el resultado anterior (#267) + COMISION_INTERMEDIACION (#325/#355) + COMISION_REASEGURO (#207/#208).

-- ---- Nodo KNIME sin SQL: Concatenate (#209) ----
-- Concatenate (UNION): junta el resultado anterior (#199) + SOBRECOMISION (#216 -> #217 -> #341 -> #342).

-- ---- Nodo KNIME sin SQL: Concatenate (#343) ----
-- Concatenate: paso de consolidacion final de los 5 conceptos antes de cruzar con los Excel de sucursales/canales.

-- ---- Nodo KNIME sin SQL: Joiner (#200) ----
-- Joiner: cruza el consolidado de comisiones (#343) con el Excel 'Canales y Sucursales.xlsx' (#48).

-- ---- Nodo KNIME sin SQL: Joiner (#211) ----
-- Joiner: cruza el resultado anterior con el Excel 'Sucursales Andes 2023.xlsx' (#212).

-- ---- Nodo KNIME sin SQL: Column Expressions _legacy_ (#236) ----
-- Column Expressions: calculos/ajustes finales de columnas antes de filtrar por periodo.

-- ---- Nodo KNIME sin SQL: Row Filter (#401) ----
-- Row Filter: filtra las filas dejando solo el PERIODO_CONTABLE que se va a cargar.

-- ---- Nodo KNIME sin SQL: DB Insert (#390) ----
-- >>> Aqui KNIME ejecuta un DB Insert (no hay SQL escrito a mano; KNIME arma el INSERT solo) hacia:
--   liberty_pruebas_actuaria.dbo.PL_COL_DATOS_COCO_Comisiones
-- con TODAS las filas resultantes del PASO 6 (union de los 5 conceptos + cruces con Excel).


-- ----------------------------------------------------------------------------------------
-- PASO 7: Actualizaciones posteriores a la carga (UPDATE directo sobre PL_COL_DATOS_COCO_Comisiones ya insertada)
-- ----------------------------------------------------------------------------------------
-- ---- Nodo KNIME sin SQL: Microsoft SQL Server Connector (#391) ----
-- Conexion de lectura/escritura a liberty_pruebas_actuaria, usada por el DB Insert (#390) y por las actualizaciones posteriores (#403, #410).

-- ==== [07_ACTUALIZACION_POST_CARGA__403_410] sql/07_ACTUALIZACION_POST_CARGA__403_410/DML/DB_SQL_Executor__403.sql ====
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

-- ==== [07_ACTUALIZACION_POST_CARGA__403_410] sql/07_ACTUALIZACION_POST_CARGA__403_410/DDL/DB_SQL_Executor__410.sql ====
-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#410)
-- Clave      : statement

USE Liberty_pruebas_actuaria


/**********************
Porcentaje comisiones
**********************/


drop table #comisiones
select  periodo_contable,
ramo_prod,poliza,certificado,
round(sum(vr_comision_bas)/nullif(sum(vr_prima_documento),0),3) as por
into #comisiones
from liberty.prod.dwh_pol_amp_h a1
where periodo_contable >= 202601 
group by periodo_contable,ramo_prod,poliza,certificado
order by ramo_prod,poliza,certificado

UPDATE a 
SET porcentaje = b.por
from liberty_pruebas_actuaria.dbo.pl_col_datos_coco_comisiones  a
left join #comisiones b on A.RAMO_PROD = B.RAMO_PROD  AND a.poliza = B.poliza
where  a.PERIODO_CONTABLE >= 202601 and Concepto_nivel_3 = 'Comision_intermediacion'


drop table #comisiones
select  periodo_contable,
ramo_prod,poliza,certificado,
round(sum(vr_comision_bas)/nullif(sum(vr_prima_documento),0),3) as por
into #comisiones_2
from liberty.prod.dwh_pol_amp_h a1
where periodo_contable >= 202601 and tipo_transaccion in (1,2,9)
group by periodo_contable,ramo_prod,poliza,certificado
order by ramo_prod,poliza,certificado

UPDATE a 
SET porcentaje = b.por
from liberty_pruebas_actuaria.dbo.pl_col_datos_coco_comisiones  a
left join #comisiones_2 b on A.RAMO_PROD = B.RAMO_PROD  AND a.poliza = B.poliza
where  a.PERIODO_CONTABLE >= 202601 and Concepto_nivel_3 = 'Comision_intermediacion' and porcentaje is null


-- ----------------------------------------------------------------------------------------
-- PASO 8 (independiente): recarga de las tablas de referencia COMPANIA_CUENTAS_SAP / COMPANIA_CUENTAS_CUIF que usa el PASO 7
-- ----------------------------------------------------------------------------------------
-- ---- Nodo KNIME sin SQL: Excel Reader (#402) ----
-- Excel Reader: carga 'Homologaciones_PUC_CUIF_SAP.xlsx' (mapeo de cuentas locales a SAP).

-- ---- Nodo KNIME sin SQL: Microsoft SQL Server Connector (#404) ----
-- Conexion a liberty_pruebas_actuaria usada para recargar la tabla de referencia COMPANIA_CUENTAS_SAP.

-- ---- Nodo KNIME sin SQL: DB Insert (#405) ----
-- >>> Aqui KNIME ejecuta un DB Insert (no hay SQL escrito a mano) hacia:
--   liberty_pruebas_actuaria.dbo.COMPANIA_CUENTAS_SAP
-- con el contenido del Excel 'Homologaciones_PUC_CUIF_SAP.xlsx' (#402).

-- ---- Nodo KNIME sin SQL: Microsoft SQL Server Connector (#407) ----
-- Conexion a liberty_pruebas_actuaria usada para recargar la tabla de referencia COMPANIA_CUENTAS_CUIF.

-- ---- Nodo KNIME sin SQL: Excel Reader (#408) ----
-- Excel Reader: carga 'Homologaciones_PUC_CUIF_SAP.xlsx' (mismo archivo que #402, mapeo de cuentas locales a CUIF).

-- ---- Nodo KNIME sin SQL: DB Insert (#406) ----
-- >>> Aqui KNIME ejecuta un DB Insert (no hay SQL escrito a mano) hacia:
--   liberty_pruebas_actuaria.dbo.COMPANIA_CUENTAS_CUIF
-- con el contenido del Excel 'Homologaciones_PUC_CUIF_SAP.xlsx' (#408).
