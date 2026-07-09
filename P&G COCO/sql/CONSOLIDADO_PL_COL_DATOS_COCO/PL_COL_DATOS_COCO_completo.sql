-- ============================================================================
-- PL_COL_DATOS_COCO_completo.sql
-- ============================================================================
-- Archivo CONSOLIDADO de referencia (solo lectura), armado automaticamente a
-- partir de los scripts DDL/DML ya extraidos bajo sql/<componente>/ para cada
-- uno de los 8 componentes del workflow KNIME que alimentan la tabla
-- permanente liberty_pruebas_actuaria.dbo.PL_COL_DATOS_COCO.
--
-- El orden entre componentes (Gross Writte -> Written Prem -> COMMISSIONS ->
-- CHANGE_IN_CA #320 -> CHANGE_IN_CA #34 -> SALVAMENTOS -> RECOBROS ->
-- Recobros_sin) es una reconstruccion best-effort basada en docs/FLUJO.md
-- (conexiones de orden documentadas entre Written Prem/#320, #320/#34 y
-- #34/Recobros_sin). El orden real de disparo en KNIME puede diferir; se
-- recomienda contrastar contra sql/<componente>/*/settings.xml o el workflow
-- vivo antes de asumir este orden como definitivo.
--
-- Dentro de cada componente el orden es: DDL/ (ascendente por el numero de
-- nodo embebido en el nombre de archivo) y luego DML/ (mismo criterio).
--
-- IMPORTANTE: este archivo NO esta pensado para ejecutarse tal cual contra
-- una base de datos real. Las tablas temporales #... de distintos componentes
-- o scripts pueden colisionar entre si o requerir ejecucion secuencial en la
-- misma sesion exactamente como fueron escritas originalmente. Este archivo
-- solo concatena los scripts ya extraidos con fines de lectura y referencia.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- COMPONENTE 1/8: Gross Writte (#43) -- Prima emitida bruta
-- Calcula la prima emitida bruta del periodo (produccion de polizas,
-- clasificacion de negocio y reparto por cocorretaje segun PARTICIPACION).
-- Escribe en PL_COL_DATOS_COCO mediante el nodo DB Insert (#260).
-- ----------------------------------------------------------------------------
-- ==== [Gross_Writte__43] sql/Gross_Writte__43/DDL/DB_SQL_Executor__2.sql ====
-- Nodo KNIME : P&G_COCO\Gross Writte (#43)\DB SQL Executor (#2)
-- Clave      : statement
-- Que hace: calcula parte de prima emitida bruta (el valor total de las polizas emitidas, antes de repartir por reaseguro).
-- Arma la tabla temporal #primas_pyg a partir de liberty.prod.dwh_pol_amp_h, liberty.prod.dwh_polizas_h, liberty.apoyo.dwh_sbu_ramo_prod.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.
-- Nota: SOAT: seguro obligatorio de accidentes de transito.

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#primas_pyg','U') is not null drop table #primas_pyg

select
t1.PERIODO_CONTABLE
,t1.SSEGURO	
,t1.SUCURSAL_PROD
,t1.RAMO_PROD
,t1.RAMO_TECNICO
,case when t1.ramo_prod = '900753' and t1.ramo_contable not in (322,323,324) and  t3.cod_modalidad = 1  then 345 
	  when t1.ramo_prod = '900753' and t1.ramo_contable not in (322,323,324) and t3.cod_modalidad  = 2  then 335 
	  when t1.ramo_prod = '900753' and t1.ramo_contable not in (322,323,324) and t3.cod_modalidad  = 3  then 346 
	  when t1.ramo_prod = '900753' and t1.ramo_contable not in (322,323,324) and t3.cod_modalidad  = 4  then 343
	  else t1.RAMO_CONTABLE end as RAMO_CONTABLE
,t1.POLIZA	
,t1.CERTIFICADO	
,t1.DOCUMENTO	
,t1.ANEXO	
,SUM(t1.VR_PRIMA_DOCUMENTO) AS VR_PRIMA_DOCUMENTO --- Prima al 100%
,SUM(t1.VR_PRIMA_MN_ORIG) AS VR_PRIMA_MN_ORIG     --- Prima Contribución SOAT , para lo demas es la misma vr_prima_documento
,t2.SBU
,t1.FI_CERTIFICADO	
,t1.FF_CERTIFICADO	
,t1.FI_DOCUMENTO	
,t1.FF_DOCUMENTO	
,t1.FECHA_EXPE	
,t1.INTERMEDIARIO_LIDE
,t1.vr_p_p_sucursal as vr_p_sucursal
,t3.vr_p_p_sucursal	
,t1.FI_ANEXO	
,t1.FF_ANEXO
,case when t2.sbu = 'AUT' THEN t5.cod_uso_vehic else t3.COD_MODALIDAD end as modalidad	
,t3.cod_modalidad
,t1.TIPO_RIESGO
,t6.COD_TIPO_RIESGO
,sum(isnull(t1.vr_prima_documento, 0) - iif(t1.ramo_prod = 'AO', isnull(t1.vr_prima_mn_orig,0), 0) - iif(t1.ramo_prod = '900730',isnull(t1.vr_contribucion, 0), 0))  as VR_PRIMA_EMITIDA_DIRECTA
,sum(isnull(t1.vr_prima_documento, 0) - isnull(t1.vr_prima_documento_coa, 0)  - iif(t1.ramo_prod = 'AO', isnull(t1.vr_prima_mn_orig, 0), 0) - iif(t1.ramo_prod = '900730', isnull(t1.vr_contribucion, 0), 0)) as vlr_prima_cedida
,sum(isnull(t1.vr_prima_documento_coa, 0)  - iif(t1.ramo_prod = 'AO', isnull(t1.vr_prima_mn_orig, 0), 0) - iif(t1.ramo_prod = '900730', isnull(t1.vr_contribucion, 0), 0)) as GROSS_WRITTEN_PREMIUM
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,'INTERFAZ_AUT' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'GROSS_WRITTEN_PRIMIUM' AS Concepto_nivel_1
,'NET_WRITTEN_PREMIUM' AS Concepto_nivel_0
into #primas_pyg
from  liberty.prod.dwh_pol_amp_h t1
left join
liberty.prod.dwh_polizas_h t3 on t1.llave = t3.llave
left join 
liberty.apoyo.dwh_sbu_ramo_prod t2 on t1.ramo_prod = t2.ramo_prod
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = t1.ramo_prod and t4.sucursal = t1.sucursal_prod and t4.ramo_contable = t1.ramo_contable
left join 
liberty.[DT].[DWH_DT_AUT_AUTOS] t5 on t1.llave = t5.LLAVE_POL
left join 
(select * from liberty.puac.dwh_tipo_riesgo_puac where desc_tipo_riesgo is not null) t6 on t1.sseguro = t6.sseguro  and t1.documento = t6.documento
WHERE 
--t1.periodo_contable BETWEEN 202210 AND 202408
t1.periodo_contable >= @periodo_contable
group by
t1.PERIODO_CONTABLE
,t1.SSEGURO	
,t1.SUCURSAL_PROD
,t1.RAMO_PROD
,t1.RAMO_TECNICO
,t1.RAMO_CONTABLE
,t1.POLIZA	
,t1.CERTIFICADO	
,t1.DOCUMENTO	
,t1.ANEXO	
,t2.SBU
,t1.FI_CERTIFICADO	
,t1.FF_CERTIFICADO	
,t1.FI_DOCUMENTO	
,t1.FF_DOCUMENTO	
,t1.FECHA_EXPE	
,t1.INTERMEDIARIO_LIDE
,t1.vr_p_p_sucursal
,t3.vr_p_p_sucursal		
,t1.FI_ANEXO	
,t1.FF_ANEXO
,t3.cod_modalidad
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,t5.cod_uso_vehic
,t1.TIPO_RIESGO
,t6.cod_tipo_riesgo


-- ==== [Gross_Writte__43] sql/Gross_Writte__43/DDL/DB_SQL_Executor__3.sql ====
-- Nodo KNIME : P&G_COCO\Gross Writte (#43)\DB SQL Executor (#3)
-- Clave      : statement
-- Que hace: calcula parte de prima emitida bruta (el valor total de las polizas emitidas, antes de repartir por reaseguro).
-- Arma la tabla temporal #primas_pyg_inter a partir de otras tablas ya calculadas antes en este mismo componente.

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#primas_pyg_inter','U') is not null drop table #primas_pyg_inter


select
PERIODO_CONTABLE
,SUCURSAL_PROD
,SBU
,INTERMEDIARIO_LIDE	
--,INTERMEDIARIO VALIDAR SI SE INCLUYE PARA LA VISTA DEL TABLERO REQUIERE MODIFICAR EN TODOS LOS OCNCEPTOS Y REPROCESAR
,sum(GROSS_WRITTEN_PREMIUM) as VALOR_CONCEPTO
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
into #primas_pyg_inter
from #primas_pyg
group by
PERIODO_CONTABLE
,SUCURSAL_PROD
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


-- ==== [Gross_Writte__43] sql/Gross_Writte__43/DDL/DB_SQL_Executor__197.sql ====
-- Nodo KNIME : P&G_COCO\Gross Writte (#43)\DB SQL Executor (#197)
-- Clave      : statement
-- Que hace: calcula parte de prima emitida bruta (el valor total de las polizas emitidas, antes de repartir por reaseguro).
-- Arma la tabla temporal #profit a partir de liberty.amocom.homologa_profit_center.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('#profit','U') is not null drop table #profit

drop table #profit


select  
t1.*
,coalesce(/*pc1.mapped_sapprofitcenter,*/ pc2.mapped_sapprofitcenter, pc3.mapped_sapprofitcenter, pc4.mapped_sapprofitcenter, pc5.mapped_sapprofitcenter, pc6.mapped_sapprofitcenter, pc7.mapped_sapprofitcenter, pc8.mapped_sapprofitcenter, pc9.mapped_sapprofitcenter) Profit_nuevo
,coalesce(/*pc1.[description],*/ pc2.[description], pc3.[description], pc4.[description], pc5.[description], pc6.[description], pc7.[description], pc8.[description], pc9.[description]) Descripcion_profit
,coalesce(/*pc1.[description],*/ pc2.lob_g1, pc3.lob_g1, pc4.lob_g1, pc5.lob_g1, pc6.lob_g1, pc7.lob_g1, pc8.lob_g1, pc9.lob_g1) LOB_SAP
into #profit
from  #primas_pyg t1
left join (select * from liberty.amocom.homologa_profit_center where opcion = 1) pc1
	on t1.ramo_contable = pc1.ramo_contable
	and t1.ramo_prod = pc1.ramo_producto_tecnico
	and t1.sucursal_prod = pc1.sucursal_contable
	and t1.modalidad = pc1.modalidad
left join (select * from liberty.amocom.homologa_profit_center where opcion = 2) pc2
	on t1.ramo_contable = pc2.ramo_contable
	and t1.ramo_prod = pc2.ramo_producto_tecnico
	and t1.sucursal_prod = pc2.sucursal_contable
left join (select * from liberty.amocom.homologa_profit_center where opcion = 3) pc3
	on t1.ramo_contable = pc3.ramo_contable
	and t1.ramo_prod = pc3.ramo_producto_tecnico
	and t1.modalidad = pc3.modalidad
left join (select * from liberty.amocom.homologa_profit_center where opcion = 4) pc4
	on t1.ramo_contable = pc4.ramo_contable
	and t1.sucursal_prod = pc4.sucursal_contable
	and t1.modalidad = pc4.modalidad
left join (select * from liberty.amocom.homologa_profit_center where opcion = 5) pc5
	on t1.ramo_contable = pc5.ramo_contable
	and t1.modalidad = pc5.modalidad
left join (select * from liberty.amocom.homologa_profit_center where opcion = 6) pc6
	on t1.ramo_contable = pc6.ramo_contable
	and t1.sucursal_prod = pc6.sucursal_contable
left join (select * from liberty.amocom.homologa_profit_center where opcion = 7) pc7
	on t1.ramo_contable = pc7.ramo_contable
	and t1.ramo_prod = pc7.ramo_producto_tecnico
left join (select * from liberty.amocom.homologa_profit_center where opcion = 8) pc8
	on t1.ramo_contable = pc8.ramo_contable
cross join (select * from liberty.amocom.homologa_profit_center where opcion = 9) pc9


-- ==== [Gross_Writte__43] sql/Gross_Writte__43/DDL/DB_SQL_Executor__216.sql ====
-- Nodo KNIME : P&G_COCO\Gross Writte (#43)\DB SQL Executor (#216)
-- Clave      : statement
-- Que hace: calcula parte de prima emitida bruta (el valor total de las polizas emitidas, antes de repartir por reaseguro).
-- Arma la tabla temporal #corretaje, #cocorretaje_sucursal, #sucursal, #cocorretaje_sn a partir de liberty..

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
,a.SSEGURO	
,a.SUCURSAL_PROD
,a.RAMO_PROD
,a.RAMO_TECNICO
,a.RAMO_CONTABLE
,a.POLIZA	
,a.CERTIFICADO	
,a.DOCUMENTO	
,a.ANEXO	
,a.SBU
,a.FI_CERTIFICADO	
,a.FF_CERTIFICADO	
,a.FI_DOCUMENTO	
,a.FF_DOCUMENTO	
,a.FECHA_EXPE	
,a.INTERMEDIARIO_LIDE
,a.vr_p_sucursal
,a.vr_p_p_sucursal	
,a.FI_ANEXO	
,a.FF_ANEXO
,a.cod_modalidad
,a.GROSS_WRITTEN_PREMIUM	
,a.Profit_nuevo as cod_profitcenter
,a.Descripcion_profit as desc_profitcenter
,SUBSTRING(LOB_SAP, 1, charindex('-', LOB_SAP)-1) as cod_sbu_sap 
,SUBSTRING(LOB_SAP, charindex('-', LOB_SAP)+1, len(LOB_SAP))  as desc_sbu_sap
,a.Concepto_nivel_3
,a.Concepto_nivel_2
,a.Concepto_nivel_1
,a.Concepto_nivel_0
--,b.LLAVE_CERT 
,CASE WHEN B.LLAVE_CERT IS NULL THEN 0 ELSE 1 END as Marca_corretaje
into #cocorretaje_sucursal
from #profit a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje) B ON (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT)


if OBJECT_ID('tempdb.dbo.#sucursal','U') is not null drop table #sucursal


select 
--distinct
row_number() over( order by 
					a.RAMO_PROD
					,a.POLIZA	
					,a.CERTIFICADO	
					,a.DOCUMENTO
					,a.ANEXO
					,a.SUCURSAL_PROD
					,a.INTERMEDIARIO_LIDE
					,a.vr_p_sucursal
					,a.vr_p_p_sucursal	
					,a.GROSS_WRITTEN_PREMIUM
					,a.RAMO_TECNICO
					,a.RAMO_CONTABLE
					,a.FI_DOCUMENTO	
					,a.FF_DOCUMENTO) as id
,a.SSEGURO	
,a.RAMO_PROD
,a.POLIZA	
,a.CERTIFICADO	
,a.DOCUMENTO
,a.ANEXO
,a.SUCURSAL_PROD
,a.INTERMEDIARIO_LIDE
,a.vr_p_sucursal
,a.vr_p_p_sucursal	
,a.GROSS_WRITTEN_PREMIUM
,a.RAMO_TECNICO
,a.RAMO_CONTABLE
,a.FI_DOCUMENTO	
,a.FF_DOCUMENTO	
into  #sucursal
from #cocorretaje_sucursal a
where Marca_corretaje = 0

-------------------------------------------------




if OBJECT_ID('tempdb.dbo.#cocorretaje_sn','U') is not null drop table #cocorretaje_sn

select 
a.PERIODO_CONTABLE
,a.SSEGURO	
--,a.SUCURSAL_PROD
,a.RAMO_PROD
,a.RAMO_TECNICO
,a.RAMO_CONTABLE
,a.POLIZA	
,a.CERTIFICADO	
,a.DOCUMENTO	
,a.ANEXO	
,a.SBU
,a.FI_CERTIFICADO	
,a.FF_CERTIFICADO	
,a.FI_DOCUMENTO	
,a.FF_DOCUMENTO	
,a.FECHA_EXPE	
,a.INTERMEDIARIO_LIDE
,a.vr_p_sucursal
,a.vr_p_p_sucursal	
,a.FI_ANEXO	
,a.FF_ANEXO
,a.cod_modalidad
,a.GROSS_WRITTEN_PREMIUM	
,a.Profit_nuevo as cod_profitcenter
,a.Descripcion_profit as desc_profitcenter
,SUBSTRING(LOB_SAP, 1, charindex('-', LOB_SAP)-1) as cod_sbu_sap 
,SUBSTRING(LOB_SAP, charindex('-', LOB_SAP)+1, len(LOB_SAP))  as desc_sbu_sap
,a.Concepto_nivel_3
,a.Concepto_nivel_2
,a.Concepto_nivel_1
,a.Concepto_nivel_0
--,b.LLAVE_CERT 
,CASE WHEN B.LLAVE_CERT IS NULL THEN 0 ELSE 1 END as Marca_corretaje
into #cocorretaje_sn
from #profit a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje) B ON (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT)

------AND A.documento>=B.documento and A.documento<B.doc_2)


-- ==== [Gross_Writte__43] sql/Gross_Writte__43/DDL/DB_SQL_Executor__218.sql ====
-- Nodo KNIME : P&G_COCO\Gross Writte (#43)\DB SQL Executor (#218)
-- Clave      : statement
-- Que hace: calcula parte de prima emitida bruta (el valor total de las polizas emitidas, antes de repartir por reaseguro).
-- Arma la tabla temporal #si_coco a partir de otras tablas ya calculadas antes en este mismo componente.

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


-- ==== [Gross_Writte__43] sql/Gross_Writte__43/DDL/DB_SQL_Executor__219.sql ====
-- Nodo KNIME : P&G_COCO\Gross Writte (#43)\DB SQL Executor (#219)
-- Clave      : statement
-- Que hace: calcula parte de prima emitida bruta (el valor total de las polizas emitidas, antes de repartir por reaseguro).
-- Arma la tabla temporal #no_coco a partir de otras tablas ya calculadas antes en este mismo componente.

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
a.PERIODO_CONTABLE
,a.SSEGURO	
--,a.SUCURSAL_PROD
,a.RAMO_PROD
,a.RAMO_TECNICO
,a.RAMO_CONTABLE
,a.POLIZA	
,a.CERTIFICADO	
,a.DOCUMENTO	
,a.ANEXO	
,a.SBU
,a.FI_CERTIFICADO	
,a.FF_CERTIFICADO	
,a.FI_DOCUMENTO	
,a.FF_DOCUMENTO	
,a.FECHA_EXPE	
,a.INTERMEDIARIO_LIDE
,a.vr_p_sucursal
,a.vr_p_p_sucursal	
,a.FI_ANEXO	
,a.FF_ANEXO
,a.cod_modalidad
,a.GROSS_WRITTEN_PREMIUM	
,a.cod_profitcenter
,a.desc_profitcenter
,a.cod_sbu_sap
,a.desc_sbu_sap
,a.Concepto_nivel_3
,a.Concepto_nivel_2
,a.Concepto_nivel_1
,a.Concepto_nivel_0
,a.Marca_corretaje
,INTERMEDIARIO_LIDE AS COD_INTERMEDIARIO,
VR_P_P_SUCURSAL AS PARTICIPACION,
DOCUMENTO AS DOC,
GROSS_WRITTEN_PREMIUM as GROSS_WRITTEN_PREMIUM_CO,
a.SUCURSAL_PROD AS COD_SUCURSAL
into #no_coco
from #cocorretaje_sucursal a
where marca_corretaje =0


-- ==== [Gross_Writte__43] sql/Gross_Writte__43/DDL/DB_SQL_Executor__222.sql ====
-- Nodo KNIME : P&G_COCO\Gross Writte (#43)\DB SQL Executor (#222)
-- Clave      : statement
-- Que hace: calcula parte de prima emitida bruta (el valor total de las polizas emitidas, antes de repartir por reaseguro).
-- Arma la tabla temporal #caso1 a partir de otras tablas ya calculadas antes en este mismo componente.

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
--b.DOC_2,
--b.COD_SUCURSAL,
--CASE WHEN b.COD_SUCURSAL IS NULL THEN A.SUCURSAL_PROD ELSE B.COD_SUCURSAL END AS COD_SUCURSAL,
CASE WHEN b.PARTICIPACION IS NULL THEN a.GROSS_WRITTEN_PREMIUM 
	 ELSE a.GROSS_WRITTEN_PREMIUM * (b.PARTICIPACION/100) 
END as GROSS_WRITTEN_PREMIUM_CO,
b.COD_SUCURSAL
into #caso1
from  #si_coco a
left join #corretaje b 
on (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT AND A.documento>=B.documento and A.documento<B.doc_2)
where
b.PARTICIPACION is not null and (vr_p_p_sucursal = 0 or (vr_p_p_sucursal = 100 and vr_p_sucursal= 100))


-- ==== [Gross_Writte__43] sql/Gross_Writte__43/DDL/DB_SQL_Executor__224.sql ====
-- Nodo KNIME : P&G_COCO\Gross Writte (#43)\DB SQL Executor (#224)
-- Clave      : statement
-- Que hace: calcula parte de prima emitida bruta (el valor total de las polizas emitidas, antes de repartir por reaseguro).
-- Arma la tabla temporal #caso2_1, #caso2_2, #caso2_u a partir de otras tablas ya calculadas antes en este mismo componente.

USE Liberty_pruebas_actuaria

/*****************
CASO 1 DE COCORRETAJE interemdiario misma sucursal 
******************/

if OBJECT_ID('tempdb.dbo.#caso2_1','U') is not null drop table #caso2_1


select distinct 
a.*,
b.COD_INTERMEDIARIO,
b.PARTICIPACION,
b.DOCUMENTO AS DOC,
case when a.vr_p_sucursal = 100 and a.vr_p_p_sucursal in (100,50)  then a.GROSS_WRITTEN_PREMIUM * (b.PARTICIPACION/100)
else GROSS_WRITTEN_PREMIUM  end as GROSS_WRITTEN_PREMIUM_CO,
B.COD_SUCURSAL
--,null as agente2,null as partici2
into #caso2_1
from  #si_coco a
left join #corretaje b 
on  (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT AND A.documento>=B.documento and A.documento<B.doc_2)  and a.vr_p_p_sucursal = b.participacion
where
b.PARTICIPACION is not null and
vr_p_p_sucursal <> 0
--AND vr_p_sucursal  <= 100



----- Este segundo cruce validarlo para los casos donde el cocorretaje es  entre varias sucursales
----- y varios intermediarios en una de esas sucursales

--drop table #caso2_2

if OBJECT_ID('tempdb.dbo.#caso2_2','U') is not null drop table #caso2_2

select  
a.PERIODO_CONTABLE
,a.SSEGURO
--,a.SUCURSAL_PROD
,a.RAMO_PROD
,a.RAMO_TECNICO
,a.RAMO_CONTABLE
,a.POLIZA
,a.CERTIFICADO
,a.DOCUMENTO
,a.ANEXO
,a.SBU
,a.FI_CERTIFICADO
,a.FF_CERTIFICADO
,a.FI_DOCUMENTO
,a.FF_DOCUMENTO
,a.FECHA_EXPE
,a.INTERMEDIARIO_LIDE
,a.vr_p_sucursal
,a.vr_p_p_sucursal
,a.FI_ANEXO
,a.FF_ANEXO
,a.cod_modalidad
,a.GROSS_WRITTEN_PREMIUM
,a.cod_profitcenter
,a.desc_profitcenter
,a.cod_sbu_sap
,a.desc_sbu_sap
,a.Concepto_nivel_3
,a.Concepto_nivel_2
,a.Concepto_nivel_1
,a.Concepto_nivel_0
,a.marca_corretaje
,b.COD_INTERMEDIARIO
,b.PARTICIPACION
,b.DOCUMENTO as DOC
,case when b.participacion IS NULL then a.GROSS_WRITTEN_PREMIUM * (b.PARTICIPACION/100) / (a.vr_p_p_sucursal/100) 
	  when a.vr_p_p_sucursal = 100 then a.GROSS_WRITTEN_PREMIUM * (b.PARTICIPACION/100)
 	  else
 	  a.GROSS_WRITTEN_PREMIUM
	   end as GROSS_WRITTEN_PREMIUM_CO
,b.COD_SUCURSAL
into #caso2_2
from #caso2_1 a
left join #corretaje b
on  (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT AND A.documento>=B.documento and A.documento<B.doc_2)
and NOT exists (select * from #caso2_1 aa where aa.ramo_prod=b.cod_ramo_prod and aa.poliza=b.nro_poliza and aa.certificado=b.nro_certificado and aa.participacion=b.participacion)
where a.participacion is null



--select 
--d.*,
--c.COD_INTERMEDIARIO,
--c.PARTICIPACION,
--c.DOCUMENTO AS DOC,
--c.COD_SUCURSAL,
--d.GROSS_WRITTEN_PREMIUM * (c.PARTICIPACION/100) as GROSS_WRITTEN_PREMIUM_CO
--into #caso2_2
--from
--(
--	select
--	a.*
--	--into #caso2_2
--	from  #si_coco a
--	left join #corretaje b 
--	on a.ramo_prod = b.cod_ramo_prod and a.poliza = b.nro_poliza and a.certificado = b.nro_certificado and  a.DOCUMENTO = b.documento  and a.vr_p_p_sucursal = b.participacion
--	where
--	b.PARTICIPACION is  null and
--	vr_p_p_sucursal <> 0
--) d
--left join #corretaje c 
--on d.ramo_prod = c.cod_ramo_prod and d.poliza = c.nro_poliza and d.certificado = c.nro_certificado and  d.DOCUMENTO = c.documento
--DROP TABLE #caso2_u

--select * 
--into #caso2_u
--from #caso2_1
--where PARTICIPACION is not null
--union
--select * from #caso2_2










---GROSS_WRITTEN_PREMIUM_CO


-- ==== [Gross_Writte__43] sql/Gross_Writte__43/DDL/DB_SQL_Executor__226.sql ====
-- Nodo KNIME : P&G_COCO\Gross Writte (#43)\DB SQL Executor (#226)
-- Clave      : statement
-- Que hace: calcula parte de prima emitida bruta (el valor total de las polizas emitidas, antes de repartir por reaseguro).
-- Arma la tabla temporal #cocorretaje_completo a partir de otras tablas ya calculadas antes en este mismo componente.

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
FROM #no_coco
UNION all
SELECT * FROM #caso1
--, 'caso1' as marca 
union all
SELECT * FROM #caso2_1
) a


-- ==== [Gross_Writte__43] sql/Gross_Writte__43/DML/DB_Query_Reader__6.sql ====
-- Nodo KNIME : P&G_COCO\Gross Writte (#43)\DB Query Reader (#6)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para prima emitida bruta (el valor total de las polizas emitidas, antes de repartir por reaseguro),
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

select * from #primas_pyg_inter


-- ==== [Gross_Writte__43] sql/Gross_Writte__43/DML/DB_Query_Reader__229.sql ====
-- Nodo KNIME : P&G_COCO\Gross Writte (#43)\DB Query Reader (#229)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para prima emitida bruta (el valor total de las polizas emitidas, antes de repartir por reaseguro),
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.
-- Nota: prima emitida: el valor total de la prima de una poliza en el momento en que se emite, sin importar si ya se devengo o no.

SELECT * 
FROM  #cocorretaje_completo
WHERE GROSS_WRITTEN_PREMIUM_CO <> 0


-- >>> Aqui KNIME ejecuta un nodo "DB Insert (#260)" que hace: INSERT INTO liberty_pruebas_actuaria.dbo.PL_COL_DATOS_COCO SELECT * FROM #primas_pyg_inter ;
-- >>> NOTA: este INSERT es una reconstruccion/inferencia; el nodo DB Insert de KNIME no tiene script SQL capturado en este repositorio.

-- ----------------------------------------------------------------------------
-- COMPONENTE 2/8: Written Prem (#33) -- Prima cedida al reaseguro
-- Calcula la prima cedida al reaseguro cruzando polizas con las cesiones de
-- reservas.CEDIDAS / CEDIDAS_IAXIS y homologando profit center. Se ejecuta
-- antes de CHANGE_IN_CA (#320) segun conexion de orden en docs/FLUJO.md.
-- Escribe en PL_COL_DATOS_COCO mediante el nodo DB Insert (#261).
-- ----------------------------------------------------------------------------
-- ==== [Written_Prem__33] sql/Written_Prem__33/DDL/DB_SQL_Executor__29.sql ====
-- Nodo KNIME : P&G_COCO\Written Prem (#33)\DB SQL Executor (#29)
-- Clave      : statement
-- Que hace: calcula parte de prima cedida al reaseguro (la parte de la prima que se traspasa a la reaseguradora).
-- Arma la tabla temporal #primas_ced_rea a partir de liberty.reservas.CEDIDAS_IAXIS, liberty.apoyo.dwh_sbu_ramo_prod, liberty..
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_pruebas_actuaria

declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$

if OBJECT_ID('tempdb.dbo.#primas_ced_rea','U') is not null drop table #primas_ced_rea


select 
ced.periodo_contable,
ced.sucursal as sucursal_prod,
sbu.SBU,
ced.ramo as ramo_prod,
ced.ramo_rea,
case when ced.ramo = '900753' and ced.ramo_contable not in (322,323,324) and  t3.modalidad = 1  then 345 
	  when ced.ramo = '900753' and ced.ramo_contable not in (322,323,324) and t3.modalidad  = 2  then 335 
	  when ced.ramo = '900753' and ced.ramo_contable not in (322,323,324) and t3.modalidad  = 3  then 346 
	  when ced.ramo = '900753' and ced.ramo_contable not in (322,323,324) and t3.modalidad  = 4  then 343
	  else ced.RAMO_CONTABLE end as RAMO_CONTABLE,
ced.poliza,
ced.certificado,
ced.documento,
t3.modalidad as cod_modalidad,
--SUM(ced.valor_cesion) AS VALOR_CESION,
sum(ced.valor_cedido) as VALOR_CEDIDO,
pro.cod_profitcenter,
pro.desc_profitcenter,
pro.cod_sbu_sap,
pro.desc_sbu_sap
,'INTERFAZ_AUT' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'WRITTEN PREMIUM-CEDED' AS Concepto_nivel_1
,'NET_WRITTEN_PREMIUM' AS Concepto_nivel_0
,'Iaxis' as Fuente
into #primas_ced_rea
from liberty.reservas.CEDIDAS_IAXIS ced
left join 
liberty.apoyo.dwh_sbu_ramo_prod sbu on ced.ramo = sbu.ramo_prod 
--left join
--liberty.prod.dwh_polizas_h t3 on ced.ramo = t3.ramo_prod and ced.poliza = t3.poliza and ced.certificado = t3.certificado and ced.documento = t3.documento
left join  liberty.[RESERVAS].[POLIZA_MODALIDAD] t3 on ced.ramo = t3.ramo_prod and ced.poliza = t3.poliza and ced.certificado = t3.certificado
left join
liberty.apoyo.dwh_profitcenter pro on pro.ramo_prod = ced.ramo and pro.sucursal = ced.sucursal and pro.ramo_contable = ced.ramo_contable
where ced.periodo_contable >= @periodo_contable 
group by
ced.periodo_contable,
ced.sucursal,
sbu.SBU,
ced.ramo,
ced.ramo_rea,
ced.ramo_contable,
ced.poliza,
ced.certificado,
ced.documento,
--p.intermediario_lide
pro.cod_profitcenter,
pro.desc_profitcenter,
pro.cod_sbu_sap,
pro.desc_sbu_sap,
t3.modalidad

union all 


select 
ced.peco as periodo_contable,
ced.suli as  sucursal_prod,
sbu.sbu,
ced.ramo as ramo_prod,
ced.reas as ramo_rea,
ced.raco as ramo_contable,
ced.poli as poliza,
ced.cert as certificado,
ced.anex as documento,
'' as cod_modalidad,
sum(vces) as VALOR_CEDIDO,
pro.cod_profitcenter,
pro.desc_profitcenter,
pro.cod_sbu_sap,
pro.desc_sbu_sap
,'INTERFAZ_AUT' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'WRITTEN PREMIUM-CEDED' AS Concepto_nivel_1
,'NET_WRITTEN_PREMIUM' AS Concepto_nivel_0
,'AS400' as Fuente
from liberty.reservas.cedidaS ced
left join 
liberty.apoyo.dwh_sbu_ramo_prod sbu on ced.ramo = sbu.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter pro on pro.ramo_prod = ced.ramo and pro.sucursal = ced.suli and pro.ramo_contable = ced.raco
where ced.PECO >= @periodo_contable 
group by 
ced.peco ,
ced.suli,
sbu.sbu,
ced.ramo,
ced.reas,
ced.raco,
ced.poli,
ced.cert,
ced.anex,
--p.intermediario_lide
pro.cod_profitcenter,
pro.desc_profitcenter,
pro.cod_sbu_sap,
pro.desc_sbu_sap


-- ==== [Written_Prem__33] sql/Written_Prem__33/DDL/DB_SQL_Executor__30.sql ====
-- Nodo KNIME : P&G_COCO\Written Prem (#33)\DB SQL Executor (#30)
-- Clave      : statement
-- Que hace: calcula parte de prima cedida al reaseguro (la parte de la prima que se traspasa a la reaseguradora).
-- Arma la tabla temporal #cedidas_pyg a partir de otras tablas ya calculadas antes en este mismo componente.

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#cedidas_pyg','U') is not null drop table #cedidas_pyg

select 
periodo_contable AS PERIODO_CONTABLE,
sucursal_prod AS SUCURSAL_PROD,
SBU,
INTERMEDIARIO_LIDE
,Profit_nuevo as cod_profitcenter
,Descripcion_profit as desc_profitcenter
,SUBSTRING(LOB_SAP, 1, charindex('-', LOB_SAP)-1) COD_SBU 
,SUBSTRING(LOB_SAP, charindex('-', LOB_SAP)+1, len(LOB_SAP)) DESC_SBU
,sum(VALOR_CEDIDO)  as VALOR_CONCEPTO
, Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
into #cedidas_pyg
from #cedidas
group by
periodo_contable,
sucursal_prod,
SBU,
Profit_nuevo,
Descripcion_profit,
cod_sbu_sap,
desc_sbu_sap,
Intermediario_lide
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,LOB_SAP


-- ==== [Written_Prem__33] sql/Written_Prem__33/DDL/DB_SQL_Executor__197.sql ====
-- Nodo KNIME : P&G_COCO\Written Prem (#33)\DB SQL Executor (#197)
-- Clave      : statement
-- Que hace: calcula parte de prima cedida al reaseguro (la parte de la prima que se traspasa a la reaseguradora).
-- Arma la tabla temporal #cedidas a partir de liberty.prod.dwh_polizas_h.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_pruebas_actuaria

declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#cedidas','U') is not null drop table #cedidas


if OBJECT_ID('dbo.intermediarios_unicos','U') is not null drop table intermediarios_unicos
SELECT * 
INTO intermediarios_unicos
from (
		SELECT ramo_prod,
		       poliza AS pol,
		       intermediario_lide,
		       ROW_NUMBER() OVER (PARTITION BY ramo_prod, poliza ORDER BY intermediario_lide) AS rn
		FROM liberty.prod.dwh_polizas_h
		WHERE PERIODO_CONTABLE >= 202001
) a 
where rn = 1

select ced.* ,p.intermediario_lide
into #cedidas
from #profit_ced ced
left join 
intermediarios_unicos p on ced.RAMO_prod = p.ramo_prod and ced.poliza = p.pol --and ced.certificado = p.certi-- and ced.DOCUMENTO = p.documento


-- ==== [Written_Prem__33] sql/Written_Prem__33/DDL/DB_SQL_Executor__216.sql ====
-- Nodo KNIME : P&G_COCO\Written Prem (#33)\DB SQL Executor (#216)
-- Clave      : statement
-- Que hace: calcula parte de prima cedida al reaseguro (la parte de la prima que se traspasa a la reaseguradora).
-- Arma la tabla temporal #corretaje, #cocorretaje_sn a partir de liberty..

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


-------------------------------------------------



/*********************
Marca Corretaje
*********************/

if OBJECT_ID('tempdb.dbo.#cocorretaje_sn','U') is not null drop table #cocorretaje_sn

select 
ced.periodo_contable
,ced.sucursal_prod
,ced.ramo_prod
,ced.ramo_rea
,ced.ramo_contable
,ced.poliza
,ced.certificado
,ced.documento
,ced.SBU
,ced.intermediario_lide
,ced.VALOR_CEDIDO
--,ced.cod_profitcenter
--,ced.desc_profitcenter
--,ced.cod_sbu_sap
--,ced.desc_sbu_sap
,ced.Profit_nuevo as cod_profitcenter
,ced.Descripcion_profit as desc_profitcenter
,SUBSTRING(LOB_SAP, 1, charindex('-', ced.LOB_SAP)-1) as  cod_sbu_sap 
,SUBSTRING(LOB_SAP, charindex('-', ced.LOB_SAP)+1, len(ced.LOB_SAP)) as desc_sbu_sap
,ced.Concepto_nivel_3
,ced.Concepto_nivel_2
,ced.Concepto_nivel_1
,ced.Concepto_nivel_0
,ced.Fuente
--,b.LLAVE_CERT 
,CASE WHEN B.LLAVE_CERT IS NULL THEN 0 ELSE 1 END as Marca_corretaje
into #cocorretaje_sn
from #cedidas ced
LEFT JOIN (select distinct LLAVE_CERT from #corretaje) B ON (concat(ltrim(rtrim(ced.RAMO_prod)),'_',ltrim(rtrim(ced.poliza)),'_',ced.certificado)=B.LLAVE_CERT)

------AND A.documento>=B.documento and A.documento<B.doc_2)


-- ==== [Written_Prem__33] sql/Written_Prem__33/DDL/DB_SQL_Executor__218.sql ====
-- Nodo KNIME : P&G_COCO\Written Prem (#33)\DB SQL Executor (#218)
-- Clave      : statement
-- Que hace: calcula parte de prima cedida al reaseguro (la parte de la prima que se traspasa a la reaseguradora).
-- Arma la tabla temporal #si_coco a partir de otras tablas ya calculadas antes en este mismo componente.

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


-- ==== [Written_Prem__33] sql/Written_Prem__33/DDL/DB_SQL_Executor__219.sql ====
-- Nodo KNIME : P&G_COCO\Written Prem (#33)\DB SQL Executor (#219)
-- Clave      : statement
-- Que hace: calcula parte de prima cedida al reaseguro (la parte de la prima que se traspasa a la reaseguradora).
-- Arma la tabla temporal #no_coco a partir de otras tablas ya calculadas antes en este mismo componente.

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
,row_number() over(order by ramo_prod) as id
,INTERMEDIARIO_LIDE AS COD_INTERMEDIARIO
,0 AS PARTICIPACION
,DOCUMENTO AS DOC
,VALOR_CEDIDO as VALOR_CEDIDO_CO
,SUCURSAL_prod AS COD_SUCURSAL
into #no_coco
from #cocorretaje_sn c
where marca_corretaje =0


-- ==== [Written_Prem__33] sql/Written_Prem__33/DDL/DB_SQL_Executor__224.sql ====
-- Nodo KNIME : P&G_COCO\Written Prem (#33)\DB SQL Executor (#224)
-- Clave      : statement
-- Que hace: calcula parte de prima cedida al reaseguro (la parte de la prima que se traspasa a la reaseguradora).
-- Arma la tabla temporal #caso1 a partir de otras tablas ya calculadas antes en este mismo componente.

USE Liberty_pruebas_actuaria

/*****************
CASO 1 DE COCORRETAJE interemdiario misma sucursal 
******************/

if OBJECT_ID('tempdb.dbo.#caso1','U') is not null drop table #caso1

select
a.*,
row_number() over(order by ramo_prod) as id,
CASE WHEN b.COD_INTERMEDIARIO IS NULL THEN A.INTERMEDIARIO_LIDE ELSE b.COD_INTERMEDIARIO END AS COD_INTERMEDIARIO,
CASE WHEN b.PARTICIPACION IS NULL THEN 0 ELSE b.PARTICIPACION END  AS PARTICIPACION,
CASE WHEN b.DOCUMENTO IS NULL THEN A.DOCUMENTO ELSE b.DOCUMENTO END AS DOC,
CASE WHEN b.PARTICIPACION IS NULL THEN a.VALOR_CEDIDO
	 ELSE a.VALOR_CEDIDO  * (b.PARTICIPACION/100) 
END as VALOR_CEDIDO_CO,
b.COD_SUCURSAL
into #caso1
from  #si_coco a
left join #corretaje b 
on (concat(ltrim(rtrim(A.RAMO_prod)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT AND A.documento>=B.documento and A.documento<B.doc_2)
--where
--b.PARTICIPACION is not null


-- ==== [Written_Prem__33] sql/Written_Prem__33/DDL/DB_SQL_Executor__233.sql ====
-- Nodo KNIME : P&G_COCO\Written Prem (#33)\DB SQL Executor (#233)
-- Clave      : statement
-- Que hace: calcula parte de prima cedida al reaseguro (la parte de la prima que se traspasa a la reaseguradora).
-- Arma la tabla temporal #cocorretaje_completo a partir de otras tablas ya calculadas antes en este mismo componente.

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
FROM #no_coco
UNION all
SELECT * FROM #caso1
) a


-- ==== [Written_Prem__33] sql/Written_Prem__33/DDL/DB_SQL_Executor__264.sql ====
-- Nodo KNIME : P&G_COCO\Written Prem (#33)\DB SQL Executor (#264)
-- Clave      : statement
-- Que hace: calcula parte de prima cedida al reaseguro (la parte de la prima que se traspasa a la reaseguradora).
-- Arma la tabla temporal #profit_ced a partir de liberty.amocom.homologa_profit_center.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('#profit_ced','U') is not null drop table #profit_ced



select  
t1.*
,coalesce(/*pc1.mapped_sapprofitcenter,*/ pc2.mapped_sapprofitcenter, pc3.mapped_sapprofitcenter, pc4.mapped_sapprofitcenter, pc5.mapped_sapprofitcenter, pc6.mapped_sapprofitcenter, pc7.mapped_sapprofitcenter, pc8.mapped_sapprofitcenter, pc9.mapped_sapprofitcenter) Profit_nuevo
,coalesce(/*pc1.[description],*/ pc2.[description], pc3.[description], pc4.[description], pc5.[description], pc6.[description], pc7.[description], pc8.[description], pc9.[description]) Descripcion_profit
,coalesce(/*pc1.[description],*/ pc2.lob_g1, pc3.lob_g1, pc4.lob_g1, pc5.lob_g1, pc6.lob_g1, pc7.lob_g1, pc8.lob_g1, pc9.lob_g1) LOB_SAP
into #profit_ced
from  #primas_ced_rea t1
left join (select * from liberty.amocom.homologa_profit_center where opcion = 1) pc1
	on t1.ramo_contable = pc1.ramo_contable
	and t1.ramo_prod = pc1.ramo_producto_tecnico
	and t1.sucursal_prod = pc1.sucursal_contable
	and t1.cod_modalidad = pc1.modalidad
left join (select * from liberty.amocom.homologa_profit_center where opcion = 2) pc2
	on t1.ramo_contable = pc2.ramo_contable
	and t1.ramo_prod = pc2.ramo_producto_tecnico
	and t1.sucursal_prod = pc2.sucursal_contable
left join (select * from liberty.amocom.homologa_profit_center where opcion = 3) pc3
	on t1.ramo_contable = pc3.ramo_contable
	and t1.ramo_prod = pc3.ramo_producto_tecnico
	and t1.cod_modalidad = pc3.modalidad
left join (select * from liberty.amocom.homologa_profit_center where opcion = 4) pc4
	on t1.ramo_contable = pc4.ramo_contable
	and t1.sucursal_prod = pc4.sucursal_contable
	and t1.cod_modalidad = pc4.modalidad
left join (select * from liberty.amocom.homologa_profit_center where opcion = 5) pc5
	on t1.ramo_contable = pc5.ramo_contable
	and t1.cod_modalidad = pc5.modalidad
left join (select * from liberty.amocom.homologa_profit_center where opcion = 6) pc6
	on t1.ramo_contable = pc6.ramo_contable
	and t1.sucursal_prod = pc6.sucursal_contable
left join (select * from liberty.amocom.homologa_profit_center where opcion = 7) pc7
	on t1.ramo_contable = pc7.ramo_contable
	and t1.ramo_prod = pc7.ramo_producto_tecnico
left join (select * from liberty.amocom.homologa_profit_center where opcion = 8) pc8
	on t1.ramo_contable = pc8.ramo_contable
cross join (select * from liberty.amocom.homologa_profit_center where opcion = 9) pc9


-- ==== [Written_Prem__33] sql/Written_Prem__33/DML/DB_Query_Reader__4.sql ====
-- Nodo KNIME : P&G_COCO\Written Prem (#33)\DB Query Reader (#4)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para prima cedida al reaseguro (la parte de la prima que se traspasa a la reaseguradora),
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

/*select * from #primas_pyg */

select
--* 
--COUNT(*) 
periodo_contable,sum(VALOR_CEDIDO)
from #primas_ced_rea
--#cedidas
group by periodo_contable


-- ==== [Written_Prem__33] sql/Written_Prem__33/DML/DB_Query_Reader__31.sql ====
-- Nodo KNIME : P&G_COCO\Written Prem (#33)\DB Query Reader (#31)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para prima cedida al reaseguro (la parte de la prima que se traspasa a la reaseguradora),
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

select * from #cedidas_pyg


-- ==== [Written_Prem__33] sql/Written_Prem__33/DML/DB_Query_Reader__220.sql ====
-- Nodo KNIME : P&G_COCO\Written Prem (#33)\DB Query Reader (#220)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para prima cedida al reaseguro (la parte de la prima que se traspasa a la reaseguradora),
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

/*select * from #primas_pyg */

select
--* 
--COUNT(*) 
sum(VALOR_CEDIDO)
from #cocorretaje_sn


-- ==== [Written_Prem__33] sql/Written_Prem__33/DML/DB_Query_Reader__222.sql ====
-- Nodo KNIME : P&G_COCO\Written Prem (#33)\DB Query Reader (#222)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para prima cedida al reaseguro (la parte de la prima que se traspasa a la reaseguradora),
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

/*select * from #primas_pyg */

select
top 10 * 
--COUNT(*) 
--sum(VALOR_CEDIDO),
--sum(VALOR_CEDIDO_CO)
from #no_coco


-- ==== [Written_Prem__33] sql/Written_Prem__33/DML/DB_Query_Reader__223.sql ====
-- Nodo KNIME : P&G_COCO\Written Prem (#33)\DB Query Reader (#223)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para prima cedida al reaseguro (la parte de la prima que se traspasa a la reaseguradora),
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

/*select * from #primas_pyg */

select
--* 
--COUNT(*) 
sum(VALOR_CEDIDO)
from #si_coco


-- ==== [Written_Prem__33] sql/Written_Prem__33/DML/DB_Query_Reader__225.sql ====
-- Nodo KNIME : P&G_COCO\Written Prem (#33)\DB Query Reader (#225)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para prima cedida al reaseguro (la parte de la prima que se traspasa a la reaseguradora),
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

/*select * from #primas_pyg */

select
--* 
COUNT(*) 
--sum(VALOR_CEDIDO),
--sum(VALOR_CEDIDO_CO)
from #caso1


-- ==== [Written_Prem__33] sql/Written_Prem__33/DML/DB_Query_Reader__234.sql ====
-- Nodo KNIME : P&G_COCO\Written Prem (#33)\DB Query Reader (#234)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para prima cedida al reaseguro (la parte de la prima que se traspasa a la reaseguradora),
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.
-- Nota: prima cedida: la parte de la prima que la aseguradora le traspasa a un reasegurador porque comparte el riesgo con el.
-- Nota: cedidas: operaciones (primas, siniestros, comisiones) que se traspasaron al reasegurador.

/*select * from #primas_pyg */

select
* 
--COUNT(*) 
--sum(VALOR_CEDIDO),
--sum(VALOR_CEDIDO_CO)
from #cocorretaje_completo


-- >>> Aqui KNIME ejecuta un nodo "DB Insert (#261)" que hace: INSERT INTO liberty_pruebas_actuaria.dbo.PL_COL_DATOS_COCO SELECT * FROM #cedidas_pyg ;
-- >>> NOTA: este INSERT es una reconstruccion/inferencia; el nodo DB Insert de KNIME no tiene script SQL capturado en este repositorio.

-- ----------------------------------------------------------------------------
-- COMPONENTE 3/8: COMMISSIONS (#216) -- Comisiones
-- Calcula el gasto de comisiones (COMMISSION EXPENSE) y la comision de
-- reaseguro (REINSURANCE_COMMISSION), a partir de comercial.DWH_OC_REMUNERACION_TECNICO_H
-- y middleware.DWH_REASEGURO_H. Incluye los subcomponentes OTRAS_COMISI (#276)
-- y PROFIT (#275). Escribe en PL_COL_DATOS_COCO mediante el nodo DB Insert (#218).
-- ----------------------------------------------------------------------------
-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__75.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#75)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #retorno a partir de liberty., liberty.apoyo.dwh_sbu_ramo_prod, liberty.prod.dwh_polizas_h.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('#retorno','U') is not null drop table #retorno

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__76.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#76)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #directa a partir de liberty., liberty.apoyo.dwh_sbu_ramo_prod, liberty.prod.dwh_polizas_h.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__77.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#77)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #reaseguro a partir de liberty., liberty.apoyo.dwh_sbu_ramo_prod, liberty.apoyo.dwh_profitcenter.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__195.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#195)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #retornos_1 a partir de otras tablas ya calculadas antes en este mismo componente.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__197.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#197)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #directa_1 a partir de otras tablas ya calculadas antes en este mismo componente.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__214.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#214)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #sobre a partir de liberty., liberty.comercial.DWH_OC_REMUNERACION_TECNICO_H, liberty.apoyo.dwh_profitcenter.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__215.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#215)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #sobre_1 a partir de otras tablas ya calculadas antes en este mismo componente.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__228.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#228)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #retorno_22 a partir de otras tablas ya calculadas antes en este mismo componente.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__231.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#231)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #retorno_2 a partir de liberty., liberty.apoyo.dwh_sbu_ramo_prod, liberty.apoyo.dwh_profitcenter.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__280.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#280)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #reaseguro_impuestos a partir de liberty.middleware.dwh_reaseguro_h, liberty.apoyo.dwh_sbu_ramo_prod, liberty.apoyo.dwh_profitcenter.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#reaseguro_impuestos','U') is not null drop table #reaseguro_impuestos

select 
a.periodo as periodo_contable,
a.PROGRAMA_INTERFACE,
a.DESCRIPCION_CUENTA_SUB,
a.ramo_contable,
a.sucursal_prod,
a.Libro,
b.sbu,
a.codigo_ramo_producto,
a.agente_lider as intermediario_lide
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,case when a.naturaleza_contable = 'H'  THEN a.VALOR_RUBRO * -1 ELSE a.VALOR_RUBRO END AS valor_rubro
,'Comisiones_reaseguro_impuestos' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'COMMISSION EXPENSE' AS Concepto_nivel_1
,'COMMISSION EXPENSE' AS Concepto_nivel_0
into #reaseguro_impuestos
from liberty.middleware.dwh_reaseguro_h a
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.codigo_ramo_producto = b.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.codigo_ramo_producto and t4.sucursal = a.sucursal_prod and t4.ramo_contable = a.ramo_contable
where periodo = @periodo_contable and cuenta_local = 411631 and SUBCUENTA_LOCAL in (101,102) and PROGRAMA_INTERFACE = 'PLINTREA'


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__281.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#281)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #reaseguro_impuestos_1 a partir de otras tablas ya calculadas antes en este mismo componente.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#reaseguro_impuestos_1','U') is not null drop table #reaseguro_impuestos_1



select
PERIODO_CONTABLE
,SBU
,SUCURSAL_PROD
,INTERMEDIARIO_LIDE
,sum(cast(VALOR_RUBRO as bigint)) as VALOR_CONCEPTO
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
into #reaseguro_impuestos_1
from #reaseguro_impuestos
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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__286.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#286)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #si_coco a partir de otras tablas ya calculadas antes en este mismo componente.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__287.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#287)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #no_coco a partir de otras tablas ya calculadas antes en este mismo componente.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__288.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#288)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #corretaje, #cocorretaje_sucursal, #sucursal, #cocorretaje_sn a partir de liberty..

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
into #cocorretaje_sn
from #retorno_22 a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje) B ON (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT)

------AND A.documento>=B.documento and A.documento<B.doc_2)


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__289.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#289)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #no_coco_completo a partir de otras tablas ya calculadas antes en este mismo componente.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__290.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#290)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #cocorretaje_completo a partir de otras tablas ya calculadas antes en este mismo componente.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__291.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#291)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #caso1 a partir de otras tablas ya calculadas antes en este mismo componente.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__313.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#313)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #retornos_docu a partir de liberty.prod.dwh_polizas_h.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

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
into #retornos_docu
from #retornos_1 a
left join #recibo b on a.ramo_prod = b.ramo_prod and a.poliza = b.poliza and a.certificado = b.certificado and a.recibo = b.recibo
--left join  liberty.prod.dwh_polizas_h b on a.ramo_prod = b.ramo_prod and a.poliza = b.poliza and a.certificado = b.certificado and a.recibo = b.recibo
left join  #pol c on a.ramo_prod = c.ramo_prod and a.poliza = c.poliza and a.certificado = c.certificado


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__317.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#317)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #caso1_i a partir de otras tablas ya calculadas antes en este mismo componente.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__318.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#318)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #cocorretaje_completo_i a partir de otras tablas ya calculadas antes en este mismo componente.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__319.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#319)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #no_coco_completo_i a partir de otras tablas ya calculadas antes en este mismo componente.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__320.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#320)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #corretaje, #cocorretaje_sucursal_i, #sucursal_i, #cocorretaje_sn_i a partir de liberty..

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
into #cocorretaje_sn_i
from #retornos_docu a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje) B ON (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT)

------AND A.documento>=B.documento and A.documento<B.doc_2)


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__321.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#321)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #no_coco, #no_coco_r2 a partir de otras tablas ya calculadas antes en este mismo componente.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__322.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#322)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #si_coco_r2, #si_coco a partir de otras tablas ya calculadas antes en este mismo componente.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__326.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#326)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #no_coco_completo_d a partir de otras tablas ya calculadas antes en este mismo componente.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__327.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#327)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #cocorretaje_completo_d a partir de otras tablas ya calculadas antes en este mismo componente.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__328.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#328)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #caso1_d a partir de otras tablas ya calculadas antes en este mismo componente.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__329.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#329)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #si_coco_d, #si_coco a partir de otras tablas ya calculadas antes en este mismo componente.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__330.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#330)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #no_coco, #no_coco_d a partir de otras tablas ya calculadas antes en este mismo componente.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__331.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#331)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #corretaje, #cocorretaje_sucursal_d, #sucursal_d, #cocorretaje_sn_d a partir de liberty..

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
into #cocorretaje_sn_d
from #directa_docu a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje) B ON (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT)

------AND A.documento>=B.documento and A.documento<B.doc_2)


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__366.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#366)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #pol, #recibo a partir de liberty.prod.dwh_polizas_h.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__367.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#367)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #pol, #recibo2 a partir de liberty.prod.dwh_polizas_h.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__368.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#368)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #directa_docu a partir de otras tablas ya calculadas antes en este mismo componente.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

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
into #directa_docu
from #directa_1 a
left join  #recibo2 b on a.ramo_prod = b.ramo_prod and a.poliza = b.poliza and a.certificado = b.certificado and a.recibo = b.recibo
left join  #pol c on a.ramo_prod = c.ramo_prod and a.poliza = c.poliza and a.certificado = c.certificado


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__371.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#371)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #reaseguro_1 a partir de otras tablas ya calculadas antes en este mismo componente.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__373.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#373)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #retorno_p a partir de liberty_pruebas_actuaria.dbo.PnL_Homologa_profit.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__374.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#374)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #directa_p a partir de liberty_pruebas_actuaria.dbo.PnL_Homologa_profit.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__397.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#397)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #reaseguro_p a partir de liberty_pruebas_actuaria.dbo.PnL_Homologa_profit.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DDL/DB_SQL_Executor__398.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#398)
-- Clave      : statement
-- Que hace: calcula parte de las comisiones que se pagan a los intermediarios y la comision de reaseguro.
-- Arma la tabla temporal #retorno_p a partir de liberty_pruebas_actuaria.dbo.PnL_Homologa_profit.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DML/DB_Query_Reader__207.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB Query Reader (#207)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para las comisiones que se pagan a los intermediarios y la comision de reaseguro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

SELECT
*
FROM #REASEGURO_1


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DML/DB_Query_Reader__216.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB Query Reader (#216)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para las comisiones que se pagan a los intermediarios y la comision de reaseguro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

SELECT * FROM #SOBRE_1


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DML/DB_Query_Reader__282.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB Query Reader (#282)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para las comisiones que se pagan a los intermediarios y la comision de reaseguro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

SELECT * FROM #REASEGURO_impuestos_1


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DML/DB_Query_Reader__311.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB Query Reader (#311)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para las comisiones que se pagan a los intermediarios y la comision de reaseguro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DML/DB_Query_Reader__324.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB Query Reader (#324)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para las comisiones que se pagan a los intermediarios y la comision de reaseguro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DML/DB_Query_Reader__325.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB Query Reader (#325)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para las comisiones que se pagan a los intermediarios y la comision de reaseguro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

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


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DML/DB_Query_Reader__361.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB Query Reader (#361)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para las comisiones que se pagan a los intermediarios y la comision de reaseguro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.



select
PERIODO_CONTABLE,
sum(VALOR_CONCEPTO)
from #no_coco_completo_d 
--where sucursal_prod is null
group by periodo_contable


---select
--*
--from  #retornos_docu


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DML/DB_Query_Reader__369.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB Query Reader (#369)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para las comisiones que se pagan a los intermediarios y la comision de reaseguro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.



select  
PERIODO_CONTABLE,
concepto_nivel_2,
sum(VALOR_CONCEPTO)
from #directa_docu
--where poliza = 515244 and certificado = 213
group by periodo_contable,concepto_nivel_2


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DML/DB_Query_Reader__375.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB Query Reader (#375)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para las comisiones que se pagan a los intermediarios y la comision de reaseguro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.



select
PERIODO_CONTABLE,
concepto_nivel_2,
sum(VALOR_COMISION)
from #directa_p
--where poliza = 515244 and certificado = 213
group by periodo_contable,concepto_nivel_2


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DML/DB_Query_Reader__378.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB Query Reader (#378)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para las comisiones que se pagan a los intermediarios y la comision de reaseguro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.



select 
PERIODO_CONTABLE,
concepto_nivel_2,
sum(VALOR_COMISION) as valor
from #directa
--where poliza = 515244 and certificado = 213
group by periodo_contable
,concepto_nivel_2


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DML/DB_Query_Reader__379.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB Query Reader (#379)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para las comisiones que se pagan a los intermediarios y la comision de reaseguro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.



select
PERIODO_CONTABLE,
sum(VALOR_COncepto)
,concepto_nivel_2
from #directa_1
--where poliza = 515244 and certificado = 213
group by periodo_contable,concepto_nivel_2


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DML/DB_Query_Reader__380.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB Query Reader (#380)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para las comisiones que se pagan a los intermediarios y la comision de reaseguro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.



select 
PERIODO_CONTABLE,
CONCEPTO_NIVEL_1,
CONCEPTO_NIVEL_2,
CONCEPTO_NIVEL_3,
sum(VALOR_RETORNO) as valor
from #retorno
--where poliza = 515244 and certificado = 213
group by periodo_contable,
CONCEPTO_NIVEL_1,
CONCEPTO_NIVEL_2,
CONCEPTO_NIVEL_3


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DML/DB_Query_Reader__381.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB Query Reader (#381)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para las comisiones que se pagan a los intermediarios y la comision de reaseguro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.



select 
PERIODO_CONTABLE,
CONCEPTO_NIVEL_1,
CONCEPTO_NIVEL_2,
CONCEPTO_NIVEL_3,
sum(VALOR_CONCEPTO) as valor
from #retornos_docu
--where poliza = 515244 and certificado = 213
group by periodo_contable,
CONCEPTO_NIVEL_1,
CONCEPTO_NIVEL_2,
CONCEPTO_NIVEL_3


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DML/DB_Query_Reader__382.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB Query Reader (#382)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para las comisiones que se pagan a los intermediarios y la comision de reaseguro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.



select 
PERIODO_CONTABLE,
CONCEPTO_NIVEL_1,
CONCEPTO_NIVEL_2,
CONCEPTO_NIVEL_3,
sum(VALOR_CONCEPTO) as valor
from #retornos_1
--where poliza = 515244 and certificado = 213
group by periodo_contable,
CONCEPTO_NIVEL_1,
CONCEPTO_NIVEL_2,
CONCEPTO_NIVEL_3


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DML/DB_Query_Reader__383.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB Query Reader (#383)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para las comisiones que se pagan a los intermediarios y la comision de reaseguro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.




select *
--concepto_nivel_2,
--sum(valor_concepto_co)
from #caso1_d
--where poliza = 515244 and certificado = 213
--group by concepto_nivel_2


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DML/DB_Query_Reader__384.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB Query Reader (#384)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para las comisiones que se pagan a los intermediarios y la comision de reaseguro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.



select *
--concepto_nivel_2,
--sum(valor_concepto)
from #si_coco_d
--where poliza = 515244 and certificado = 213
--group by concepto_nivel_2


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DML/DB_Query_Reader__385.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB Query Reader (#385)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para las comisiones que se pagan a los intermediarios y la comision de reaseguro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.



select
PERIODO_CONTABLE,
cuenta_LOCAL,
subcuenta_local,
sum(VALOR_reaseguro)
from #reaseguro
--where poliza = 515244 and certificado = 213
group by periodo_contable,cuenta_LOCAL,subcuenta_local


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DML/DB_Query_Reader__386.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB Query Reader (#386)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para las comisiones que se pagan a los intermediarios y la comision de reaseguro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.



select 
concepto_nivel_2,
sum(valor_concepto)
from #no_coco_d
--where poliza = 515244 and certificado = 213
group by concepto_nivel_2


-- ==== [COMMISSIONS__216] sql/COMMISSIONS__216/DML/DB_Query_Reader__387.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB Query Reader (#387)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para las comisiones que se pagan a los intermediarios y la comision de reaseguro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.



select 
concepto_nivel_2,
sum(valor_concepto)
from #cocorretaje_sn_d
--where poliza = 515244 and certificado = 213
group by concepto_nivel_2


-- ==== [COMMISSIONS__216/OTRAS_COMISI__276] sql/COMMISSIONS__216/OTRAS_COMISI__276/DML/DB_Query_Reader__249.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\OTRAS COMISI (#276)\DB Query Reader (#249)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para otras comisiones o retornos adicionales dentro del calculo de comisiones,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.
-- Toma datos principalmente de: liberty.apoyo.dwh_profitcenter.

select * from liberty.apoyo.dwh_profitcenter


-- ==== [COMMISSIONS__216/PROFIT__275] sql/COMMISSIONS__216/PROFIT__275/DML/DB_Query_Reader__38.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\PROFIT (#275)\DB Query Reader (#38)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para la atribucion de las comisiones al profit center (unidad de negocio) correspondiente,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.
-- Toma datos principalmente de: liberty.apoyo.dwh_profitcenter.

select * from liberty.apoyo.dwh_profitcenter


-- ==== [COMMISSIONS__216/PROFIT__275] sql/COMMISSIONS__216/PROFIT__275/DML/DB_Query_Reader__271.sql ====
-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\PROFIT (#275)\DB Query Reader (#271)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para la atribucion de las comisiones al profit center (unidad de negocio) correspondiente,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.
-- Toma datos principalmente de: liberty.apoyo.dwh_intermediarios_total, LIBERTY..

select distinct
nit_cc,
INTERMEDIARIO_LIDE
from 
(
select 
COD_INTERMEDIARIO
,RAZON_SOCIAL
,CAST(NIT_CC AS BIGINT) AS NIT_CC
,TIPO_IDENTIFICACION
,CAST(COD_SUCURSAL AS INT) AS COD_SUCURSAL
,lider.llave
,lider.clave_lider as intermediario_lide
FROM liberty.apoyo.dwh_intermediarios_total total
left join  LIBERTY.[APOYO].[DWH_REDCOMERCIAL_INTERMEDIARIOS] lider on total.cod_intermediario = lider.llave
) a


-- >>> Aqui KNIME ejecuta un nodo "DB Insert (#218)" que hace: INSERT INTO liberty_pruebas_actuaria.dbo.PL_COL_DATOS_COCO SELECT * FROM #retorno_p ;
-- >>> NOTA: este INSERT es una reconstruccion/inferencia; el nodo DB Insert de KNIME no tiene script SQL capturado en este repositorio. La tabla temporal final es INCIERTA: el componente produce varias ramas (#retorno_p, #directa_p, #reaseguro_p) mas los DML de OTRAS_COMISI__276/PROFIT__275 sin que quede claro por el nombre de archivo cual es la unica tabla consumida por el DB Insert; se tomo la ultima tabla creada por numero de nodo DDL como mejor estimacion.

-- ----------------------------------------------------------------------------
-- COMPONENTE 4/8: CHANGE_IN_CA (#320) -- Siniestros pagados y change in case (version cocorretaje)
-- Calcula el siniestro pagado (sini.DWH_S_NOV_CONT_D) y el change in case
-- directo y cedido (middleware.DWH_REASEGURO_H), distribuyendo por cocorretaje.
-- Se ejecuta despues de Written Prem (#33). Escribe en PL_COL_DATOS_COCO
-- mediante el nodo DB Insert (#322).
-- ----------------------------------------------------------------------------
-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DDL/DB_SQL_Executor__8.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB SQL Executor (#8)
-- Clave      : statement
-- Que hace: calcula parte de los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje.
-- Arma la tabla temporal #sini_pagado a partir de liberty.sini.DWH_S_NOV_CONT_D, liberty.sini.dwh_s_maestro_d, liberty.apoyo.dwh_sbu_ramo_prod.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#sini_pagado','U') is not null drop table #sini_pagado


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$

Select 
a.periodo_contable
,a.ANNO_SINIESTRO
,a.RADICACION
,a.SUCURSAL_PROD
,a.RAMO_PROD
,b.POLIZA
,b.CERTIFICADO
,b.intermediario_lide
,t2.SBU
,a.ramo_contable
,sum(a.VR_NOVEDAD) as VR_PAGADO
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,'Pagado' AS Concepto_nivel_3
,'INTERFAZ_AUT' as Concepto_nivel_2 
,'CHANGE IN CASE' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
into #sini_pagado
from liberty.sini.DWH_S_NOV_CONT_D a
left join
liberty.sini.dwh_s_maestro_d b on  a.ANNO_SINIESTRO = b.ANNO_SINIESTRO and a.SUCURSAL_PROD = b.SUCURSAL_PROD and a.RADICACION = b.RADICACION and a.RAMO_PROD = b.RAMO_PROD
left join 
liberty.apoyo.dwh_sbu_ramo_prod t2 on a.ramo_prod = t2.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.ramo_prod and a.sucursal_prod = t4.sucursal and a.ramo_contable = t4.ramo_contable
where a.periodo_contable = @periodo_contable and TIPO_NOVEDAD in (5,6)
group by 
a.periodo_contable,
a.ANNO_SINIESTRO,
a.RADICACION,
a.SUCURSAL_PROD,
a.RAMO_PROD,
b.POLIZA,
b.CERTIFICADO,
b.intermediario_lide,
t2.SBU,
a.ramo_contable,
t4.cod_profitcenter,
t4.desc_profitcenter,
t4.cod_sbu_sap,
t4.desc_sbu_sap


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DDL/DB_SQL_Executor__10.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB SQL Executor (#10)
-- Clave      : statement
-- Que hace: calcula parte de los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje.
-- Arma la tabla temporal #sini_reserva a partir de liberty.sini.DWH_S_NOV_CONT_D, liberty.sini.dwh_s_maestro_d, liberty.apoyo.dwh_sbu_ramo_prod.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#sini_reserva','U') is not null drop table #sini_reserva

declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$

Select 
a.periodo_contable ,
a.ANNO_SINIESTRO,
a.RADICACION,
a.SUCURSAL_PROD,
a.RAMO_PROD,
b.POLIZA,
b.CERTIFICADO,
b.intermediario_lide,
t2.SBU,
a.ramo_contable,
sum(a.VR_NOVEDAD) as VR_RESERVA,
t4.cod_profitcenter,
t4.desc_profitcenter,
t4.cod_sbu_sap,
t4.desc_sbu_sap
,'Reserva' AS Concepto_nivel_3
,'INTERFAZ_AUT' as Concepto_nivel_2 
,'CHANGE IN CASE' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
into #sini_reserva
from liberty.sini.DWH_S_NOV_CONT_D a
left join
liberty.sini.dwh_s_maestro_d b on  a.ANNO_SINIESTRO = b.ANNO_SINIESTRO and a.SUCURSAL_PROD = b.SUCURSAL_PROD and a.RADICACION = b.RADICACION and a.RAMO_PROD = b.RAMO_PROD
left join 
liberty.apoyo.dwh_sbu_ramo_prod t2 on a.ramo_prod = t2.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.ramo_prod and a.sucursal_prod = t4.sucursal and a.ramo_contable = t4.ramo_contable
where a.periodo_contable = @periodo_contable 
group by 
a.periodo_contable,
a.ANNO_SINIESTRO,
a.RADICACION,
a.SUCURSAL_PROD,
a.RAMO_PROD,
b.POLIZA,
b.CERTIFICADO,
b.intermediario_lide,
t2.SBU,
a.ramo_contable,
t4.cod_profitcenter,
t4.desc_profitcenter,
t4.cod_sbu_sap,
t4.desc_sbu_sap


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DDL/DB_SQL_Executor__11.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB SQL Executor (#11)
-- Clave      : statement
-- Que hace: calcula parte de los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje.
-- Arma la tabla temporal #sini_pagado_pyg a partir de otras tablas ya calculadas antes en este mismo componente.

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#sini_pagado_pyg','U') is not null drop table #sini_pagado_pyg

Select 
periodo_contable
,SUCURSAL_PROD
,intermediario_lide
,SBU
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,sum(VR_PAGADO) AS VR_PAGADO
into #sini_pagado_pyg
from #sini_pagado
group by 
periodo_contable,
SUCURSAL_PROD,
intermediario_lide,
SBU,
cod_profitcenter,
desc_profitcenter,
cod_sbu_sap,
desc_sbu_sap


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DDL/DB_SQL_Executor__16.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB SQL Executor (#16)
-- Clave      : statement
-- Que hace: calcula parte de los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje.
-- Arma la tabla temporal #sini_incurrido a partir de liberty.prod.dwh_polizas_h, liberty.sini.DWH_S_NOV_CONT_D, liberty.sini.dwh_s_maestro_d.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#sini_incurrido','U') is not null drop table #sini_incurrido


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$



if OBJECT_ID('dbo.intermediarios_unicos','U') is not null drop table intermediarios_unicos
SELECT * 
INTO intermediarios_unicos
from (
		SELECT ramo_prod,
		       poliza AS pol,
		       intermediario_lide,
		       ROW_NUMBER() OVER (PARTITION BY ramo_prod, poliza ORDER BY intermediario_lide) AS rn
		FROM liberty.prod.dwh_polizas_h
		WHERE PERIODO_CONTABLE >= 202001
) a 
where rn = 1




Select 
a.periodo_contable ,
a.ANNO_SINIESTRO,
a.RADICACION,
a.SUCURSAL_PROD,
a.SUCURSAL_contable,
a.RAMO_PROD,
--a.VR_P_COASEGURO as Coaseguro,                
b.POLIZA,
b.CERTIFICADO,
b.DOCUMENTO,
coalesce(b.intermediario_lide,it.intermediario_lide) as INTERMEDIARIO_LIDE,
t2.SBU,
a.ramo_contable,
sum(a.VR_NOVEDAD) as VR_INCURRIDO,
SUM(convert	(
				decimal(25,2),a.VR_NOVEDAD*	(isnull	(
													case 	when coa_aseg_temp.VR_P_COASEGURO is null or coa_aseg_temp.VR_P_COASEGURO=0 then 1
															else (100-coa_aseg_temp.VR_P_COASEGURO)/100
													end,	case	when COA.[GDPJVR] is null or COA.[GDPJVR]=0 or COA.[GDPJVR]=100 then 1
																		else (COA.[GDPJVR])/100
															end
													)
											)
				)) as VR_INCURRIDO_NETO,
--case when a.SIS_ORIGEN = 'N' AND a.VR_P_COASEGURO=0 THEN a.VR_NOVEDAD
--	 when a.SIS_ORIGEN = 'N' AND a.VR_P_COASEGURO <>0 then  a.VR_NOVEDAD*1-(VR_P_COASEGURO/100)
--	 when a.SIS_ORIGEN = 'O' AND a.VR_P_COASEGURO=100 THEN a.VR_NOVEDAD
--	 when a.SIS_ORIGEN = 'O' AND a.VR_P_COASEGURO=100 THEN a.VR_NOVEDAD*(VR_P_COASEGURO/100)
--ELSE VR_NOVEDAD
--END AS VR_INCURRIDO_NETO_2,
t4.cod_profitcenter,
t4.desc_profitcenter,
t4.cod_sbu_sap,
t4.desc_sbu_sap,
b.modalidad
into #sini_incurrido
from liberty.sini.DWH_S_NOV_CONT_D a
left join
liberty.sini.dwh_s_maestro_d b on  a.ANNO_SINIESTRO = b.ANNO_SINIESTRO and a.SUCURSAL_PROD = b.SUCURSAL_PROD and a.RADICACION = b.RADICACION and a.RAMO_PROD = b.RAMO_PROD
left join 
liberty.apoyo.dwh_sbu_ramo_prod t2 on a.ramo_prod = t2.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.ramo_prod and a.sucursal_prod = t4.sucursal and a.ramo_contable = t4.ramo_contable
left join #RT_Apoyo_p_coaseg as coa_aseg_temp on	(
													coa_aseg_temp.poliza=b.POLIZA
													and coa_aseg_temp.certificado=b.CERTIFICADO
													and coa_aseg_temp.recibo=b.recibo
													and coa_aseg_temp.Id_Row=1
													and b.[SIS_ORIGEN] = 'N'
													)
left join [Liberty].[AS400].[SNLCOAC1] as COA on	(													
															b.ramo_prod = coa.GDRACG 
															and b.poliza= coa.GDPZNU 
															and b.certificado = coa.GDCTNU 
															and b.documento = coa.GDDCNU
															and b.[SIS_ORIGEN] = 'O'
															)
left join 
intermediarios_unicos it on a.RAMO_prod = it.ramo_prod and a.poliza = it.pol  		
where a.periodo_contable = @periodo_contable 
AND a.TIPO_NOVEDAD NOT IN (5,6)
group by
a.periodo_contable,
a.ANNO_SINIESTRO,
a.RADICACION,
a.SUCURSAL_PROD,
a.RAMO_PROD,
b.POLIZA,
b.CERTIFICADO,
b.documento,
--a.VR_P_COASEGURO,
b.intermediario_lide,
t2.SBU,
a.ramo_contable,
t4.cod_profitcenter,
t4.desc_profitcenter,
t4.cod_sbu_sap,
t4.desc_sbu_sap,
a.SIS_ORIGEN,
it.intermediario_lide,
b.modalidad,
a.SUCURSAL_contable




--Select 
--a.periodo_contable ,
--a.ANNO_SINIESTRO,
--a.RADICACION,
--a.SUCURSAL_PROD,
--a.RAMO_PROD,
--b.POLIZA,
--b.CERTIFICADO,
--b.DOCUMENTO,
--b.intermediario_lide,
--t2.SBU,
--a.ramo_contable,
--sum(a.VR_NOVEDAD) as VR_INCURRIDO,
--t4.cod_profitcenter,
--t4.desc_profitcenter,
--t4.cod_sbu_sap,
--t4.desc_sbu_sap
--into #sini_incurrido
--from liberty.sini.DWH_S_NOV_CONT_D a
--left join
--liberty.sini.dwh_s_maestro_d b on  a.ANNO_SINIESTRO = b.ANNO_SINIESTRO and a.SUCURSAL_PROD = b.SUCURSAL_PROD and a.RADICACION = b.RADICACION and a.RAMO_PROD = b.RAMO_PROD
--left join 
--liberty.apoyo.dwh_sbu_ramo_prod t2 on a.ramo_prod = t2.ramo_prod 
--left join
--liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.ramo_prod and a.sucursal_prod = t4.sucursal and a.ramo_contable = t4.ramo_contable
--where a.periodo_contable = @periodo_contable AND a.TIPO_NOVEDAD NOT IN (5,6)
--group by
--a.periodo_contable,
--a.ANNO_SINIESTRO,
--a.RADICACION,
--a.SUCURSAL_PROD,
--a.RAMO_PROD,
--b.POLIZA,
--b.CERTIFICADO,
--b.DOCUMENTO,
--b.intermediario_lide,
--t2.SBU,
--a.ramo_contable,
--t4.cod_profitcenter,
--t4.desc_profitcenter,
--t4.cod_sbu_sap,
--t4.desc_sbu_sap


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DDL/DB_SQL_Executor__17.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB SQL Executor (#17)
-- Clave      : statement
-- Que hace: calcula parte de los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje.
-- Arma la tabla temporal #sini_reserva_pyg a partir de otras tablas ya calculadas antes en este mismo componente.

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#sini_reserva_pyg','U') is not null drop table #sini_reserva_pyg

Select 
periodo_contable
,SUCURSAL_PROD
,intermediario_lide
,SBU
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,sum(VR_RESERVA) AS VR_RESERVA
into #sini_reserva_pyg
from #sini_reserva
group by 
periodo_contable,
SUCURSAL_PROD,
intermediario_lide,
SBU,
cod_profitcenter,
desc_profitcenter,
cod_sbu_sap,
desc_sbu_sap


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DDL/DB_SQL_Executor__20.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB SQL Executor (#20)
-- Clave      : statement
-- Que hace: calcula parte de los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje.
-- Arma la tabla temporal #sini_incurrido_pyg a partir de otras tablas ya calculadas antes en este mismo componente.

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#sini_incurrido_pyg','U') is not null drop table #sini_incurrido_pyg

Select 
periodo_contable AS PERIODO_CONTABLE
,SUCURSAL_PROD
,intermediario_lide AS INTERMEDIARIO_LIDE
,SBU
,sum(VR_INCURRIDO_NETO) AS VALOR_CONCEPTO
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,'Incurrido' AS Concepto_nivel_3
,'INTERFAZ_AUT' as Concepto_nivel_2 
,'CHANGE IN CASE' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
into #sini_incurrido_pyg
from #sini_incurrido
group by 
periodo_contable,
SUCURSAL_PROD,
intermediario_lide,
SBU,
cod_profitcenter,
desc_profitcenter,
cod_sbu_sap,
desc_sbu_sap


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DDL/DB_SQL_Executor__197.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB SQL Executor (#197)
-- Clave      : statement
-- Que hace: calcula parte de los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje.
-- Arma la tabla temporal #reaseguro_siniestros a partir de liberty., liberty.apoyo.dwh_sbu_ramo_prod, liberty.apoyo.dwh_profitcenter.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#reaseguro_siniestros','U') is not null drop table #reaseguro_siniestros

select 
a.mdpek as periodo_contable,
a.mdint as PROGRAMA_INTERFACE,
a.mddl1 as DESCRIPCION_CUENTA_SUB,
a.mdrc as ramo_contable,
a.mdsul as sucursal_prod,
a.mdlt as Libro,
b.sbu,
a.mdprt as codigo_ramo_producto,
[dbo].[F_Conv_Cod_Agente](a.mdagl) as INTERMEDIARIO_LIDE
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,case when a.mdnat = 'H'  THEN cast(a.mdaag as bigint) * -1 ELSE cast(a.mdaag as bigint) END AS VALOR_CONCEPTO
,a.mdmod as modalidad
,'Siniestros_reaseguro' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'REINSURANCE CHANGE IN CASE ' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
into #reaseguro_siniestros
from liberty.[MIDDLEWARE].[BASE_REASEGUROS_H] a
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.mdprt = b.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.mdprt and t4.sucursal = a.mdsul and t4.ramo_contable = a.mdrc
where mdpek = @periodo_contable  and  mdobj in (411640,411645)  and mdsct in (0101,0102,0103,0109,0113,0106,0402,0403,405,0405,0407,0102,0105,0107,0402)



--select 
--a.periodo as periodo_contable,
--a.PROGRAMA_INTERFACE,
--a.DESCRIPCION_CUENTA_SUB,
--a.ramo_contable,
--a.sucursal_prod,
--a.Libro,
--b.sbu,
--a.codigo_ramo_producto,
--[dbo].[F_Conv_Cod_Agente](a.agente_lider) as INTERMEDIARIO_LIDE
--,t4.cod_profitcenter
--,t4.desc_profitcenter
--,t4.cod_sbu_sap
--,t4.desc_sbu_sap
--,case when a.naturaleza_contable = 'H'  THEN cast(a.VALOR_RUBRO as bigint) * -1 ELSE cast(a.VALOR_RUBRO as bigint) END AS VALOR_CONCEPTO
--,'Siniestros_reaseguro' AS Concepto_nivel_3
--,'INTERFAZ_AUT' AS Concepto_nivel_2
--,'CHANGE IN CASE' as Concepto_nivel_1 
--,'TOTAL_CLAIMS' as Concepto_nivel_0 
--into #reaseguro_siniestros
--from liberty.middleware.dwh_reaseguro_h a
--left join 
--liberty.apoyo.dwh_sbu_ramo_prod b on a.codigo_ramo_producto = b.ramo_prod 
--left join
--liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.codigo_ramo_producto and t4.sucursal = a.sucursal_prod and t4.ramo_contable = a.ramo_contable
--where periodo = @periodo_contable  and  cuenta_local in (411640,411645)  and subcuenta_local in (0101,0102,0103,0109,0113,0106,0402,0403,405,0405,0407,0102,0105,0107,0402)


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DDL/DB_SQL_Executor__216.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB SQL Executor (#216)
-- Clave      : statement
-- Que hace: calcula parte de los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje.
-- Arma la tabla temporal #corretaje_sin, #corretaje, #cocorretaje_sucursal_sini, #sucursal_sin, #cocorretaje_sn_sin a partir de liberty..

USE Liberty_pruebas_actuaria


/*****************
TEMPORAL COCORRETAJE
******************/

if OBJECT_ID('tempdb.dbo.#corretaje_sin','U') is not null drop table #corretaje_sin

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
into #corretaje_sin
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




if OBJECT_ID('tempdb.dbo.#cocorretaje_sucursal_sini','U') is not null drop table #cocorretaje_sucursal_sini

select 
a.PERIODO_CONTABLE ,
a.ANNO_SINIESTRO,
a.RADICACION,
a.SUCURSAL_PROD,
a.RAMO_PROD,
a.POLIZA,
a.CERTIFICADO,
a.DOCUMENTO,
a.INTERMEDIARIO_LIDE,
a.SBU,
a.ramo_contable,
a.VR_INCURRIDO_NETO,
a.cod_profitcenter,
a.desc_profitcenter,
a.cod_sbu_sap,
a.desc_sbu_sap
,'Incurrido' AS Concepto_nivel_3
,'INTERFAZ_AUT' as Concepto_nivel_2 
,'CHANGE IN CASE' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
--,b.LLAVE_CERT 
,CASE WHEN B.LLAVE_CERT IS NULL THEN 0 ELSE 1 END as Marca_corretaje
into #cocorretaje_sucursal_sini
from #sini_incurrido a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje_sin) B ON (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT)


if OBJECT_ID('tempdb.dbo.#sucursal_sin','U') is not null drop table #sucursal_sin


select 
--distinct
--row_number() over(order by sseguro) as id,
a.PERIODO_CONTABLE ,
a.ANNO_SINIESTRO,
a.RADICACION,
a.SUCURSAL_PROD,
a.RAMO_PROD,
a.POLIZA,
a.CERTIFICADO,
a.DOCUMENTO,
a.INTERMEDIARIO_LIDE
into #sucursal_sin
from #cocorretaje_sucursal_sini a
where Marca_corretaje = 0

-------------------------------------------------




if OBJECT_ID('tempdb.dbo.#cocorretaje_sn_sin','U') is not null drop table #cocorretaje_sn_sin

select 
a.PERIODO_CONTABLE ,
a.ANNO_SINIESTRO,
a.RADICACION,
a.SUCURSAL_PROD,
a.RAMO_PROD,
a.POLIZA,
a.CERTIFICADO,
a.DOCUMENTO,
a.INTERMEDIARIO_LIDE,
a.SBU,
a.ramo_contable,
a.VR_INCURRIDO_NETO,
a.cod_profitcenter,
a.desc_profitcenter,
a.cod_sbu_sap,
a.desc_sbu_sap
,'Incurrido' AS Concepto_nivel_3
,'INTERFAZ_AUT' as Concepto_nivel_2 
,'CHANGE IN CASE' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
,CASE WHEN B.LLAVE_CERT IS NULL THEN 0 ELSE 1 END as Marca_corretaje
into #cocorretaje_sn_sin
from #sini_incurrido a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje_sin) B ON (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT) ---AND A.documento>=B.documento and A.documento<B.doc_2


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DDL/DB_SQL_Executor__218.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB SQL Executor (#218)
-- Clave      : statement
-- Que hace: calcula parte de los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje.
-- Arma la tabla temporal #si_coco a partir de otras tablas ya calculadas antes en este mismo componente.

USE Liberty_pruebas_actuaria

/************************
Separamos casos  si
**************************/

if OBJECT_ID('tempdb.dbo.#si_coco','U') is not null drop table #si_coco

select 
periodo_contable ,
ANNO_SINIESTRO,
RADICACION,
SUCURSAL_PROD,
RAMO_PROD,
POLIZA,
CERTIFICADO,
CASE WHEN DOCUMENTO = 0 THEN 1 ELSE DOCUMENTO END AS DOCUMENTO,
intermediario_lide,
SBU,
ramo_contable,
VR_INCURRIDO_NETO,
cod_profitcenter,
desc_profitcenter,
cod_sbu_sap,
desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2 
,Concepto_nivel_1 
,Concepto_nivel_0 
,Marca_corretaje
into #si_coco
from #cocorretaje_sn_sin
where marca_corretaje =1



--select *  
--into #si_coco
--from #cocorretaje_sn
--where cocorretaje =1


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DDL/DB_SQL_Executor__219.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB SQL Executor (#219)
-- Clave      : statement
-- Que hace: calcula parte de los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje.
-- Arma la tabla temporal #no_coco a partir de otras tablas ya calculadas antes en este mismo componente.

USE Liberty_pruebas_actuaria

/************************
Separamos casos no y si
**************************/

---- Para el caso no cocorretaje se le agregan las columnas necesarias para 
---- el union al final del proceso 

if OBJECT_ID('tempdb.dbo.#no_coco','U') is not null drop table #no_coco

select 
c.*
--,row_number() over(order by sseguro) as id
,INTERMEDIARIO_LIDE AS COD_INTERMEDIARIO,
0 AS PARTICIPACION,
DOCUMENTO AS DOC,
SUCURSAL_PROD AS COD_SUCURSAL,
c.VR_INCURRIDO_NETO as VR_INCURRIDO_CO
into #no_coco
from #cocorretaje_sn_sin c
where marca_corretaje =0


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DDL/DB_SQL_Executor__222.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB SQL Executor (#222)
-- Clave      : statement
-- Que hace: calcula parte de los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje.
-- Arma la tabla temporal #caso1 a partir de otras tablas ya calculadas antes en este mismo componente.

USE Liberty_pruebas_actuaria

/*****************
CASO 1 DE COCORRETAJE interemdiario misma sucursal 
******************/

if OBJECT_ID('tempdb.dbo.#caso1','U') is not null drop table #caso1

select
a.*,
case when b.participacion is null then a.intermediario_lide else
			b.COD_INTERMEDIARIO END AS COD_INTERMEDIARIO,
case when b.participacion is null then 0 		
			ELSE b.PARTICIPACION END AS PARTICIPACION,
case when b.participacion is null then a.DOCUMENTO 
			ELSE b.DOCUMENTO END AS DOC,
case when b.participacion is null then a.SUCURSAL_PROD
			else b.COD_SUCURSAL END as COD_SUCURSAL,
CASE WHEN b.PARTICIPACION IS NULL THEN a.VR_INCURRIDO_NETO
	 ELSE a.VR_INCURRIDO_NETO * (b.PARTICIPACION/100) 
END as VR_INCURRIDO_CO
into #caso1
from  #si_coco a
left join #corretaje_sin b 
on (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT AND A.documento>=B.documento and A.documento<B.doc_2)
--where
--b.PARTICIPACION is not null


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DDL/DB_SQL_Executor__226.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB SQL Executor (#226)
-- Clave      : statement
-- Que hace: calcula parte de los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje.
-- Arma la tabla temporal #cocorretaje_completo a partir de otras tablas ya calculadas antes en este mismo componente.

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
FROM #no_coco
UNION all
SELECT * FROM #caso1

) a


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DDL/DB_SQL_Executor__281.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB SQL Executor (#281)
-- Clave      : statement
-- Que hace: calcula parte de los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje.
-- Arma la tabla temporal #reaseguro_siniestros_1 a partir de otras tablas ya calculadas antes en este mismo componente.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#reaseguro_siniestros_1','U') is not null drop table #reaseguro_siniestros_1



select
PERIODO_CONTABLE
,SBU
,SUCURSAL_PROD
,INTERMEDIARIO_LIDE
,sum(VALOR_CONCEPTO) as VALOR_CONCEPTO
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
into #reaseguro_siniestros_1
from #reaseguro_siniestros
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


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DDL/DB_SQL_Executor__287.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB SQL Executor (#287)
-- Clave      : statement
-- Que hace: calcula parte de los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje.
-- Arma la tabla temporal #reaseguro_siniestros_co, #reaseguro_siniestros a partir de liberty., liberty.apoyo.dwh_sbu_ramo_prod, liberty.apoyo.dwh_profitcenter.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#reaseguro_siniestros_co','U') is not null drop table #reaseguro_siniestros_co

select 
a.mdpek as periodo_contable,
a.mdint as PROGRAMA_INTERFACE,
a.mddl1 as DESCRIPCION_CUENTA_SUB,
a.mdrc as ramo_contable,
a.mdsul as sucursal_prod,
a.mdsuc as cod_sucursal,
a.mdlt as Libro,
b.sbu,
a.mdprt as  RAMO_PROD,
a.mdpza as poliza,
[dbo].[F_Conv_Cod_Agente](a.mdagl) as INTERMEDIARIO_LIDE,
[dbo].[F_Conv_Cod_Agente](a.mdagc) as INTERMEDIARIO_CO
,a.mdmod as modalidad
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,case when a.mdnat = 'H'  THEN cast(a.mdaag as bigint) * -1 ELSE cast(a.mdaag as bigint) END AS VALOR_CONCEPTO
,'Siniestros_reaseguro' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'REINSURANCE CHANGE IN CASE' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
into #reaseguro_siniestros_co
from liberty.[MIDDLEWARE].[BASE_REASEGUROS_H] a
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.mdprt = b.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.mdprt and t4.sucursal = a.mdsul and t4.ramo_contable = a.mdrc
where mdpek >=  @periodo_contable  and  mdobj in (411640,411645)  and mdsct in (0101,0102,0103,0109,0113,0106,0402,0403,405,0405,0407,0102,0105,0107,0402)




--select 
--a.periodo as periodo_contable,
--a.PROGRAMA_INTERFACE,
--a.DESCRIPCION_CUENTA_SUB,
--a.ramo_contable,
--a.sucursal_prod,
--a.Libro,
--b.sbu,
--a.codigo_ramo_producto,
--[dbo].[F_Conv_Cod_Agente](a.agente_lider) as INTERMEDIARIO_LIDE
--,t4.cod_profitcenter
--,t4.desc_profitcenter
--,t4.cod_sbu_sap
--,t4.desc_sbu_sap
--,case when a.naturaleza_contable = 'H'  THEN cast(a.VALOR_RUBRO as bigint) * -1 ELSE cast(a.VALOR_RUBRO as bigint) END AS VALOR_CONCEPTO
--,'Siniestros_reaseguro' AS Concepto_nivel_3
--,'INTERFAZ_AUT' AS Concepto_nivel_2
--,'CHANGE IN CASE' as Concepto_nivel_1 
--,'TOTAL_CLAIMS' as Concepto_nivel_0 
--into #reaseguro_siniestros
--from liberty.middleware.dwh_reaseguro_h a
--left join 
--liberty.apoyo.dwh_sbu_ramo_prod b on a.codigo_ramo_producto = b.ramo_prod 
--left join
--liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.codigo_ramo_producto and t4.sucursal = a.sucursal_prod and t4.ramo_contable = a.ramo_contable
--where periodo = @periodo_contable  and  cuenta_local in (411640,411645)  and subcuenta_local in (0101,0102,0103,0109,0113,0106,0402,0403,405,0405,0407,0102,0105,0107,0402)


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DDL/DB_SQL_Executor__289.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB SQL Executor (#289)
-- Clave      : statement
-- Que hace: calcula parte de los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje.
-- Arma la tabla temporal #reaseguro_siniestros_1 a partir de otras tablas ya calculadas antes en este mismo componente.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#reaseguro_siniestros_1','U') is not null drop table #reaseguro_siniestros_1



select
PERIODO_CONTABLE
--,SUCURSAL_PROD
,RAMO_PROD
,POLIZA AS POLIZA
,SBU
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,SUBSTRING(LOB_SAP, 1, charindex('-', LOB_SAP)-1) as cod_sbu_sap 
,SUBSTRING(LOB_SAP, charindex('-', LOB_SAP)+1, len(LOB_SAP))  as desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,0 AS Marca_corretaje
,COD_INTERMEDIARIO AS COD_INTERMEDIARIO
,0 AS PARTICIPACION
,COD_SUCURSAL AS COD_SUCURSAL
,sum(VALOR_CONCEPTO) as VALOR_CONCEPTO
into #reaseguro_siniestros_1
from #reaseguro_siniestros
group by
PERIODO_CONTABLE
,SBU
,RAMO_PROD
,POLIZA
--,SUCURSAL_PROD
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,LOB_SAP
,COD_INTERMEDIARIO
,COD_SUCURSAL


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DDL/DB_SQL_Executor__298.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB SQL Executor (#298)
-- Clave      : statement
-- Que hace: calcula parte de los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje.
-- Arma la tabla temporal #RT_Apoyo_p_coaseg a partir de Liberty.PROD.DWH_POLIZAS_H.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_Pruebas_Actuaria

declare
@periodo_contable varchar(6)='201501'


if OBJECT_ID('tempdb.dbo.#RT_Apoyo_p_coaseg','U') is not null drop table #RT_Apoyo_p_coaseg


select row_number()over(partition by clasi.poliza,clasi.certificado,clasi.RECIBO order by clasi.VR_P_COASEGURO desc) as Id_Row,
*
into #RT_Apoyo_p_coaseg
from	(
		select distinct
		pol_h_A.poliza,
		pol_h_A.certificado,
		pol_h_A.SUCURSAL_PROD,
		pol_h_A.RAMO_PROD,
		--pol_h_A.documento,
		pol_h_A.RECIBO,
		pol_h_A.VR_P_COASEGURO
		from Liberty.PROD.DWH_POLIZAS_H as pol_h_A
		where
		pol_h_A.tipo_coaseguro=1
		and pol_h_A.PERIODO_CONTABLE>=@periodo_contable
		) as clasi

CREATE INDEX IDX_p_coaseg
ON #RT_Apoyo_p_coaseg(poliza,certificado,RECIBO)


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DDL/DB_SQL_Executor__305.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB SQL Executor (#305)
-- Clave      : statement
-- Que hace: calcula parte de los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje.
-- Arma la tabla temporal #reaseguro_siniestros a partir de liberty.amocom.homologa_profit_center.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#reaseguro_siniestros','U') is not null drop table #reaseguro_siniestros

select 
t1.periodo_contable,
t1.PROGRAMA_INTERFACE,
t1.DESCRIPCION_CUENTA_SUB,
t1.ramo_contable,
t1.sucursal_prod,
t1.cod_sucursal,
t1.Libro,
t1.sbu,
t1.RAMO_PROD,
t1.poliza,
t1.INTERMEDIARIO_LIDE,
COALESCE(t1.INTERMEDIARIO_CO,INTERMEDIARIO_LIDE) AS COD_INTERMEDIARIO
,coalesce(/*pc1.mapped_sapprofitcenter,*/ pc2.mapped_sapprofitcenter, pc3.mapped_sapprofitcenter, pc4.mapped_sapprofitcenter, pc5.mapped_sapprofitcenter, pc6.mapped_sapprofitcenter, pc7.mapped_sapprofitcenter, pc8.mapped_sapprofitcenter, pc9.mapped_sapprofitcenter) cod_profitcenter
,coalesce(/*pc1.[description],*/ pc2.[description], pc3.[description], pc4.[description], pc5.[description], pc6.[description], pc7.[description], pc8.[description], pc9.[description]) desc_profitcenter
,coalesce(/*pc1.[description],*/ pc2.lob_g1, pc3.lob_g1, pc4.lob_g1, pc5.lob_g1, pc6.lob_g1, pc7.lob_g1, pc8.lob_g1, pc9.lob_g1) LOB_SAP
,t1.VALOR_CONCEPTO
,t1.modalidad
,t1.Concepto_nivel_3
,t1.Concepto_nivel_2
,t1.Concepto_nivel_1 
,t1.Concepto_nivel_0 
into #reaseguro_siniestros 
from #reaseguro_siniestros_co t1
left join (select * from liberty.amocom.homologa_profit_center where opcion = 1) pc1
	on t1.ramo_contable = pc1.ramo_contable
	and t1.ramo_prod = pc1.ramo_producto_tecnico
	and t1.sucursal_prod = pc1.sucursal_contable
	and t1.modalidad = pc1.modalidad
left join (select * from liberty.amocom.homologa_profit_center where opcion = 2) pc2
	on t1.ramo_contable = pc2.ramo_contable
	and t1.ramo_prod = pc2.ramo_producto_tecnico
	and t1.sucursal_prod = pc2.sucursal_contable
left join (select * from liberty.amocom.homologa_profit_center where opcion = 3) pc3
	on t1.ramo_contable = pc3.ramo_contable
	and t1.ramo_prod = pc3.ramo_producto_tecnico
	and t1.modalidad = pc3.modalidad
left join (select * from liberty.amocom.homologa_profit_center where opcion = 4) pc4
	on t1.ramo_contable = pc4.ramo_contable
	and t1.sucursal_prod = pc4.sucursal_contable
	and t1.modalidad = pc4.modalidad
left join (select * from liberty.amocom.homologa_profit_center where opcion = 5) pc5
	on t1.ramo_contable = pc5.ramo_contable
	and t1.modalidad = pc5.modalidad
left join (select * from liberty.amocom.homologa_profit_center where opcion = 6) pc6
	on t1.ramo_contable = pc6.ramo_contable
	and t1.sucursal_prod = pc6.sucursal_contable
left join (select * from liberty.amocom.homologa_profit_center where opcion = 7) pc7
	on t1.ramo_contable = pc7.ramo_contable
	and t1.ramo_prod = pc7.ramo_producto_tecnico
left join (select * from liberty.amocom.homologa_profit_center where opcion = 8) pc8
	on t1.ramo_contable = pc8.ramo_contable
cross join (select * from liberty.amocom.homologa_profit_center where opcion = 9) pc9


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DDL/DB_SQL_Executor__308.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB SQL Executor (#308)
-- Clave      : statement
-- Que hace: calcula parte de los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje.
-- Arma la tabla temporal #profit a partir de liberty_pruebas_actuaria.dbo.PnL_Homologa_profit.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('#profit','U') is not null drop table #profit

drop table #profit


select  
t1.*
,coalesce(/*pc1.mapped_sapprofitcenter,*/ pc2.mapped_sapprofitcenter, pc3.mapped_sapprofitcenter, pc4.mapped_sapprofitcenter, pc5.mapped_sapprofitcenter, pc6.mapped_sapprofitcenter, pc7.mapped_sapprofitcenter, pc8.mapped_sapprofitcenter, pc9.mapped_sapprofitcenter) Profit_nuevo
,coalesce(/*pc1.[description],*/ pc2.[description], pc3.[description], pc4.[description], pc5.[description], pc6.[description], pc7.[description], pc8.[description], pc9.[description]) Descripcion_profit
,coalesce(/*pc1.[description],*/ pc2.lob_g1, pc3.lob_g1, pc4.lob_g1, pc5.lob_g1, pc6.lob_g1, pc7.lob_g1, pc8.lob_g1, pc9.lob_g1) LOB_SAP
into #profit
from  #sini_incurrido t1
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 1) pc1
	on t1.ramo_contable = pc1.ramo_contable
	and t1.ramo_prod = pc1.ramo_producto_tecnico
	and t1.sucursal_prod = pc1.sucursal_contable
	and t1.modalidad = pc1.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 2) pc2
	on t1.ramo_contable = pc2.ramo_contable
	and t1.ramo_prod = pc2.ramo_producto_tecnico
	and t1.sucursal_prod = pc2.sucursal_contable
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 3) pc3
	on t1.ramo_contable = pc3.ramo_contable
	and t1.ramo_prod = pc3.ramo_producto_tecnico
	and t1.modalidad = pc3.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 4) pc4
	on t1.ramo_contable = pc4.ramo_contable
	and t1.sucursal_prod = pc4.sucursal_contable
	and t1.modalidad = pc4.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 5) pc5
	on t1.ramo_contable = pc5.ramo_contable
	and t1.modalidad = pc5.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 6) pc6
	on t1.ramo_contable = pc6.ramo_contable
	and t1.sucursal_prod = pc6.sucursal_contable
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 7) pc7
	on t1.ramo_contable = pc7.ramo_contable
	and t1.ramo_prod = pc7.ramo_producto_tecnico
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 8) pc8
	on t1.ramo_contable = pc8.ramo_contable
cross join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 9) pc9


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DDL/DB_SQL_Executor__310.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB SQL Executor (#310)
-- Clave      : statement
-- Que hace: calcula parte de los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje.
-- Arma la tabla temporal #profit a partir de liberty.amocom.homologa_profit_center.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('#profit','U') is not null drop table #profit

drop table #profit


select  
t1.*
,coalesce(/*pc1.mapped_sapprofitcenter,*/ pc2.mapped_sapprofitcenter, pc3.mapped_sapprofitcenter, pc4.mapped_sapprofitcenter, pc5.mapped_sapprofitcenter, pc6.mapped_sapprofitcenter, pc7.mapped_sapprofitcenter, pc8.mapped_sapprofitcenter, pc9.mapped_sapprofitcenter) Profit_nuevo
,coalesce(/*pc1.[description],*/ pc2.[description], pc3.[description], pc4.[description], pc5.[description], pc6.[description], pc7.[description], pc8.[description], pc9.[description]) Descripcion_profit
,coalesce(/*pc1.[description],*/ pc2.lob_g1, pc3.lob_g1, pc4.lob_g1, pc5.lob_g1, pc6.lob_g1, pc7.lob_g1, pc8.lob_g1, pc9.lob_g1) LOB_SAP
into #profit
from  #sini_incurrido t1
left join (select * from liberty.amocom.homologa_profit_center where opcion = 1) pc1
	on t1.ramo_contable = pc1.ramo_contable
	and t1.ramo_prod = pc1.ramo_producto_tecnico
	and t1.sucursal_prod = pc1.sucursal_contable
	and t1.modalidad = pc1.modalidad
left join (select * from liberty.amocom.homologa_profit_center where opcion = 2) pc2
	on t1.ramo_contable = pc2.ramo_contable
	and t1.ramo_prod = pc2.ramo_producto_tecnico
	and t1.sucursal_prod = pc2.sucursal_contable
left join (select * from liberty.amocom.homologa_profit_center where opcion = 3) pc3
	on t1.ramo_contable = pc3.ramo_contable
	and t1.ramo_prod = pc3.ramo_producto_tecnico
	and t1.modalidad = pc3.modalidad
left join (select * from liberty.amocom.homologa_profit_center where opcion = 4) pc4
	on t1.ramo_contable = pc4.ramo_contable
	and t1.sucursal_prod = pc4.sucursal_contable
	and t1.modalidad = pc4.modalidad
left join (select * from liberty.amocom.homologa_profit_center where opcion = 5) pc5
	on t1.ramo_contable = pc5.ramo_contable
	and t1.modalidad = pc5.modalidad
left join (select * from liberty.amocom.homologa_profit_center where opcion = 6) pc6
	on t1.ramo_contable = pc6.ramo_contable
	and t1.sucursal_prod = pc6.sucursal_contable
left join (select * from liberty.amocom.homologa_profit_center where opcion = 7) pc7
	on t1.ramo_contable = pc7.ramo_contable
	and t1.ramo_prod = pc7.ramo_producto_tecnico
left join (select * from liberty.amocom.homologa_profit_center where opcion = 8) pc8
	on t1.ramo_contable = pc8.ramo_contable
cross join (select * from liberty.amocom.homologa_profit_center where opcion = 9) pc9


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DML/DB_Query_Reader__9.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB Query Reader (#9)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

select count(*) from #sini_pagado


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DML/DB_Query_Reader__13.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB Query Reader (#13)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

select count(*) from #sini_reserva


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DML/DB_Query_Reader__18.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB Query Reader (#18)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

select count(*) from #sini_reserva_pyg


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DML/DB_Query_Reader__19.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB Query Reader (#19)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

select count(*) from #sini_pagado_pyg


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DML/DB_Query_Reader__21.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB Query Reader (#21)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

select 
*
--sum(vr_incurrido)
from #sini_incurrido


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DML/DB_Query_Reader__22.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB Query Reader (#22)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

select * from #sini_incurrido_pyg


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DML/DB_Query_Reader__198.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB Query Reader (#198)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

select * From  #reaseguro_siniestros_1
where valor_concepto <> 0


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DML/DB_Query_Reader__217.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB Query Reader (#217)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.


    
--select 
--*
--sum(vr_incurrido)
--from #cocorretaje_sn_sin
--WHERE POLIZA = 19003112

SELECT * 
FROM #cocorretaje_sn_sin
--WHERE NRO_POLIZA =3000367 EJEMPLO PARA VALIDAR CON ANDREY
-- AND NRO_CERTIFICADO = 6274 AND COD_RAMO_PROD = 'LO'


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DML/DB_Query_Reader__220.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB Query Reader (#220)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

/*select * from #primas_pyg */

--select COUNT(*) from #cocorretaje_sn

select  
 *
--sum(vr_incurrido_co)
--count(*)
from #no_coco
--WHERE POLIZA =19003112


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DML/DB_Query_Reader__221.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB Query Reader (#221)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

/*select * from #primas_pyg */

--select COUNT(*) from #cocorretaje_sn
--1419

select
*
----sum(vr_incurrido)
from #si_coco
--WHERE POLIZA = 19003112


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DML/DB_Query_Reader__223.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB Query Reader (#223)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.



select 
*
--count(*)
--sum(vr_incurrido),sum(vr_incurrido_co) 
from #caso1
--WHERE POLIZA = 19003112


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DML/DB_Query_Reader__229.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB Query Reader (#229)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

SELECT * 
FROM  #cocorretaje_completo
WHERE VR_INCURRIDO_CO <> 0


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DML/DB_Query_Reader__288.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB Query Reader (#288)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

select * From  #reaseguro_siniestros_1
where valor_concepto <> 0


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DML/DB_Query_Reader__306.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB Query Reader (#306)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

select * From  #reaseguro_siniestros 
where valor_concepto <> 0


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DML/DB_Query_Reader__309.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB Query Reader (#309)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

select 
*
--sum(vr_incurrido)
from #profit
where ramo_prod = 'BO'


-- ==== [CHANGE_IN_CA__320] sql/CHANGE_IN_CA__320/DML/DB_Query_Reader__311.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB Query Reader (#311)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los siniestros pagados y la variacion (change in case) de la reserva de siniestros, version cocorretaje,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

select 
*
--sum(vr_incurrido)
from #sini_incurrido
where ramo_prod = 'BO'


-- >>> Aqui KNIME ejecuta un nodo "DB Insert (#322)" que hace: INSERT INTO liberty_pruebas_actuaria.dbo.PL_COL_DATOS_COCO SELECT * FROM #profit ;
-- >>> NOTA: este INSERT es una reconstruccion/inferencia; el nodo DB Insert de KNIME no tiene script SQL capturado en este repositorio. La tabla temporal final es INCIERTA: la ultima DDL por numero de nodo (__310) crea #profit, pero ese nombre tambien es creado antes (__308) y luce como tabla de homologacion auxiliar, no necesariamente el resultado final del componente.

-- ----------------------------------------------------------------------------
-- COMPONENTE 5/8: CHANGE_IN_CA (#34) -- Movimiento de reservas de siniestros
-- Calcula el Change in Case (variacion de la reserva de siniestros avisados)
-- sobre sini.DWH_S_MAESTRO_D y prod.DWH_POLIZAS_H, generando CHANGE IN CASE L,
-- CHANGE IN CASE V y REINSURANCE CHANGE IN CASE. Tras su ejecucion se dispara
-- Recobros_sin (#315). Escribe en PL_COL_DATOS_COCO mediante el nodo DB Insert (#203).
-- ----------------------------------------------------------------------------
-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DDL/DB_SQL_Executor__16.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#16)
-- Clave      : statement
-- Que hace: calcula parte de el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro.
-- Arma la tabla temporal #documentos_unicos, #documento_sin, #sini_incurrido a partir de liberty.prod.dwh_polizas_h, liberty.sini.dwh_s_maestro_d, liberty..
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#sini_incurrido','U') is not null drop table #sini_incurrido


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$





/*********************************
Documento polizas_h por recibo
*********************************/



DROP TABLE IF EXISTS #documentos_unicos

SELECT * 
INTO #documentos_unicos
from (
		SELECT ramo_prod,
		       poliza AS pol,
		       certificado,
		       recibo,
		       documento,
		       ROW_NUMBER() OVER (PARTITION BY ramo_prod, poliza,certificado,recibo ORDER BY documento asc) AS rn
		FROM liberty.prod.dwh_polizas_h
		WHERE PERIODO_CONTABLE >= 200101 and sis_origen = 'N'
		) a 
where rn = 1

/******************************************
Documento desde el radicado del siniestro
******************************************/



DROP TABLE IF EXISTS #documento_sin

SELECT RADICACION,DOCUMENTO,COUNT(*) as conteo 
INTO #documento_sin
FROM liberty.sini.dwh_s_maestro_d
WHERE SIS_ORIGEN = 'N'
GROUP BY RADICACION,DOCUMENTO


/******************************************
LIQUIDAOS BASE_H
******************************************/

DROP TABLE IF EXISTS #sini_incurrido

select 
a.mdpek as periodo_contable,
a.mdint as PROGRAMA_INTERFACE,
a.mddl1 as DESCRIPCION_CUENTA_SUB,
a.mdrc as ramo_contable,
a.mdsul as sucursal_prod,
a.mdsuc as cod_sucursal,
a.mdrep as documento,
null as documento_final,
a.mdlt as Libro,
b.sbu,
a.mdprt as  RAMO_PROD,
a.mdpza as poliza,
a.mdctd as certificado,
a.mdnsn as numero_siniestro,
--0 AS documento,
a.mdagl as INTERMEDIARIO_LIDE,
a.mdagc as INTERMEDIARIO_CO
,a.mdmod as modalidad
,cast(a.mdaag as bigint) AS VALOR_CONCEPTO
--,case when a.mdnat = 'H'  THEN cast(a.mdaag as bigint) * -1 ELSE cast(a.mdaag as bigint) END AS VALOR_CONCEPTO
,'Siniestros_liquidados' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'CHANGE IN CASE L' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
into #sini_incurrido
from liberty.[MIDDLEWARE].[BASE_H] a
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.mdprt = b.ramo_prod 
--left join #documentos_unicos c on a.mdpza = c.pol and a.mdctd = c.certificado and a.documento = b.recibo
where mdpek >=  202501  and mdobj in (510205,510210,510215)
and mdsct in (102,105,101,103,1001,104,106)


/*****************************************************************************
actualizar documento AL = IAXIS  AA AS400 - Cruce con  polizas_h y maestro_h
******************************************************************************/


update a
set a.documento_final = b.documento
from #sini_incurrido a 
left join #documentos_unicos b  on  a.poliza = b.pol and a.certificado = b.certificado and a.documento = b.recibo
where libro = 'AL'

update a
set a.documento_final = b.documento
from #sini_incurrido a 
left join #documento_sin b  on  convert(int,a.numero_siniestro) = b.radicacion
where libro = 'AL' and documento_final is null

update a
set a.documento_final = 0
from #sini_incurrido a 
where libro = 'AL' and documento_final is null

update a
set a.documento_final = 0
from #sini_incurrido a 
where libro = 'AL' and documento_final is null



update a
set a.documento_final = a.documento
from #sini_incurrido a 
where libro = 'AA' and documento_final is null


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DDL/DB_SQL_Executor__216.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#216)
-- Clave      : statement
-- Que hace: calcula parte de el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro.
-- Arma la tabla temporal #corretaje_sin, #corretaje, #cocorretaje_sucursal_sini, #sucursal_sin, #cocorretaje_sn_sin a partir de liberty..

USE Liberty_pruebas_actuaria


/*****************
TEMPORAL COCORRETAJE
******************/

if OBJECT_ID('tempdb.dbo.#corretaje_sin','U') is not null drop table #corretaje_sin

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
into #corretaje_sin
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




if OBJECT_ID('tempdb.dbo.#cocorretaje_sucursal_sini','U') is not null drop table #cocorretaje_sucursal_sini

select 
a.PERIODO_CONTABLE ,
--a.ANNO_SINIESTRO,
---a.RADICACION,
a.SUCURSAL_PROD,
a.RAMO_PROD,
a.POLIZA,
a.CERTIFICADO,
a.DOCUMENTO,
a.INTERMEDIARIO_LIDE,
a.SBU,
a.ramo_contable,
a.VALOR_CONCEPTO,
a.profit_nuevo as cod_profitcenter
,a.Descripcion_profit as desc_profitcenter
,SUBSTRING(LOB_SAP, 1, charindex('-', LOB_SAP)-1) as cod_sbu_sap 
,SUBSTRING(LOB_SAP, charindex('-', LOB_SAP)+1, len(LOB_SAP))  as desc_sbu_sap
,'Siniestros_liquidados' AS Concepto_nivel_3
,'INTERFAZ_AUT' as Concepto_nivel_2 
,'CHANGE IN CASE L' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
--,b.LLAVE_CERT 
,CASE WHEN B.LLAVE_CERT IS NULL THEN 0 ELSE 1 END as Marca_corretaje
into #cocorretaje_sucursal_sini
from #sini_incurrido_1 a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje_sin) B ON (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT)


if OBJECT_ID('tempdb.dbo.#sucursal_sin','U') is not null drop table #sucursal_sin


select 
--distinct
--row_number() over(order by sseguro) as id,
a.PERIODO_CONTABLE ,
--a.ANNO_SINIESTRO,
--a.RADICACION,
a.SUCURSAL_PROD,
a.RAMO_PROD,
a.POLIZA,
a.CERTIFICADO,
a.DOCUMENTO,
a.INTERMEDIARIO_LIDE
into #sucursal_sin
from #cocorretaje_sucursal_sini a
where Marca_corretaje = 0

-------------------------------------------------




if OBJECT_ID('tempdb.dbo.#cocorretaje_sn_sin','U') is not null drop table #cocorretaje_sn_sin

select 
a.PERIODO_CONTABLE ,
--a.ANNO_SINIESTRO,
---a.RADICACION,
a.SUCURSAL_PROD,
a.RAMO_PROD,
a.POLIZA,
a.CERTIFICADO,
a.DOCUMENTO,
a.INTERMEDIARIO_LIDE,
a.SBU,
a.ramo_contable,
a.VALOR_CONCEPTO,
a.profit_nuevo as cod_profitcenter
,a.Descripcion_profit as desc_profitcenter
,SUBSTRING(LOB_SAP, 1, charindex('-', LOB_SAP)-1) as cod_sbu_sap 
,SUBSTRING(LOB_SAP, charindex('-', LOB_SAP)+1, len(LOB_SAP))  as desc_sbu_sap
,'Siniestros_liquidados' AS Concepto_nivel_3
,'INTERFAZ_AUT' as Concepto_nivel_2 
,'CHANGE IN CASE L' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
,CASE WHEN B.LLAVE_CERT IS NULL THEN 0 ELSE 1 END as Marca_corretaje
into #cocorretaje_sn_sin
from #sini_incurrido_1 a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje_sin) B ON (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT) ---AND A.documento>=B.documento and A.documento<B.doc_2


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DDL/DB_SQL_Executor__218.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#218)
-- Clave      : statement
-- Que hace: calcula parte de el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro.
-- Arma la tabla temporal #si_coco a partir de otras tablas ya calculadas antes en este mismo componente.

USE Liberty_pruebas_actuaria

/************************
Separamos casos  si
**************************/

if OBJECT_ID('tempdb.dbo.#si_coco','U') is not null drop table #si_coco

select 
periodo_contable ,
--ANNO_SINIESTRO,
--RADICACION,
SUCURSAL_PROD,
RAMO_PROD,
POLIZA,
CERTIFICADO,
CASE WHEN DOCUMENTO = 0 THEN 1 ELSE DOCUMENTO END AS DOCUMENTO,
intermediario_lide,
SBU,
ramo_contable,
VALOR_CONCEPTO,
cod_profitcenter,
desc_profitcenter,
cod_sbu_sap,
desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2 
,Concepto_nivel_1 
,Concepto_nivel_0 
,Marca_corretaje
into #si_coco
from #cocorretaje_sn_sin
where marca_corretaje =1



--select *  
--into #si_coco
--from #cocorretaje_sn
--where cocorretaje =1


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DDL/DB_SQL_Executor__219.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#219)
-- Clave      : statement
-- Que hace: calcula parte de el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro.
-- Arma la tabla temporal #no_coco a partir de otras tablas ya calculadas antes en este mismo componente.

USE Liberty_pruebas_actuaria

/************************
Separamos casos no y si
**************************/

---- Para el caso no cocorretaje se le agregan las columnas necesarias para 
---- el union al final del proceso 

if OBJECT_ID('tempdb.dbo.#no_coco','U') is not null drop table #no_coco

select 
c.*
--,row_number() over(order by sseguro) as id
,INTERMEDIARIO_LIDE AS COD_INTERMEDIARIO,
0 AS PARTICIPACION,
DOCUMENTO AS DOC,
SUCURSAL_PROD AS COD_SUCURSAL,
c.VALOR_CONCEPTO as VALOR_CONCEPTO_CO
into #no_coco
from #cocorretaje_sn_sin c
where marca_corretaje =0


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DDL/DB_SQL_Executor__222.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#222)
-- Clave      : statement
-- Que hace: calcula parte de el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro.
-- Arma la tabla temporal #caso1 a partir de otras tablas ya calculadas antes en este mismo componente.

USE Liberty_pruebas_actuaria

/*****************
CASO 1 DE COCORRETAJE interemdiario misma sucursal 
******************/

if OBJECT_ID('tempdb.dbo.#caso1','U') is not null drop table #caso1

select
a.*,
case when b.participacion is null then a.intermediario_lide else
			b.COD_INTERMEDIARIO END AS COD_INTERMEDIARIO,
case when b.participacion is null then 0 		
			ELSE b.PARTICIPACION END AS PARTICIPACION,
case when b.participacion is null then a.DOCUMENTO 
			ELSE b.DOCUMENTO END AS DOC,
case when b.participacion is null then a.SUCURSAL_PROD
			else b.COD_SUCURSAL END as COD_SUCURSAL,
CASE WHEN b.PARTICIPACION IS NULL THEN a.VALOR_CONCEPTO
	 ELSE a.VALOR_CONCEPTO * (b.PARTICIPACION/100) 
END as VALOR_CONCEPTO_CO
into #caso1
from #si_coco a
left join #corretaje_sin b 
on (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT AND A.documento>=B.documento and A.documento<B.doc_2)


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DDL/DB_SQL_Executor__226.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#226)
-- Clave      : statement
-- Que hace: calcula parte de el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro.
-- Arma la tabla temporal #cocorretaje_completo a partir de otras tablas ya calculadas antes en este mismo componente.

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
FROM #no_coco
UNION all
SELECT * FROM #caso1

) a


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DDL/DB_SQL_Executor__287.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#287)
-- Clave      : statement
-- Que hace: calcula parte de el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro.
-- Arma la tabla temporal #reaseguro_siniestros_co a partir de liberty., liberty.apoyo.dwh_sbu_ramo_prod, liberty.apoyo.dwh_profitcenter.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$

if OBJECT_ID('tempdb.dbo.#reaseguro_siniestros_co','U') is not null drop table #reaseguro_siniestros_co

select 
a.mdpek as periodo_contable,
a.mdint as PROGRAMA_INTERFACE,
a.mddl1 as DESCRIPCION_CUENTA_SUB,
a.mdrc as ramo_contable,
a.mdsul as sucursal_prod,
a.mdsuc as cod_sucursal,
a.mdlt as Libro,
b.sbu,
a.mdprt as  RAMO_PROD,
a.mdpza as poliza,
[dbo].[F_Conv_Cod_Agente](a.mdagl) as INTERMEDIARIO_LIDE,
[dbo].[F_Conv_Cod_Agente](a.mdagc) as INTERMEDIARIO_CO
,a.mdmod as modalidad
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,case when a.mdnat = 'H'  THEN cast(a.mdaag as bigint) * -1 ELSE cast(a.mdaag as bigint) END AS VALOR_CONCEPTO
,'Siniestros_reaseguro' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'REINSURANCE CHANGE IN CASE' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
into #reaseguro_siniestros_co
from liberty.[MIDDLEWARE].[BASE_REASEGUROS_H] a
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.mdprt = b.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.mdprt and t4.sucursal = a.mdsul and t4.ramo_contable = a.mdrc
where mdpek >=  @periodo_contable  and  mdobj in (411640,411645)  and mdsct in (0101,0102,0103,0109,0113,0106,0402,0403,405,0405,0407,0102,0105,0107,0402)


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DDL/DB_SQL_Executor__289.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#289)
-- Clave      : statement
-- Que hace: calcula parte de el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro.
-- Arma la tabla temporal #reaseguro_siniestros_1 a partir de otras tablas ya calculadas antes en este mismo componente.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#reaseguro_siniestros_1','U') is not null drop table #reaseguro_siniestros_1



select
PERIODO_CONTABLE
--,SUCURSAL_PROD
,RAMO_PROD
,POLIZA AS POLIZA
,SBU
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,SUBSTRING(LOB_SAP, 1, charindex('-', LOB_SAP)-1) as cod_sbu_sap 
,SUBSTRING(LOB_SAP, charindex('-', LOB_SAP)+1, len(LOB_SAP))  as desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,0 AS Marca_corretaje
,COD_INTERMEDIARIO AS COD_INTERMEDIARIO
,0 AS PARTICIPACION
,COD_SUCURSAL AS COD_SUCURSAL
,sum(VALOR_CONCEPTO) as VALOR_CONCEPTO
into #reaseguro_siniestros_1
from #reaseguro_siniestros
group by
PERIODO_CONTABLE
,SBU
,RAMO_PROD
,POLIZA
--,SUCURSAL_PROD
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,LOB_SAP
,COD_INTERMEDIARIO
,COD_SUCURSAL


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DDL/DB_SQL_Executor__298.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#298)
-- Clave      : statement
-- Que hace: calcula parte de el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro.
-- Arma la tabla temporal #RT_Apoyo_p_coaseg a partir de Liberty.PROD.DWH_POLIZAS_H.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_Pruebas_Actuaria

declare
@periodo_contable varchar(6)='201501'


if OBJECT_ID('tempdb.dbo.#RT_Apoyo_p_coaseg','U') is not null drop table #RT_Apoyo_p_coaseg


select row_number()over(partition by clasi.poliza,clasi.certificado,clasi.RECIBO order by clasi.VR_P_COASEGURO desc) as Id_Row,
*
into #RT_Apoyo_p_coaseg
from	(
		select distinct
		pol_h_A.poliza,
		pol_h_A.certificado,
		pol_h_A.SUCURSAL_PROD,
		pol_h_A.RAMO_PROD,
		--pol_h_A.documento,
		pol_h_A.RECIBO,
		pol_h_A.VR_P_COASEGURO
		from Liberty.PROD.DWH_POLIZAS_H as pol_h_A
		where
		pol_h_A.tipo_coaseguro=1
		and pol_h_A.PERIODO_CONTABLE>=@periodo_contable
		) as clasi

CREATE INDEX IDX_p_coaseg
ON #RT_Apoyo_p_coaseg(poliza,certificado,RECIBO)


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DDL/DB_SQL_Executor__305.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#305)
-- Clave      : statement
-- Que hace: calcula parte de el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro.
-- Arma la tabla temporal #reaseguro_siniestros a partir de liberty.amocom.homologa_profit_center.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#reaseguro_siniestros','U') is not null drop table #reaseguro_siniestros

select 
t1.periodo_contable,
t1.PROGRAMA_INTERFACE,
t1.DESCRIPCION_CUENTA_SUB,
t1.ramo_contable,
t1.sucursal_prod,
t1.cod_sucursal,
t1.Libro,
t1.sbu,
t1.RAMO_PROD,
t1.poliza,
t1.INTERMEDIARIO_LIDE,
COALESCE(t1.INTERMEDIARIO_CO,INTERMEDIARIO_LIDE) AS COD_INTERMEDIARIO
,coalesce(/*pc1.mapped_sapprofitcenter,*/ pc2.mapped_sapprofitcenter, pc3.mapped_sapprofitcenter, pc4.mapped_sapprofitcenter, pc5.mapped_sapprofitcenter, pc6.mapped_sapprofitcenter, pc7.mapped_sapprofitcenter, pc8.mapped_sapprofitcenter, pc9.mapped_sapprofitcenter) cod_profitcenter
,coalesce(/*pc1.[description],*/ pc2.[description], pc3.[description], pc4.[description], pc5.[description], pc6.[description], pc7.[description], pc8.[description], pc9.[description]) desc_profitcenter
,coalesce(/*pc1.[description],*/ pc2.lob_g1, pc3.lob_g1, pc4.lob_g1, pc5.lob_g1, pc6.lob_g1, pc7.lob_g1, pc8.lob_g1, pc9.lob_g1) LOB_SAP
,t1.VALOR_CONCEPTO
,t1.modalidad
,t1.Concepto_nivel_3
,t1.Concepto_nivel_2
,t1.Concepto_nivel_1 
,t1.Concepto_nivel_0 
into #reaseguro_siniestros 
from #reaseguro_siniestros_co t1
left join (select * from liberty.amocom.homologa_profit_center where opcion = 1) pc1
	on t1.ramo_contable = pc1.ramo_contable
	and t1.ramo_prod = pc1.ramo_producto_tecnico
	and t1.sucursal_prod = pc1.sucursal_contable
	and t1.modalidad = pc1.modalidad
left join (select * from liberty.amocom.homologa_profit_center where opcion = 2) pc2
	on t1.ramo_contable = pc2.ramo_contable
	and t1.ramo_prod = pc2.ramo_producto_tecnico
	and t1.sucursal_prod = pc2.sucursal_contable
left join (select * from liberty.amocom.homologa_profit_center where opcion = 3) pc3
	on t1.ramo_contable = pc3.ramo_contable
	and t1.ramo_prod = pc3.ramo_producto_tecnico
	and t1.modalidad = pc3.modalidad
left join (select * from liberty.amocom.homologa_profit_center where opcion = 4) pc4
	on t1.ramo_contable = pc4.ramo_contable
	and t1.sucursal_prod = pc4.sucursal_contable
	and t1.modalidad = pc4.modalidad
left join (select * from liberty.amocom.homologa_profit_center where opcion = 5) pc5
	on t1.ramo_contable = pc5.ramo_contable
	and t1.modalidad = pc5.modalidad
left join (select * from liberty.amocom.homologa_profit_center where opcion = 6) pc6
	on t1.ramo_contable = pc6.ramo_contable
	and t1.sucursal_prod = pc6.sucursal_contable
left join (select * from liberty.amocom.homologa_profit_center where opcion = 7) pc7
	on t1.ramo_contable = pc7.ramo_contable
	and t1.ramo_prod = pc7.ramo_producto_tecnico
left join (select * from liberty.amocom.homologa_profit_center where opcion = 8) pc8
	on t1.ramo_contable = pc8.ramo_contable
cross join (select * from liberty.amocom.homologa_profit_center where opcion = 9) pc9


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DDL/DB_SQL_Executor__308.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#308)
-- Clave      : statement
-- Que hace: calcula parte de el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro.
-- Arma la tabla temporal #sini_incurrido_1 a partir de liberty_pruebas_actuaria.dbo.PnL_Homologa_profit.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('#sini_incurrido_1','U') is not null drop table #sini_incurrido_1

drop table #sini_incurrido_1


select  
t1.*
,coalesce(/*pc1.mapped_sapprofitcenter,*/ pc2.mapped_sapprofitcenter, pc3.mapped_sapprofitcenter, pc4.mapped_sapprofitcenter, pc5.mapped_sapprofitcenter, pc6.mapped_sapprofitcenter, pc7.mapped_sapprofitcenter, pc8.mapped_sapprofitcenter, pc9.mapped_sapprofitcenter) Profit_nuevo
,coalesce(/*pc1.[description],*/ pc2.[description], pc3.[description], pc4.[description], pc5.[description], pc6.[description], pc7.[description], pc8.[description], pc9.[description]) Descripcion_profit
,coalesce(/*pc1.[description],*/ pc2.lob_g1, pc3.lob_g1, pc4.lob_g1, pc5.lob_g1, pc6.lob_g1, pc7.lob_g1, pc8.lob_g1, pc9.lob_g1) LOB_SAP
into #sini_incurrido_1
from  #sini_incurrido t1
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 1) pc1
	on t1.ramo_contable = pc1.ramo_contable
	and t1.ramo_prod = pc1.ramo_producto_tecnico
	and t1.sucursal_prod = pc1.sucursal_contable
	and t1.modalidad = pc1.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 2) pc2
	on t1.ramo_contable = pc2.ramo_contable
	and t1.ramo_prod = pc2.ramo_producto_tecnico
	and t1.sucursal_prod = pc2.sucursal_contable
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 3) pc3
	on t1.ramo_contable = pc3.ramo_contable
	and t1.ramo_prod = pc3.ramo_producto_tecnico
	and t1.modalidad = pc3.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 4) pc4
	on t1.ramo_contable = pc4.ramo_contable
	and t1.sucursal_prod = pc4.sucursal_contable
	and t1.modalidad = pc4.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 5) pc5
	on t1.ramo_contable = pc5.ramo_contable
	and t1.modalidad = pc5.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 6) pc6
	on t1.ramo_contable = pc6.ramo_contable
	and t1.sucursal_prod = pc6.sucursal_contable
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 7) pc7
	on t1.ramo_contable = pc7.ramo_contable
	and t1.ramo_prod = pc7.ramo_producto_tecnico
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 8) pc8
	on t1.ramo_contable = pc8.ramo_contable
cross join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 9) pc9


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DDL/DB_SQL_Executor__312.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#312)
-- Clave      : statement
-- Que hace: calcula parte de el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro.
-- Arma la tabla temporal #cocorretaje_completo a partir de otras tablas ya calculadas antes en este mismo componente.

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
FROM #no_coco
UNION all
SELECT * FROM #caso1

) a


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DDL/DB_SQL_Executor__315.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#315)
-- Clave      : statement
-- Que hace: calcula parte de el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro.
-- Arma la tabla temporal #sini_incurrido_v_1 a partir de liberty_pruebas_actuaria.dbo.PnL_Homologa_profit.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$



drop table if exists #sini_incurrido_v_1


select  
t1.*
,coalesce(/*pc1.mapped_sapprofitcenter,*/ pc2.mapped_sapprofitcenter, pc3.mapped_sapprofitcenter, pc4.mapped_sapprofitcenter, pc5.mapped_sapprofitcenter, pc6.mapped_sapprofitcenter, pc7.mapped_sapprofitcenter, pc8.mapped_sapprofitcenter, pc9.mapped_sapprofitcenter) Profit_nuevo
,coalesce(/*pc1.[description],*/ pc2.[description], pc3.[description], pc4.[description], pc5.[description], pc6.[description], pc7.[description], pc8.[description], pc9.[description]) Descripcion_profit
,coalesce(/*pc1.[description],*/ pc2.lob_g1, pc3.lob_g1, pc4.lob_g1, pc5.lob_g1, pc6.lob_g1, pc7.lob_g1, pc8.lob_g1, pc9.lob_g1) LOB_SAP
into #sini_incurrido_v_1
from #sini_incurrido_va t1
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 1) pc1
	on t1.ramo_contable = pc1.ramo_contable
	and t1.ramo_prod = pc1.ramo_producto_tecnico
	and t1.sucursal_prod = pc1.sucursal_contable
	and t1.modalidad = pc1.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 2) pc2
	on t1.ramo_contable = pc2.ramo_contable
	and t1.ramo_prod = pc2.ramo_producto_tecnico
	and t1.sucursal_prod = pc2.sucursal_contable
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 3) pc3
	on t1.ramo_contable = pc3.ramo_contable
	and t1.ramo_prod = pc3.ramo_producto_tecnico
	and t1.modalidad = pc3.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 4) pc4
	on t1.ramo_contable = pc4.ramo_contable
	and t1.sucursal_prod = pc4.sucursal_contable
	and t1.modalidad = pc4.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 5) pc5
	on t1.ramo_contable = pc5.ramo_contable
	and t1.modalidad = pc5.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 6) pc6
	on t1.ramo_contable = pc6.ramo_contable
	and t1.sucursal_prod = pc6.sucursal_contable
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 7) pc7
	on t1.ramo_contable = pc7.ramo_contable
	and t1.ramo_prod = pc7.ramo_producto_tecnico
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 8) pc8
	on t1.ramo_contable = pc8.ramo_contable
cross join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 9) pc9


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DDL/DB_SQL_Executor__319.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#319)
-- Clave      : statement
-- Que hace: calcula parte de el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro.
-- Arma la tabla temporal #caso1 a partir de otras tablas ya calculadas antes en este mismo componente.

USE Liberty_pruebas_actuaria

/*****************
CASO 1 DE COCORRETAJE interemdiario misma sucursal 
******************/

if OBJECT_ID('tempdb.dbo.#caso1','U') is not null drop table #caso1

select
a.*,
case when b.participacion is null then a.intermediario_lide else
			b.COD_INTERMEDIARIO END AS COD_INTERMEDIARIO,
case when b.participacion is null then 0 		
			ELSE b.PARTICIPACION END AS PARTICIPACION,
case when b.participacion is null then a.DOCUMENTO 
			ELSE b.DOCUMENTO END AS DOC,
case when b.participacion is null then a.SUCURSAL_PROD
			else b.COD_SUCURSAL END as COD_SUCURSAL,
CASE WHEN b.PARTICIPACION IS NULL THEN a.VALOR_CONCEPTO
	 ELSE a.VALOR_CONCEPTO * (b.PARTICIPACION/100) 
END as VALOR_CONCEPTO_CO
into #caso1
from  #si_coco a
left join #corretaje_sin b 
on (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT AND A.documento>=B.documento and A.documento<B.doc_2)
--where
--b.PARTICIPACION is not null


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DDL/DB_SQL_Executor__322.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#322)
-- Clave      : statement
-- Que hace: calcula parte de el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro.
-- Arma la tabla temporal #corretaje_sin, #corretaje, #cocorretaje_sucursal_sini, #sucursal_sin, #cocorretaje_sn_sin a partir de liberty..

USE Liberty_pruebas_actuaria


/*****************
TEMPORAL COCORRETAJE
******************/

if OBJECT_ID('tempdb.dbo.#corretaje_sin','U') is not null drop table #corretaje_sin

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
into #corretaje_sin
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




if OBJECT_ID('tempdb.dbo.#cocorretaje_sucursal_sini','U') is not null drop table #cocorretaje_sucursal_sini

select 
a.PERIODO_CONTABLE ,
--a.ANNO_SINIESTRO,
---a.RADICACION,
a.SUCURSAL_PROD,
a.RAMO_PROD,
a.POLIZA,
a.CERTIFICADO,
a.DOCUMENTO,
a.INTERMEDIARIO_LIDE,
a.SBU,
a.ramo_contable,
a.VALOR_CONCEPTO,
a.profit_nuevo as cod_profitcenter
,a.Descripcion_profit as desc_profitcenter
,SUBSTRING(LOB_SAP, 1, charindex('-', LOB_SAP)-1) as cod_sbu_sap 
,SUBSTRING(LOB_SAP, charindex('-', LOB_SAP)+1, len(LOB_SAP))  as desc_sbu_sap
,'Siniestros_variacion' AS Concepto_nivel_3
,'INTERFAZ_AUT' as Concepto_nivel_2 
,'CHANGE IN CASE V' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
--,b.LLAVE_CERT 
,CASE WHEN B.LLAVE_CERT IS NULL THEN 0 ELSE 1 END as Marca_corretaje
into #cocorretaje_sucursal_sini
from  #sini_incurrido_v_1 a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje_sin) B ON (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT)


if OBJECT_ID('tempdb.dbo.#sucursal_sin','U') is not null drop table #sucursal_sin


select 
--distinct
--row_number() over(order by sseguro) as id,
a.PERIODO_CONTABLE ,
--a.ANNO_SINIESTRO,
--a.RADICACION,
a.SUCURSAL_PROD,
a.RAMO_PROD,
a.POLIZA,
a.CERTIFICADO,
a.DOCUMENTO,
a.INTERMEDIARIO_LIDE
into #sucursal_sin
from #cocorretaje_sucursal_sini a
where Marca_corretaje = 0

-------------------------------------------------




if OBJECT_ID('tempdb.dbo.#cocorretaje_sn_sin','U') is not null drop table #cocorretaje_sn_sin

select 
a.PERIODO_CONTABLE ,
--a.ANNO_SINIESTRO,
---a.RADICACION,
a.SUCURSAL_PROD,
a.RAMO_PROD,
a.POLIZA,
a.CERTIFICADO,
a.DOCUMENTO_FINAL AS DOCUMENTO,
a.INTERMEDIARIO_LIDE,
a.SBU,
a.ramo_contable,
a.VALOR_CONCEPTO,
a.profit_nuevo as cod_profitcenter
,a.Descripcion_profit as desc_profitcenter
,SUBSTRING(LOB_SAP, 1, charindex('-', LOB_SAP)-1) as cod_sbu_sap 
,SUBSTRING(LOB_SAP, charindex('-', LOB_SAP)+1, len(LOB_SAP))  as desc_sbu_sap
,'Siniestros_variacion' AS Concepto_nivel_3
,'INTERFAZ_AUT' as Concepto_nivel_2 
,'CHANGE IN CASE V' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
,CASE WHEN B.LLAVE_CERT IS NULL THEN 0 ELSE 1 END as Marca_corretaje
into #cocorretaje_sn_sin
from  #sini_incurrido_v_1 a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje_sin) B ON (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT) ---AND A.documento>=B.documento and A.documento<B.doc_2


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DDL/DB_SQL_Executor__323.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#323)
-- Clave      : statement
-- Que hace: calcula parte de el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro.
-- Arma la tabla temporal #no_coco a partir de otras tablas ya calculadas antes en este mismo componente.

USE Liberty_pruebas_actuaria

/************************
Separamos casos no y si
**************************/

---- Para el caso no cocorretaje se le agregan las columnas necesarias para 
---- el union al final del proceso 

if OBJECT_ID('tempdb.dbo.#no_coco','U') is not null drop table #no_coco

select 
c.*
--,row_number() over(order by sseguro) as id
,INTERMEDIARIO_LIDE AS COD_INTERMEDIARIO,
0 AS PARTICIPACION,
DOCUMENTO AS DOC,
SUCURSAL_PROD AS COD_SUCURSAL,
c.VALOR_CONCEPTO as VALOR_CONCEPTO_CO
into #no_coco
from #cocorretaje_sn_sin c
where marca_corretaje =0


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DDL/DB_SQL_Executor__324.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#324)
-- Clave      : statement
-- Que hace: calcula parte de el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro.
-- Arma la tabla temporal #si_coco a partir de otras tablas ya calculadas antes en este mismo componente.

USE Liberty_pruebas_actuaria

/************************
Separamos casos  si
**************************/

if OBJECT_ID('tempdb.dbo.#si_coco','U') is not null drop table #si_coco

select 
periodo_contable ,
--ANNO_SINIESTRO,
--RADICACION,
SUCURSAL_PROD,
RAMO_PROD,
POLIZA,
CERTIFICADO,
CASE WHEN DOCUMENTO = 0 THEN 1 ELSE DOCUMENTO END AS DOCUMENTO,
intermediario_lide,
SBU,
ramo_contable,
VALOR_CONCEPTO,
cod_profitcenter,
desc_profitcenter,
cod_sbu_sap,
desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2 
,Concepto_nivel_1 
,Concepto_nivel_0 
,Marca_corretaje
into #si_coco
from #cocorretaje_sn_sin
where marca_corretaje =1



--select *  
--into #si_coco
--from #cocorretaje_sn
--where cocorretaje =1


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DDL/DB_SQL_Executor__327.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#327)
-- Clave      : statement
-- Que hace: calcula parte de el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro.
-- Arma la tabla temporal #documento_sin, #sini_incurrido_va a partir de liberty.sini.dwh_s_maestro_d, liberty., liberty.apoyo.dwh_sbu_ramo_prod.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#sini_incurrido_v','U') is not null drop table #sini_incurrido_v


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$



/******************************************
Documento desde el radicado del siniestro
******************************************/



DROP TABLE IF EXISTS #documento_sin

SELECT RADICACION,DOCUMENTO,COUNT(*) as conteo 
INTO #documento_sin
FROM liberty.sini.dwh_s_maestro_d
WHERE SIS_ORIGEN = 'N'
GROUP BY RADICACION,DOCUMENTO


/******************************************
VARIACION BASE_H
******************************************/

DROP TABLE IF EXISTS #sini_incurrido_va

select 
a.mdpek as periodo_contable,
a.mdint as PROGRAMA_INTERFACE,
a.mddl1 as DESCRIPCION_CUENTA_SUB,
a.mdrc as ramo_contable,
a.mdsul as sucursal_prod,
a.mdsuc as cod_sucursal,
a.mdrep as documento,
null as documento_final,
a.mdlt as Libro,
b.sbu,
a.mdobj as cuenta,
a.mdsct as subcuenta,
a.mdprt as  RAMO_PROD,
a.mdpza as poliza,
a.mdctd as certificado,
a.mdnsn as numero_siniestro,
--0 AS documento,
a.mdagl as INTERMEDIARIO_LIDE,
a.mdagc as INTERMEDIARIO_CO
,a.mdmod as modalidad
,cast(a.mdaag as bigint) AS VALOR_CONCEPTO
--,case when a.mdnat = 'H'  THEN cast(a.mdaag as bigint) * -1 ELSE cast(a.mdaag as bigint) END AS VALOR_CONCEPTO
,'Siniestros_variacion' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'CHANGE IN CASE V' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
into #sini_incurrido_va
from liberty.[MIDDLEWARE].[BASE_H] a
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.mdprt = b.ramo_prod 
--left join #documentos_unicos c on a.mdpza = c.pol and a.mdctd = c.certificado and a.documento = b.recibo
where mdpek >=  202501  and mdobj in (411105)
and mdsct in (101,102,103,104,105,201,502,602,701,702,704
,706,707,708,709,1202,1301,301,302,501,501,402,402,106,202)



union all

select 
a.mdpek as periodo_contable,
a.mdint as PROGRAMA_INTERFACE,
a.mddl1 as DESCRIPCION_CUENTA_SUB,
a.mdrc as ramo_contable,
a.mdsul as sucursal_prod,
a.mdsuc as cod_sucursal,
a.mdrep as documento,
null as documento_final,
a.mdlt as Libro,
b.sbu,
a.mdobj as cuenta,
a.mdsct as subcuenta,
a.mdprt as  RAMO_PROD,
a.mdpza as poliza,
a.mdctd as certificado,
a.mdnsn as numero_siniestro,
--0 AS documento,
a.mdagl as INTERMEDIARIO_LIDE,
a.mdagc as INTERMEDIARIO_CO
,a.mdmod as modalidad
,cast(a.mdaag as bigint) AS VALOR_CONCEPTO
--,case when a.mdnat = 'H'  THEN cast(a.mdaag as bigint) * -1 ELSE cast(a.mdaag as bigint) END AS VALOR_CONCEPTO
,'Siniestros_variacion' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'CHANGE IN CASE V' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
from liberty.[MIDDLEWARE].[BASE_H] a
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.mdprt = b.ramo_prod 
--left join #documentos_unicos c on a.mdpza = c.pol and a.mdctd = c.certificado and a.documento = b.recibo
where mdpek >=  202501  and mdobj in (411110)
and mdsct in (101
,102,103,201,502,706,1202,104,202,1301
)

union all

select 
a.mdpek as periodo_contable,
a.mdint as PROGRAMA_INTERFACE,
a.mddl1 as DESCRIPCION_CUENTA_SUB,
a.mdrc as ramo_contable,
a.mdsul as sucursal_prod,
a.mdsuc as cod_sucursal,
a.mdrep as documento,
null as documento_final,
a.mdlt as Libro,
b.sbu,
a.mdobj as cuenta,
a.mdsct as subcuenta,
a.mdprt as  RAMO_PROD,
a.mdpza as poliza,
a.mdctd as certificado,
a.mdnsn as numero_siniestro,
--0 AS documento,
a.mdagl as INTERMEDIARIO_LIDE,
a.mdagc as INTERMEDIARIO_CO
,a.mdmod as modalidad
,cast(a.mdaag as bigint) AS VALOR_CONCEPTO
--,case when a.mdnat = 'H'  THEN cast(a.mdaag as bigint) * -1 ELSE cast(a.mdaag as bigint) END AS VALOR_CONCEPTO
,'Siniestros_variacion' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'CHANGE IN CASE V' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
from liberty.[MIDDLEWARE].[BASE_H] a
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.mdprt = b.ramo_prod 
--left join #documentos_unicos c on a.mdpza = c.pol and a.mdctd = c.certificado and a.documento = b.recibo
where mdpek >=  202501  and mdobj in (411115)
and mdsct in (101,102,103,104,105)

union all 

select 
a.mdpek as periodo_contable,
a.mdint as PROGRAMA_INTERFACE,
a.mddl1 as DESCRIPCION_CUENTA_SUB,
a.mdrc as ramo_contable,
a.mdsul as sucursal_prod,
a.mdsuc as cod_sucursal,
a.mdrep as documento,
null as documento_final,
a.mdlt as Libro,
b.sbu,
a.mdobj as cuenta,
a.mdsct as subcuenta,
a.mdprt as  RAMO_PROD,
a.mdpza as poliza,
a.mdctd as certificado,
a.mdnsn as numero_siniestro,
--0 AS documento,
a.mdagl as INTERMEDIARIO_LIDE,
a.mdagc as INTERMEDIARIO_CO
,a.mdmod as modalidad
,cast(a.mdaag as bigint) AS VALOR_CONCEPTO
--,case when a.mdnat = 'H'  THEN cast(a.mdaag as bigint) * -1 ELSE cast(a.mdaag as bigint) END AS VALOR_CONCEPTO
,'Siniestros_variacion' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'CHANGE IN CASE V' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
from liberty.[MIDDLEWARE].[BASE_H] a
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.mdprt = b.ramo_prod 
--left join #documentos_unicos c on a.mdpza = c.pol and a.mdctd = c.certificado and a.documento = b.recibo
where mdpek >=  202501  
and mdobj in (511105)
and mdsct in (18
,101,102,103,104,105,106,199,201,202,701,702,704,706,708
,709,724,1201,1202,1301,502,502,703,703,701,501,501,723)




union all

select 
a.mdpek as periodo_contable,
a.mdint as PROGRAMA_INTERFACE,
a.mddl1 as DESCRIPCION_CUENTA_SUB,
a.mdrc as ramo_contable,
a.mdsul as sucursal_prod,
a.mdsuc as cod_sucursal,
a.mdrep as documento,
null as documento_final,
a.mdlt as Libro,
b.sbu,
a.mdobj as cuenta,
a.mdsct as subcuenta,
a.mdprt as  RAMO_PROD,
a.mdpza as poliza,
a.mdctd as certificado,
a.mdnsn as numero_siniestro,
--0 AS documento,
a.mdagl as INTERMEDIARIO_LIDE,
a.mdagc as INTERMEDIARIO_CO
,a.mdmod as modalidad
,cast(a.mdaag as bigint) AS VALOR_CONCEPTO
--,case when a.mdnat = 'H'  THEN cast(a.mdaag as bigint) * -1 ELSE cast(a.mdaag as bigint) END AS VALOR_CONCEPTO
,'Siniestros_variacion' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'CHANGE IN CASE V' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
from liberty.[MIDDLEWARE].[BASE_H] a
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.mdprt = b.ramo_prod 
--left join #documentos_unicos c on a.mdpza = c.pol and a.mdctd = c.certificado and a.documento = b.recibo
where mdpek >=  202501  and mdobj in (511110)
and mdsct in (18
,502,101,102,103,106,199,202,702,706
,723,1202,704,201,1201,104,105,1301
)

union all

select 
a.mdpek as periodo_contable,
a.mdint as PROGRAMA_INTERFACE,
a.mddl1 as DESCRIPCION_CUENTA_SUB,
a.mdrc as ramo_contable,
a.mdsul as sucursal_prod,
a.mdsuc as cod_sucursal,
a.mdrep as documento,
null as documento_final,
a.mdlt as Libro,
b.sbu,
a.mdobj as cuenta,
a.mdsct as subcuenta,
a.mdprt as  RAMO_PROD,
a.mdpza as poliza,
a.mdctd as certificado,
a.mdnsn as numero_siniestro,
--0 AS documento,
a.mdagl as INTERMEDIARIO_LIDE,
a.mdagc as INTERMEDIARIO_CO
,a.mdmod as modalidad
,cast(a.mdaag as bigint) AS VALOR_CONCEPTO
--,case when a.mdnat = 'H'  THEN cast(a.mdaag as bigint) * -1 ELSE cast(a.mdaag as bigint) END AS VALOR_CONCEPTO
,'Siniestros_variacion' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'CHANGE IN CASE V' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
from liberty.[MIDDLEWARE].[BASE_H] a
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.mdprt = b.ramo_prod 
--left join #documentos_unicos c on a.mdpza = c.pol and a.mdctd = c.certificado and a.documento = b.recibo
where mdpek >=  202501  and mdobj in (511115)
and mdsct in (18
,101,102,103,104,105,106
)

/*****************************************************************************
actualizar documento AL = IAXIS  AA AS400 - Cruce con  polizas_h y maestro_h
******************************************************************************/

update a
set a.documento_final = b.documento
from #sini_incurrido_va a 
left join #documento_sin b  on  convert(int,a.numero_siniestro) = b.radicacion
where libro = 'AL' and documento_final is null

update a
set a.documento_final = 0
from #sini_incurrido_va a 
where libro = 'AL' and documento_final is null



update a
set a.documento_final = a.documento
from #sini_incurrido_va a 
where libro = 'AA' and documento_final is null


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DDL/DB_SQL_Executor__330.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#330)
-- Clave      : statement
-- Que hace: calcula parte de el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro.
-- Arma la tabla temporal #RT_Apoyo_p_coaseg a partir de Liberty.PROD.DWH_POLIZAS_H.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_Pruebas_Actuaria

declare
@periodo_contable varchar(6)='201501'


if OBJECT_ID('tempdb.dbo.#RT_Apoyo_p_coaseg','U') is not null drop table #RT_Apoyo_p_coaseg


select row_number()over(partition by clasi.poliza,clasi.certificado,clasi.RECIBO order by clasi.VR_P_COASEGURO desc) as Id_Row,
*
into #RT_Apoyo_p_coaseg
from	(
		select distinct
		pol_h_A.poliza,
		pol_h_A.certificado,
		pol_h_A.SUCURSAL_PROD,
		pol_h_A.RAMO_PROD,
		--pol_h_A.documento,
		pol_h_A.RECIBO,
		pol_h_A.VR_P_COASEGURO
		from Liberty.PROD.DWH_POLIZAS_H as pol_h_A
		where
		pol_h_A.tipo_coaseguro=1
		and pol_h_A.PERIODO_CONTABLE>=@periodo_contable
		) as clasi

CREATE INDEX IDX_p_coaseg
ON #RT_Apoyo_p_coaseg(poliza,certificado,RECIBO)


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DDL/DB_SQL_Executor__342.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#342)
-- Clave      : statement
-- Que hace: calcula parte de el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro.
-- Arma la tabla temporal #documento_sin, #sini_incurrido_v_r a partir de liberty.sini.dwh_s_maestro_d, liberty., liberty.apoyo.dwh_sbu_ramo_prod.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

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


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DDL/DB_SQL_Executor__346.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#346)
-- Clave      : statement
-- Que hace: calcula parte de el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro.
-- Arma la tabla temporal #sini_incurrido_v_r_1 a partir de liberty_pruebas_actuaria.dbo.PnL_Homologa_profit.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('#profit','U') is not null drop table #profit

drop table #sini_incurrido_v_r_1


select  
t1.*
,coalesce(/*pc1.mapped_sapprofitcenter,*/ pc2.mapped_sapprofitcenter, pc3.mapped_sapprofitcenter, pc4.mapped_sapprofitcenter, pc5.mapped_sapprofitcenter, pc6.mapped_sapprofitcenter, pc7.mapped_sapprofitcenter, pc8.mapped_sapprofitcenter, pc9.mapped_sapprofitcenter) Profit_nuevo
,coalesce(/*pc1.[description],*/ pc2.[description], pc3.[description], pc4.[description], pc5.[description], pc6.[description], pc7.[description], pc8.[description], pc9.[description]) Descripcion_profit
,coalesce(/*pc1.[description],*/ pc2.lob_g1, pc3.lob_g1, pc4.lob_g1, pc5.lob_g1, pc6.lob_g1, pc7.lob_g1, pc8.lob_g1, pc9.lob_g1) LOB_SAP
into #sini_incurrido_v_r_1
from  #sini_incurrido_v_r t1
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 1) pc1
	on t1.ramo_contable = pc1.ramo_contable
	and t1.ramo_prod = pc1.ramo_producto_tecnico
	and t1.sucursal_prod = pc1.sucursal_contable
	and t1.modalidad = pc1.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 2) pc2
	on t1.ramo_contable = pc2.ramo_contable
	and t1.ramo_prod = pc2.ramo_producto_tecnico
	and t1.sucursal_prod = pc2.sucursal_contable
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 3) pc3
	on t1.ramo_contable = pc3.ramo_contable
	and t1.ramo_prod = pc3.ramo_producto_tecnico
	and t1.modalidad = pc3.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 4) pc4
	on t1.ramo_contable = pc4.ramo_contable
	and t1.sucursal_prod = pc4.sucursal_contable
	and t1.modalidad = pc4.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 5) pc5
	on t1.ramo_contable = pc5.ramo_contable
	and t1.modalidad = pc5.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 6) pc6
	on t1.ramo_contable = pc6.ramo_contable
	and t1.sucursal_prod = pc6.sucursal_contable
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 7) pc7
	on t1.ramo_contable = pc7.ramo_contable
	and t1.ramo_prod = pc7.ramo_producto_tecnico
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 8) pc8
	on t1.ramo_contable = pc8.ramo_contable
cross join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 9) pc9


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DDL/DB_SQL_Executor__360.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#360)
-- Clave      : statement
-- Que hace: calcula parte de el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro.
-- Arma la tabla temporal #RT_Apoyo_p_coaseg a partir de Liberty.PROD.DWH_POLIZAS_H.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_Pruebas_Actuaria

declare
@periodo_contable varchar(6)='201501'


if OBJECT_ID('tempdb.dbo.#RT_Apoyo_p_coaseg','U') is not null drop table #RT_Apoyo_p_coaseg


select row_number()over(partition by clasi.poliza,clasi.certificado,clasi.RECIBO order by clasi.VR_P_COASEGURO desc) as Id_Row,
*
into #RT_Apoyo_p_coaseg
from	(
		select distinct
		pol_h_A.poliza,
		pol_h_A.certificado,
		pol_h_A.SUCURSAL_PROD,
		pol_h_A.RAMO_PROD,
		--pol_h_A.documento,
		pol_h_A.RECIBO,
		pol_h_A.VR_P_COASEGURO
		from Liberty.PROD.DWH_POLIZAS_H as pol_h_A
		where
		pol_h_A.tipo_coaseguro=1
		and pol_h_A.PERIODO_CONTABLE>=@periodo_contable
		) as clasi

CREATE INDEX IDX_p_coaseg
ON #RT_Apoyo_p_coaseg(poliza,certificado,RECIBO)


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DDL/DB_SQL_Executor__364.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#364)
-- Clave      : statement
-- Que hace: calcula parte de el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro.
-- Arma la tabla temporal #sini_incurrido_v_r_11 a partir de otras tablas ya calculadas antes en este mismo componente.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#reaseguro_siniestros_11','U') is not null drop table #reaseguro_siniestros_11



select
PERIODO_CONTABLE
--,SUCURSAL_PROD
,RAMO_PROD
,POLIZA AS POLIZA
,SBU
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,SUBSTRING(LOB_SAP, 1, charindex('-', LOB_SAP)-1) as cod_sbu_sap 
,SUBSTRING(LOB_SAP, charindex('-', LOB_SAP)+1, len(LOB_SAP))  as desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,0 AS Marca_corretaje
,INTERMEDIARIO_LIDE AS COD_INTERMEDIARIO
,0 AS PARTICIPACION
,COD_SUCURSAL AS COD_SUCURSAL
,sum(VALOR_CONCEPTO) as VALOR_CONCEPTO
into #sini_incurrido_v_r_11
from #sini_incurrido_v_r_1
group by
PERIODO_CONTABLE
,SBU
,RAMO_PROD
,POLIZA
--,SUCURSAL_PROD
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,LOB_SAP

,COD_SUCURSAL


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DML/DB_Query_Reader__229.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB Query Reader (#229)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

SELECT * 
FROM  #cocorretaje_completo
WHERE VALOR_CONCEPTO_CO <> 0


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DML/DB_Query_Reader__288.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB Query Reader (#288)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

select * From  #reaseguro_siniestros_1
where valor_concepto <> 0


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DML/DB_Query_Reader__306.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB Query Reader (#306)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

select * From  #reaseguro_siniestros 
where valor_concepto <> 0


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DML/DB_Query_Reader__316.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB Query Reader (#316)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

SELECT * 
FROM  #cocorretaje_completo
WHERE VALOR_CONCEPTO_CO <> 0


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DML/DB_Query_Reader__334.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB Query Reader (#334)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

select 
*
--sum(vr_incurrido)
from #sini_incurrido_v_1


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DML/DB_Query_Reader__350.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB Query Reader (#350)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

select 
*
--sum(vr_incurrido)
from #sini_incurrido_v_1


-- ==== [CHANGE_IN_CA__34] sql/CHANGE_IN_CA__34/DML/DB_Query_Reader__365.sql ====
-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB Query Reader (#365)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para el movimiento de la reserva de siniestros (cuanto se espera pagar por siniestros abiertos) de un periodo a otro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

select * From  #sini_incurrido_v_r_11
where valor_concepto <> 0


-- >>> Aqui KNIME ejecuta un nodo "DB Insert (#203)" que hace: INSERT INTO liberty_pruebas_actuaria.dbo.PL_COL_DATOS_COCO SELECT * FROM #sini_incurrido_v_r_11 ;
-- >>> NOTA: este INSERT es una reconstruccion/inferencia; el nodo DB Insert de KNIME no tiene script SQL capturado en este repositorio.

-- ----------------------------------------------------------------------------
-- COMPONENTE 6/8: SALVAMENTOS (#229) -- Ingresos por salvamentos
-- Calcula los salvamentos (recuperacion de bienes siniestrados) y su efecto
-- en el change in case, con atribucion de profit center via apoyo.DWH_PROFITCENTER.
-- Escribe en PL_COL_DATOS_COCO mediante el nodo DB Insert (#234).
-- ----------------------------------------------------------------------------
-- ==== [SALVAMENTOS__229] sql/SALVAMENTOS__229/DDL/DB_SQL_Executor__181.sql ====
-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB SQL Executor (#181)
-- Clave      : statement
-- Que hace: calcula parte de los ingresos por venta de salvamentos (bienes recuperados de siniestros).
-- Arma la tabla temporal #salvamentos_As400 a partir de liberty..
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.
-- Nota: comision: el pago que recibe un intermediario (agente o corredor) por vender o gestionar una poliza.

USE Liberty_Pruebas_Actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#salvamentos_As400','U') is not null drop table #salvamentos_as400

select 
DTPEKN	AS  PERIODO_CONTABLE
,DTSCNU AS  SUCURSAL_INGRESO
,DTSCLD	as  SUCURSAL_PROD
,DTRACG AS 	RAMO_PROD
,DTPZNU AS	POLIZA
,DTCTNU AS	CERTIFICADO
,DTDCNU AS	DOCUMENTO
,DTANSN AS	ANO_SINIESTRO
,DTRCNU AS	NRO_RADC_SINIESTRO
,DTTDNT AS  NIT_TOMADOR
,DTASNT AS	NIT_ASEGURADO
,DTITCG AS	INTERMEDIARIO_LIDE
,DTVRPO AS	VLR_PAGADO_SAL
,DTIVAC AS  VALOR_IVA_COMISION
,DTIVRC AS	VALOR_IVA_RETENIDO
,DTINDC AS	VALOR_INDUS_CIO
,DTRTEF AS	VALOR_RTE_FTE
,DTIBOM AS	VR_IMP_BOMBERIL
,DTFCPO AS	FEC_LEGALIZADO
into #salvamentos_As400
from liberty.[AS400].[REFIGVDT]
where DTPEKN = @PERIODO_CONTABLE AND DTTNNU IN (30)--, 143, 153, 142)


-- ==== [SALVAMENTOS__229] sql/SALVAMENTOS__229/DDL/DB_SQL_Executor__216.sql ====
-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB SQL Executor (#216)
-- Clave      : statement
-- Que hace: calcula parte de los ingresos por venta de salvamentos (bienes recuperados de siniestros).
-- Arma la tabla temporal #corretaje, #cocorretaje_sn a partir de liberty..

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


-------------------------------------------------



/*********************
Marca Corretaje
*********************/

if OBJECT_ID('tempdb.dbo.#cocorretaje_sn','U') is not null drop table #cocorretaje_sn

select 
a.*
--,b.LLAVE_CERT 
,CASE WHEN B.LLAVE_CERT IS NULL THEN 0 ELSE 1 END as Marca_corretaje
into #cocorretaje_sn
from #s_iaxis_d a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje) B ON (concat(ltrim(rtrim(a.RAMO_PROD)),'_',ltrim(rtrim(a.poliza)),'_',a.certificado)=B.LLAVE_CERT)

------AND A.documento>=B.documento and A.documento<B.doc_2)


-- ==== [SALVAMENTOS__229] sql/SALVAMENTOS__229/DDL/DB_SQL_Executor__218.sql ====
-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB SQL Executor (#218)
-- Clave      : statement
-- Que hace: calcula parte de los ingresos por venta de salvamentos (bienes recuperados de siniestros).
-- Arma la tabla temporal #si_coco a partir de otras tablas ya calculadas antes en este mismo componente.

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


-- ==== [SALVAMENTOS__229] sql/SALVAMENTOS__229/DDL/DB_SQL_Executor__224.sql ====
-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB SQL Executor (#224)
-- Clave      : statement
-- Que hace: calcula parte de los ingresos por venta de salvamentos (bienes recuperados de siniestros).
-- Arma la tabla temporal #caso1 a partir de otras tablas ya calculadas antes en este mismo componente.

USE Liberty_pruebas_actuaria

/*****************
CASO 1 DE COCORRETAJE interemdiario misma sucursal 
******************/

if OBJECT_ID('tempdb.dbo.#caso1','U') is not null drop table #caso1

select
a.*,
row_number() over(order by ramo_prod) as id,
CASE WHEN b.COD_INTERMEDIARIO IS NULL THEN A.INTERMEDIARIO_LIDE ELSE b.COD_INTERMEDIARIO END AS COD_INTERMEDIARIO,
CASE WHEN b.PARTICIPACION IS NULL THEN 0 ELSE b.PARTICIPACION END  AS PARTICIPACION,
CASE WHEN b.DOCUMENTO IS NULL THEN A.DOCUMENTO ELSE b.DOCUMENTO END AS DOC,
CASE WHEN b.PARTICIPACION IS NULL THEN a.VLR_PAGADO_SAL
	 ELSE a.VLR_PAGADO_SAL  * (b.PARTICIPACION/100) 
END as VLR_PAGADO_SAL_CO,
b.COD_SUCURSAL
into #caso1
from  #si_coco a
left join #corretaje b 
on (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT AND A.documento>=B.documento and A.documento<B.doc_2)
--where
--b.PARTICIPACION is not null


-- ==== [SALVAMENTOS__229] sql/SALVAMENTOS__229/DDL/DB_SQL_Executor__226.sql ====
-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB SQL Executor (#226)
-- Clave      : statement
-- Que hace: calcula parte de los ingresos por venta de salvamentos (bienes recuperados de siniestros).
-- Arma la tabla temporal #salvamentos_iaxis a partir de liberty..
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

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


-- ==== [SALVAMENTOS__229] sql/SALVAMENTOS__229/DDL/DB_SQL_Executor__232.sql ====
-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB SQL Executor (#232)
-- Clave      : statement
-- Que hace: calcula parte de los ingresos por venta de salvamentos (bienes recuperados de siniestros).
-- Arma la tabla temporal #s_as400 a partir de otras tablas ya calculadas antes en este mismo componente.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_Pruebas_Actuaria


--declare
--@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#s_As400','U') is not null drop table #s_as400
SELECT 
a.PERIODO_CONTABLE
,a.sucursal_prod
,c.ramo_contable
,a.ramo_prod
,a.poliza
,a.certificado
,a.documento
,a.ano_siniestro
,a.NRO_RADC_SINIESTRO as radicado
,a.Intermediario_lide
,a.VLR_PAGADO_SAL
,'Salvamentos' AS Concepto_nivel_3
,'INTERFAZ_AUT' as Concepto_nivel_2 
,'CHANGE IN CASE' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
into #s_as400
FROM #salvamentos_As400 a
left join #homologacion_contable c on a.ramo_prod = c.ramo_prod


-- ==== [SALVAMENTOS__229] sql/SALVAMENTOS__229/DDL/DB_SQL_Executor__233.sql ====
-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB SQL Executor (#233)
-- Clave      : statement
-- Que hace: calcula parte de los ingresos por venta de salvamentos (bienes recuperados de siniestros).
-- Arma la tabla temporal #s_as400_d a partir de liberty.apoyo.dwh_sbu_ramo_prod, liberty.apoyo.dwh_profitcenter.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_Pruebas_Actuaria


--declare
--@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#s_As400_d','U') is not null drop table #s_as400_d
SELECT 
a.PERIODO_CONTABLE
,a.sucursal_prod
,a.ramo_contable
,t2.sbu
,a.ramo_prod
,a.poliza
,a.certificado
,a.documento
,a.ano_siniestro
,a.radicado
,a.Intermediario_lide
,a.VLR_PAGADO_SAL
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,'Salvamentos' AS Concepto_nivel_3
,'INTERFAZ_AUT' as Concepto_nivel_2 
,'SALVAMENTOS' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
into #s_as400_d
FROM #s_As400 a
left join 
liberty.apoyo.dwh_sbu_ramo_prod t2 on a.RAMO_PROD = t2.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.RAMO_PROD and a.SUCURSAL_prod = t4.sucursal and a.ramo_contable = t4.ramo_contable


-- ==== [SALVAMENTOS__229] sql/SALVAMENTOS__229/DDL/DB_SQL_Executor__234.sql ====
-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB SQL Executor (#234)
-- Clave      : statement
-- Que hace: calcula parte de los ingresos por venta de salvamentos (bienes recuperados de siniestros).
-- Arma la tabla temporal #s_iaxis a partir de otras tablas ya calculadas antes en este mismo componente.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_Pruebas_Actuaria


--declare
--@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#s_iaxis','U') is not null drop table #s_iaxis
SELECT 
a.PERIODO_CONTABLE
,a.sucursal_prod
,c.ramo_contable
,a.ramo_prod
,a.poliza
,a.certificado
,a.documento
,a.ano_siniestro
,a.Numero_radicado as radicado
,a.Intermediario_lide
,a.VLR_PAGADO_SAL
,'Salvamentos' AS Concepto_nivel_3
,'INTERFAZ_AUT' as Concepto_nivel_2 
,'CHANGE IN CASE' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
into #s_iaxis
FROM #salvamentos_iaxis a
left join #homologacion_contable c on a.ramo_prod = c.ramo_prod


-- ==== [SALVAMENTOS__229] sql/SALVAMENTOS__229/DDL/DB_SQL_Executor__235.sql ====
-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB SQL Executor (#235)
-- Clave      : statement
-- Que hace: calcula parte de los ingresos por venta de salvamentos (bienes recuperados de siniestros).
-- Arma la tabla temporal #s_iaxis_d a partir de liberty.apoyo.dwh_sbu_ramo_prod, liberty.apoyo.dwh_profitcenter.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_Pruebas_Actuaria


--declare
--@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#s_iaxis_d','U') is not null drop table #s_iaxis_d

SELECT 
a.PERIODO_CONTABLE
,a.sucursal_prod
,a.ramo_contable
,t2.sbu
,a.ramo_prod
,a.poliza
,a.certificado
,a.documento
,a.ano_siniestro
,a.radicado
,a.Intermediario_lide
,a.VLR_PAGADO_SAL
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,'Salvamentos' AS Concepto_nivel_3
,'INTERFAZ_AUT' as Concepto_nivel_2 
,'SALVAMENTOS' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
into #s_iaxis_d
FROM #s_iaxis a
left join 
liberty.apoyo.dwh_sbu_ramo_prod t2 on a.RAMO_PROD = t2.ramo_prod 
--left join
--liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.RAMO_PROD and a.SUCURSAL_prod = t4.sucursal and a.ramo_contable = t4.ramo_contable
left join
(select distinct ramo_prod,ramo_contable,cod_profitcenter,desc_profitcenter,cod_sbu_sap,desc_sbu_sap from liberty.apoyo.dwh_profitcenter) t4 on t4.ramo_prod = a.RAMO_PROD and a.ramo_contable = t4.ramo_contable


-- ==== [SALVAMENTOS__229] sql/SALVAMENTOS__229/DDL/DB_SQL_Executor__242.sql ====
-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB SQL Executor (#242)
-- Clave      : statement
-- Que hace: calcula parte de los ingresos por venta de salvamentos (bienes recuperados de siniestros).
-- Arma la tabla temporal #no_coco a partir de otras tablas ya calculadas antes en este mismo componente.

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
,row_number() over(order by ramo_PROD) as id
,INTERMEDIARIO_LIDE AS COD_INTERMEDIARIO
,0 AS PARTICIPACION
,DOCUMENTO AS DOC
,VLR_PAGADO_SAL as VLR_PAGADO_SAL_CO
,SUCURSAL_PROD AS COD_SUCURSAL
into #no_coco
from #cocorretaje_sn c
where marca_corretaje =0


-- ==== [SALVAMENTOS__229] sql/SALVAMENTOS__229/DDL/DB_SQL_Executor__243.sql ====
-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB SQL Executor (#243)
-- Clave      : statement
-- Que hace: calcula parte de los ingresos por venta de salvamentos (bienes recuperados de siniestros).
-- Arma la tabla temporal #cocorretaje_completo a partir de otras tablas ya calculadas antes en este mismo componente.

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
FROM #no_coco
UNION all
SELECT * FROM #caso1
) a


-- ==== [SALVAMENTOS__229] sql/SALVAMENTOS__229/DDL/DB_SQL_Executor__247.sql ====
-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB SQL Executor (#247)
-- Clave      : statement
-- Que hace: calcula parte de los ingresos por venta de salvamentos (bienes recuperados de siniestros).
-- Arma la tabla temporal #si_coco a partir de otras tablas ya calculadas antes en este mismo componente.

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


-- ==== [SALVAMENTOS__229] sql/SALVAMENTOS__229/DDL/DB_SQL_Executor__248.sql ====
-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB SQL Executor (#248)
-- Clave      : statement
-- Que hace: calcula parte de los ingresos por venta de salvamentos (bienes recuperados de siniestros).
-- Arma la tabla temporal #corretaje, #cocorretaje_sn a partir de liberty..

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


-------------------------------------------------



/*********************
Marca Corretaje
*********************/

if OBJECT_ID('tempdb.dbo.#cocorretaje_sn','U') is not null drop table #cocorretaje_sn

select 
a.*
--,b.LLAVE_CERT 
,CASE WHEN B.LLAVE_CERT IS NULL THEN 0 ELSE 1 END as Marca_corretaje
into #cocorretaje_sn
from #s_As400_d a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje) B ON (concat(ltrim(rtrim(a.RAMO_PROD)),'_',ltrim(rtrim(a.poliza)),'_',a.certificado)=B.LLAVE_CERT)

------AND A.documento>=B.documento and A.documento<B.doc_2)


-- ==== [SALVAMENTOS__229] sql/SALVAMENTOS__229/DDL/DB_SQL_Executor__250.sql ====
-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB SQL Executor (#250)
-- Clave      : statement
-- Que hace: calcula parte de los ingresos por venta de salvamentos (bienes recuperados de siniestros).
-- Arma la tabla temporal #caso1 a partir de otras tablas ya calculadas antes en este mismo componente.

USE Liberty_pruebas_actuaria

/*****************
CASO 1 DE COCORRETAJE interemdiario misma sucursal 
******************/

if OBJECT_ID('tempdb.dbo.#caso1','U') is not null drop table #caso1

select
a.*,
row_number() over(order by ramo_prod) as id,
CASE WHEN b.COD_INTERMEDIARIO IS NULL THEN A.INTERMEDIARIO_LIDE ELSE b.COD_INTERMEDIARIO END AS COD_INTERMEDIARIO,
CASE WHEN b.PARTICIPACION IS NULL THEN 0 ELSE b.PARTICIPACION END  AS PARTICIPACION,
CASE WHEN b.DOCUMENTO IS NULL THEN A.DOCUMENTO ELSE b.DOCUMENTO END AS DOC,
CASE WHEN b.PARTICIPACION IS NULL THEN a.VLR_PAGADO_SAL
	 ELSE a.VLR_PAGADO_SAL  * (b.PARTICIPACION/100) 
END as VLR_PAGADO_SAL_CO,
b.COD_SUCURSAL
into #caso1
from  #si_coco a
left join #corretaje b 
on (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT AND A.documento>=B.documento and A.documento<B.doc_2)
--where
--b.PARTICIPACION is not null


-- ==== [SALVAMENTOS__229] sql/SALVAMENTOS__229/DDL/DB_SQL_Executor__253.sql ====
-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB SQL Executor (#253)
-- Clave      : statement
-- Que hace: calcula parte de los ingresos por venta de salvamentos (bienes recuperados de siniestros).
-- Arma la tabla temporal #cocorretaje_completo a partir de otras tablas ya calculadas antes en este mismo componente.

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
FROM #no_coco
UNION all
SELECT * FROM #caso1
) a


-- ==== [SALVAMENTOS__229] sql/SALVAMENTOS__229/DDL/DB_SQL_Executor__254.sql ====
-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB SQL Executor (#254)
-- Clave      : statement
-- Que hace: calcula parte de los ingresos por venta de salvamentos (bienes recuperados de siniestros).
-- Arma la tabla temporal #no_coco a partir de otras tablas ya calculadas antes en este mismo componente.

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
,row_number() over(order by ramo_PROD) as id
,INTERMEDIARIO_LIDE AS COD_INTERMEDIARIO
,0 AS PARTICIPACION
,DOCUMENTO AS DOC
,VLR_PAGADO_SAL as VLR_PAGADO_SAL_CO
,SUCURSAL_PROD AS COD_SUCURSAL
into #no_coco
from #cocorretaje_sn c
where marca_corretaje =0


-- ==== [SALVAMENTOS__229] sql/SALVAMENTOS__229/DML/DB_Query_Reader__222.sql ====
-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB Query Reader (#222)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los ingresos por venta de salvamentos (bienes recuperados de siniestros),
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

select
cast(periodo_contable as int) as PERIODO_CONTABLE
,cast(SUCURSAL_PROD as varchar) as sucursal_prod
,INTERMEDIARIO_LIDE
,SBU
,sum(VLR_PAGADO_SAL) as VALOR_CONCEPTO
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2 
,Concepto_nivel_1 
,Concepto_nivel_0 
from #s_as400_d
group by 
periodo_contable 
,SUCURSAL_PROD
,INTERMEDIARIO_LIDE
,SBU
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2 
,Concepto_nivel_1 
,Concepto_nivel_0


-- ==== [SALVAMENTOS__229] sql/SALVAMENTOS__229/DML/DB_Query_Reader__236.sql ====
-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB Query Reader (#236)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los ingresos por venta de salvamentos (bienes recuperados de siniestros),
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

select
cast(periodo_contable as int) as PERIODO_CONTABLE
,cast(SUCURSAL_PROD as varchar) as sucursal_prod
,INTERMEDIARIO_LIDE
,SBU
,sum(VLR_PAGADO_SAL) as VALOR_CONCEPTO
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2 
,Concepto_nivel_1 
,Concepto_nivel_0 
from #s_iaxis_d
group by 
periodo_contable 
,SUCURSAL_PROD
,INTERMEDIARIO_LIDE
,SBU
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2 
,Concepto_nivel_1 
,Concepto_nivel_0


-- ==== [SALVAMENTOS__229] sql/SALVAMENTOS__229/DML/DB_Query_Reader__238.sql ====
-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB Query Reader (#238)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los ingresos por venta de salvamentos (bienes recuperados de siniestros),
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

select * from #s_iaxis_d


-- ==== [SALVAMENTOS__229] sql/SALVAMENTOS__229/DML/DB_Query_Reader__240.sql ====
-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB Query Reader (#240)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los ingresos por venta de salvamentos (bienes recuperados de siniestros),
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

select * from #s_as400_d


-- ==== [SALVAMENTOS__229] sql/SALVAMENTOS__229/DML/DB_Query_Reader__244.sql ====
-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB Query Reader (#244)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los ingresos por venta de salvamentos (bienes recuperados de siniestros),
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

/*select * from #primas_pyg */

select
* 
--COUNT(*) 
--sum(VALOR_CEDIDO),
--sum(VALOR_CEDIDO_CO)
from #cocorretaje_completo


-- ==== [SALVAMENTOS__229] sql/SALVAMENTOS__229/DML/DB_Query_Reader__246.sql ====
-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB Query Reader (#246)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los ingresos por venta de salvamentos (bienes recuperados de siniestros),
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

/*select * from #primas_pyg */

select
* 
--COUNT(*) 
--sum(VALOR_CEDIDO)
from #no_coco


-- ==== [SALVAMENTOS__229] sql/SALVAMENTOS__229/DML/DB_Query_Reader__249.sql ====
-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB Query Reader (#249)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los ingresos por venta de salvamentos (bienes recuperados de siniestros),
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

/*select * from #primas_pyg */

select
* 
--COUNT(*) 
--sum(VALOR_CEDIDO)
from #si_coco


-- ==== [SALVAMENTOS__229] sql/SALVAMENTOS__229/DML/DB_Query_Reader__252.sql ====
-- Nodo KNIME : P&G_COCO\SALVAMENTOS (#229)\DB Query Reader (#252)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los ingresos por venta de salvamentos (bienes recuperados de siniestros),
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.
-- Nota: profit center: unidad de negocio contable a la que se le atribuye el resultado (ingreso o gasto).
-- Nota: reaseguro: cuando la aseguradora traspasa parte del riesgo (y de la prima o del siniestro) a otra compañia reaseguradora.
-- Nota: salvamento: el valor que se recupera al vender bienes dañados que quedan luego de pagar un siniestro (por ejemplo, un vehiculo chocado).

/*select * from #primas_pyg */

select
* 
--COUNT(*) 
--sum(VALOR_CEDIDO),
--sum(VALOR_CEDIDO_CO)
from #cocorretaje_completo


-- >>> Aqui KNIME ejecuta un nodo "DB Insert (#234)" que hace: INSERT INTO liberty_pruebas_actuaria.dbo.PL_COL_DATOS_COCO SELECT * FROM #no_coco ;
-- >>> NOTA: este INSERT es una reconstruccion/inferencia; el nodo DB Insert de KNIME no tiene script SQL capturado en este repositorio. La tabla temporal final es INCIERTA: el nombre #no_coco se reutiliza varias veces dentro del componente (patron generico de particion cocorretaje/no-cocorretaje) y no es evidente que sea la tabla de resultado consumida por el DB Insert; se tomo la ultima creada por numero de nodo DDL como mejor estimacion.

-- ----------------------------------------------------------------------------
-- COMPONENTE 7/8: RECOBROS (#230) -- Recobros (Recovery)
-- Calcula los recobros a terceros/reaseguro (concepto RECOVERY), con la misma
-- mecanica de temporales y homologacion de profit center que SALVAMENTOS.
-- Escribe en PL_COL_DATOS_COCO mediante el nodo DB Insert (#255).
-- ----------------------------------------------------------------------------
-- ==== [RECOBROS__230] sql/RECOBROS__230/DDL/DB_SQL_Executor__181.sql ====
-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB SQL Executor (#181)
-- Clave      : statement
-- Que hace: calcula parte de los recobros: dinero recuperado de terceros luego de pagar un siniestro.
-- Arma la tabla temporal #recobros_As400 a partir de otras tablas ya calculadas antes en este mismo componente.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_Pruebas_Actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#recobros_As400','U') is not null drop table #recobros_As400

SELECT 
	DTPEKN	AS  PERIODO_CONTABLE
	,CAST(CAST(T01.DTFCPO AS VARCHAR (8)) AS DATE) AS FEC_LEGALIZADO    
	,T01.DTC9NU AS CUPON               
	,T01.DTIGNU AS NRO_INGRESO        
	,T01.DTTNNU AS TRANSACCION         
	,T01.DTCASK AS CIA                 
	,T01.DTRACG AS RAMO_PROD                
	,T01.DTANSN AS ANO_SINIESTRO       
	,T01.DTSCLD AS SUCURSAL_PROD
	,T01.DTRCNU AS NRO_SINIESTRO 
	,T01.DTPZNU AS POLIZA              
	,T01.DTDCNU AS DOCUMENTO           
	,T01.DTCTNU AS CERTIFICADO         
	,T01.DTITCG AS INTERMEDIARIO_LIDE
	,T01.DTVRPO AS VLR_PAGADO_REC            
	,CAST(CAST(T02.YAFCSN AS VARCHAR (8)) AS DATE) AS FECHA_SINIESTRO
	,T03.SBU        
into #recobros_As400
FROM [LIBERTY].[AS400].[REFIGVDT] T01
LEFT JOIN [Liberty].[AS400].[SNFSINIE] T02 ON  (T01.DTRACG = T02.YARACG AND T01.DTANSN = T02.YAANSN AND T01.DTSCLD = T02.YASCPR AND T01.DTRCNU = T02.YARCNU)
LEFT JOIN [Liberty].[APOYO].[DWH_SBU_RAMO_PROD] T03 ON TRIM(T01.DTRACG) = TRIM(T03.RAMO_PROD)
WHERE DTTNNU = 31
AND DTPEKN = @PERIODO_CONTABLE


-- ==== [RECOBROS__230] sql/RECOBROS__230/DDL/DB_SQL_Executor__216.sql ====
-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB SQL Executor (#216)
-- Clave      : statement
-- Que hace: calcula parte de los recobros: dinero recuperado de terceros luego de pagar un siniestro.
-- Arma la tabla temporal #corretaje, #cocorretaje_sn a partir de liberty..

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


-------------------------------------------------



/*********************
Marca Corretaje
*********************/

if OBJECT_ID('tempdb.dbo.#cocorretaje_sn','U') is not null drop table #cocorretaje_sn

select 
a.*
--,b.LLAVE_CERT 
,CASE WHEN B.LLAVE_CERT IS NULL THEN 0 ELSE 1 END as Marca_corretaje
into #cocorretaje_sn
from #r_iaxis_d a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje) B ON (concat(ltrim(rtrim(a.RAMO_PROD)),'_',ltrim(rtrim(a.poliza)),'_',a.certificado)=B.LLAVE_CERT)

------AND A.documento>=B.documento and A.documento<B.doc_2)


-- ==== [RECOBROS__230] sql/RECOBROS__230/DDL/DB_SQL_Executor__218.sql ====
-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB SQL Executor (#218)
-- Clave      : statement
-- Que hace: calcula parte de los recobros: dinero recuperado de terceros luego de pagar un siniestro.
-- Arma la tabla temporal #si_coco a partir de otras tablas ya calculadas antes en este mismo componente.

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


-- ==== [RECOBROS__230] sql/RECOBROS__230/DDL/DB_SQL_Executor__224.sql ====
-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB SQL Executor (#224)
-- Clave      : statement
-- Que hace: calcula parte de los recobros: dinero recuperado de terceros luego de pagar un siniestro.
-- Arma la tabla temporal #caso1 a partir de otras tablas ya calculadas antes en este mismo componente.

USE Liberty_pruebas_actuaria

/*****************
CASO 1 DE COCORRETAJE interemdiario misma sucursal 
******************/

if OBJECT_ID('tempdb.dbo.#caso1','U') is not null drop table #caso1

select
a.*,
row_number() over(order by ramo_prod) as id,
CASE WHEN b.COD_INTERMEDIARIO IS NULL THEN A.INTERMEDIARIO_LIDE ELSE b.COD_INTERMEDIARIO END AS COD_INTERMEDIARIO,
CASE WHEN b.PARTICIPACION IS NULL THEN 0 ELSE b.PARTICIPACION END  AS PARTICIPACION,
CASE WHEN b.DOCUMENTO IS NULL THEN A.DOCUMENTO ELSE b.DOCUMENTO END AS DOC,
CASE WHEN b.PARTICIPACION IS NULL THEN a.VLR_PAGADO_REC
	 ELSE a.VLR_PAGADO_REC  * (b.PARTICIPACION/100) 
END as VLR_PAGADO_REC_CO,
b.COD_SUCURSAL
into #caso1
from  #si_coco a
left join #corretaje b 
on (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT AND A.documento>=B.documento and A.documento<B.doc_2)
--where
--b.PARTICIPACION is not null


-- ==== [RECOBROS__230] sql/RECOBROS__230/DDL/DB_SQL_Executor__226.sql ====
-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB SQL Executor (#226)
-- Clave      : statement
-- Que hace: calcula parte de los recobros: dinero recuperado de terceros luego de pagar un siniestro.
-- Arma la tabla temporal #recobros_iaxis a partir de otras tablas ya calculadas antes en este mismo componente.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_Pruebas_Actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#recobros_iaxis','U') is not null drop table #recobros_iaxis

SELECT 
	substring(cast(IVFECI as varchar(8)),0,7) AS PERIODO_CONTABLE
	,IV$C9N AS Recibo_Caja
	,IVCOIV AS Compañia
	,IVRAMO AS Ramo_prod
	,IVASIN AS Año_Siniestro
	,IVSUCL AS Sucursal_prod
	,IVNRSI AS Numero_Radicado
	,T02.POLIZA AS Poliza
	,T02.CERTIFICADO AS Certificado
	,IVDOCU AS Documento
	,IVNRPA AS Numero_Pagare
	,IVCLVI AS Intermediario_lide
	,IVVRIV AS VLR_PAGADO_REC
	,T02.FECHA_SINIESTRO
	,T02.SBU
into #recobros_iaxis
FROM [LIBERTY].[AS400].[F590475] T01
LEFT JOIN (
SELECT 
	 LLAVE_SIN
	,CAST(CAST(FECHA_SINIESTRO AS VARCHAR (8)) AS DATE) AS FECHA_SINIESTRO
	,POLIZA
	,CERTIFICADO
	,SBU
FROM [Liberty].[SINI].[DWH_S_MAESTRO_D] T1
LEFT JOIN [Liberty].[APOYO].[DWH_SBU_RAMO_PROD] T2 ON T1.RAMO_PROD = T2.RAMO_PROD
WHERE T1.SIS_ORIGEN = 'N') T02 ON CAST(T01.IVNRSI AS INT) = CAST(T02.LLAVE_SIN AS INT)
WHERE IVCTIV IN (531, 539, 532, 540)
AND substring(cast(IVFECI as varchar(8)),0,7) =  @periodo_contable


-- ==== [RECOBROS__230] sql/RECOBROS__230/DDL/DB_SQL_Executor__232.sql ====
-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB SQL Executor (#232)
-- Clave      : statement
-- Que hace: calcula parte de los recobros: dinero recuperado de terceros luego de pagar un siniestro.
-- Arma la tabla temporal #r_as400 a partir de otras tablas ya calculadas antes en este mismo componente.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_Pruebas_Actuaria


--declare
--@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#r_As400','U') is not null drop table #r_as400
SELECT 
a.PERIODO_CONTABLE
,a.sucursal_prod
,c.ramo_contable
,a.ramo_prod
,a.poliza
,a.certificado
,a.ano_siniestro
,a.documento
--,a.NRO_RADC_SINIESTRO as radicado
,a.Intermediario_lide
,a.VLR_PAGADO_REC
,'Recovery' AS Concepto_nivel_3
,'INTERFAZ_AUT' as Concepto_nivel_2 
,'RECOVERY' as Concepto_nivel_1 
,'TOTAL_CLAIMS' as Concepto_nivel_0 
into #r_as400
FROM #recobros_As400 a
left join #homologacion_contable c on a.ramo_prod = c.ramo_prod


-- ==== [RECOBROS__230] sql/RECOBROS__230/DDL/DB_SQL_Executor__233.sql ====
-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB SQL Executor (#233)
-- Clave      : statement
-- Que hace: calcula parte de los recobros: dinero recuperado de terceros luego de pagar un siniestro.
-- Arma la tabla temporal #r_as400_d a partir de liberty.apoyo.dwh_sbu_ramo_prod, liberty.apoyo.dwh_profitcenter.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_Pruebas_Actuaria


--declare
--@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#r_As400_d','U') is not null drop table #r_as400_d
SELECT 
a.PERIODO_CONTABLE
,a.sucursal_prod
,a.ramo_contable
,t2.sbu
,a.ramo_prod
,a.poliza
,a.certificado
,a.ano_siniestro
,a.documento
--,a.radicado
,a.Intermediario_lide
,a.VLR_PAGADO_REC
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2 
,Concepto_nivel_1 
,Concepto_nivel_0 
into #r_as400_d
FROM #r_As400 a
left join 
liberty.apoyo.dwh_sbu_ramo_prod t2 on a.RAMO_PROD = t2.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.RAMO_PROD and a.SUCURSAL_prod = t4.sucursal and a.ramo_contable = t4.ramo_contable


-- ==== [RECOBROS__230] sql/RECOBROS__230/DDL/DB_SQL_Executor__234.sql ====
-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB SQL Executor (#234)
-- Clave      : statement
-- Que hace: calcula parte de los recobros: dinero recuperado de terceros luego de pagar un siniestro.
-- Arma la tabla temporal #r_iaxis a partir de otras tablas ya calculadas antes en este mismo componente.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

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


-- ==== [RECOBROS__230] sql/RECOBROS__230/DDL/DB_SQL_Executor__235.sql ====
-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB SQL Executor (#235)
-- Clave      : statement
-- Que hace: calcula parte de los recobros: dinero recuperado de terceros luego de pagar un siniestro.
-- Arma la tabla temporal #r_iaxis_d a partir de liberty.apoyo.dwh_sbu_ramo_prod, liberty.apoyo.dwh_profitcenter.
-- Usa como filtro el periodo contable (mes/año) que KNIME le pasa como parametro.

USE Liberty_Pruebas_Actuaria


--declare
--@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#r_iaxis_d','U') is not null drop table #r_iaxis_d

SELECT 
a.PERIODO_CONTABLE
,a.sucursal_prod
,a.ramo_contable
,t2.sbu
,a.ramo_prod
,a.poliza
,a.certificado
,a.documento
--,a.ano_siniestro
,a.radicado
,a.Intermediario_lide
,a.VLR_PAGADO_REC
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2 
,Concepto_nivel_1 
,Concepto_nivel_0 
into #r_iaxis_d
FROM #r_iaxis a
left join 
liberty.apoyo.dwh_sbu_ramo_prod t2 on a.RAMO_PROD = t2.ramo_prod 
--left join
--liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.RAMO_PROD and a.SUCURSAL_prod = t4.sucursal and a.ramo_contable = t4.ramo_contable
left join
(select distinct ramo_prod,ramo_contable,cod_profitcenter,desc_profitcenter,cod_sbu_sap,desc_sbu_sap from liberty.apoyo.dwh_profitcenter) t4 on t4.ramo_prod = a.RAMO_PROD and a.ramo_contable = t4.ramo_contable


-- ==== [RECOBROS__230] sql/RECOBROS__230/DDL/DB_SQL_Executor__242.sql ====
-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB SQL Executor (#242)
-- Clave      : statement
-- Que hace: calcula parte de los recobros: dinero recuperado de terceros luego de pagar un siniestro.
-- Arma la tabla temporal #no_coco a partir de otras tablas ya calculadas antes en este mismo componente.

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
,row_number() over(order by ramo_PROD) as id
,INTERMEDIARIO_LIDE AS COD_INTERMEDIARIO
,0 AS PARTICIPACION
,DOCUMENTO AS DOC
,VLR_PAGADO_REC as VLR_PAGADO_SAL_CO
,SUCURSAL_PROD AS COD_SUCURSAL
into #no_coco
from #cocorretaje_sn c
where marca_corretaje =0


-- ==== [RECOBROS__230] sql/RECOBROS__230/DDL/DB_SQL_Executor__243.sql ====
-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB SQL Executor (#243)
-- Clave      : statement
-- Que hace: calcula parte de los recobros: dinero recuperado de terceros luego de pagar un siniestro.
-- Arma la tabla temporal #cocorretaje_completo a partir de otras tablas ya calculadas antes en este mismo componente.

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
FROM #no_coco
UNION all
SELECT * FROM #caso1
) a


-- ==== [RECOBROS__230] sql/RECOBROS__230/DDL/DB_SQL_Executor__247.sql ====
-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB SQL Executor (#247)
-- Clave      : statement
-- Que hace: calcula parte de los recobros: dinero recuperado de terceros luego de pagar un siniestro.
-- Arma la tabla temporal #si_coco a partir de otras tablas ya calculadas antes en este mismo componente.

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


-- ==== [RECOBROS__230] sql/RECOBROS__230/DDL/DB_SQL_Executor__248.sql ====
-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB SQL Executor (#248)
-- Clave      : statement
-- Que hace: calcula parte de los recobros: dinero recuperado de terceros luego de pagar un siniestro.
-- Arma la tabla temporal #corretaje, #cocorretaje_sn a partir de liberty..

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


-------------------------------------------------



/*********************
Marca Corretaje
*********************/

if OBJECT_ID('tempdb.dbo.#cocorretaje_sn','U') is not null drop table #cocorretaje_sn

select 
a.*
--,b.LLAVE_CERT 
,CASE WHEN B.LLAVE_CERT IS NULL THEN 0 ELSE 1 END as Marca_corretaje
into #cocorretaje_sn
from #r_as400_d a
LEFT JOIN (select distinct LLAVE_CERT from #corretaje) B ON (concat(ltrim(rtrim(a.RAMO_PROD)),'_',ltrim(rtrim(a.poliza)),'_',a.certificado)=B.LLAVE_CERT)

------AND A.documento>=B.documento and A.documento<B.doc_2)


-- ==== [RECOBROS__230] sql/RECOBROS__230/DDL/DB_SQL_Executor__250.sql ====
-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB SQL Executor (#250)
-- Clave      : statement
-- Que hace: calcula parte de los recobros: dinero recuperado de terceros luego de pagar un siniestro.
-- Arma la tabla temporal #caso1 a partir de otras tablas ya calculadas antes en este mismo componente.

USE Liberty_pruebas_actuaria

/*****************
CASO 1 DE COCORRETAJE interemdiario misma sucursal 
******************/

if OBJECT_ID('tempdb.dbo.#caso1','U') is not null drop table #caso1

select
a.*,
row_number() over(order by ramo_prod) as id,
CASE WHEN b.COD_INTERMEDIARIO IS NULL THEN A.INTERMEDIARIO_LIDE ELSE b.COD_INTERMEDIARIO END AS COD_INTERMEDIARIO,
CASE WHEN b.PARTICIPACION IS NULL THEN 0 ELSE b.PARTICIPACION END  AS PARTICIPACION,
CASE WHEN b.DOCUMENTO IS NULL THEN A.DOCUMENTO ELSE b.DOCUMENTO END AS DOC,
CASE WHEN b.PARTICIPACION IS NULL THEN a.VLR_PAGADO_REC
	 ELSE a.VLR_PAGADO_REC  * (b.PARTICIPACION/100) 
END as VLR_PAGADO_REC_CO,
b.COD_SUCURSAL
into #caso1
from  #si_coco a
left join #corretaje b 
on (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT AND A.documento>=B.documento and A.documento<B.doc_2)
--where
--b.PARTICIPACION is not null


-- ==== [RECOBROS__230] sql/RECOBROS__230/DDL/DB_SQL_Executor__253.sql ====
-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB SQL Executor (#253)
-- Clave      : statement
-- Que hace: calcula parte de los recobros: dinero recuperado de terceros luego de pagar un siniestro.
-- Arma la tabla temporal #cocorretaje_completo a partir de otras tablas ya calculadas antes en este mismo componente.

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
FROM #no_coco
UNION all
SELECT * FROM #caso1
) a


-- ==== [RECOBROS__230] sql/RECOBROS__230/DDL/DB_SQL_Executor__254.sql ====
-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB SQL Executor (#254)
-- Clave      : statement
-- Que hace: calcula parte de los recobros: dinero recuperado de terceros luego de pagar un siniestro.
-- Arma la tabla temporal #no_coco a partir de otras tablas ya calculadas antes en este mismo componente.

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
,row_number() over(order by ramo_PROD) as id
,INTERMEDIARIO_LIDE AS COD_INTERMEDIARIO
,0 AS PARTICIPACION
,DOCUMENTO AS DOC
,VLR_PAGADO_REC as VLR_PAGADO_SAL_CO
,SUCURSAL_PROD AS COD_SUCURSAL
into #no_coco
from #cocorretaje_sn c
where marca_corretaje =0


-- ==== [RECOBROS__230] sql/RECOBROS__230/DML/DB_Query_Reader__222.sql ====
-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB Query Reader (#222)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los recobros: dinero recuperado de terceros luego de pagar un siniestro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

select
cast(periodo_contable as int) as PERIODO_CONTABLE
,cast(SUCURSAL_PROD as varchar) as sucursal_prod
,INTERMEDIARIO_LIDE
,SBU
,sum(VLR_PAGADO_REC) as VALOR_CONCEPTO
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2 
,Concepto_nivel_1 
,Concepto_nivel_0 
from #r_as400_d
group by 
periodo_contable 
,SUCURSAL_PROD
,INTERMEDIARIO_LIDE
,SBU
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2 
,Concepto_nivel_1 
,Concepto_nivel_0


-- ==== [RECOBROS__230] sql/RECOBROS__230/DML/DB_Query_Reader__236.sql ====
-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB Query Reader (#236)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los recobros: dinero recuperado de terceros luego de pagar un siniestro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

select
cast(periodo_contable as int) as PERIODO_CONTABLE
,cast(SUCURSAL_PROD as varchar) as sucursal_prod
,INTERMEDIARIO_LIDE
,SBU
,sum(VLR_PAGADO_REC) as VALOR_CONCEPTO
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2 
,Concepto_nivel_1 
,Concepto_nivel_0 
from #r_iaxis_d
group by 
periodo_contable 
,SUCURSAL_PROD
,INTERMEDIARIO_LIDE
,SBU
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2 
,Concepto_nivel_1 
,Concepto_nivel_0


-- ==== [RECOBROS__230] sql/RECOBROS__230/DML/DB_Query_Reader__244.sql ====
-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB Query Reader (#244)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los recobros: dinero recuperado de terceros luego de pagar un siniestro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

/*select * from #primas_pyg */

select
* 
--COUNT(*) 
--sum(VALOR_CEDIDO),
--sum(VALOR_CEDIDO_CO)
from #cocorretaje_completo


-- ==== [RECOBROS__230] sql/RECOBROS__230/DML/DB_Query_Reader__246.sql ====
-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB Query Reader (#246)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los recobros: dinero recuperado de terceros luego de pagar un siniestro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

/*select * from #primas_pyg */

select
* 
--COUNT(*) 
--sum(VALOR_CEDIDO)
from #no_coco


-- ==== [RECOBROS__230] sql/RECOBROS__230/DML/DB_Query_Reader__249.sql ====
-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB Query Reader (#249)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los recobros: dinero recuperado de terceros luego de pagar un siniestro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.
-- Nota: SI_COCO / NO_COCO: forma de separar las polizas segun si tienen cocorretaje (varios intermediarios compartiendo la poliza) o no.

/*select * from #primas_pyg */

select
* 
--COUNT(*) 
--sum(VALOR_CEDIDO)
from #si_coco


-- ==== [RECOBROS__230] sql/RECOBROS__230/DML/DB_Query_Reader__252.sql ====
-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB Query Reader (#252)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los recobros: dinero recuperado de terceros luego de pagar un siniestro,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.
-- Nota: cocorretaje: cuando dos o mas intermediarios (corredores/agentes) comparten una misma poliza y cada uno recibe una parte del negocio segun su porcentaje de PARTICIPACION.

/*select * from #primas_pyg */

select
* 
--COUNT(*) 
--sum(VALOR_CEDIDO),
--sum(VALOR_CEDIDO_CO)
from #cocorretaje_completo


-- >>> Aqui KNIME ejecuta un nodo "DB Insert (#255)" que hace: INSERT INTO liberty_pruebas_actuaria.dbo.PL_COL_DATOS_COCO SELECT * FROM #no_coco ;
-- >>> NOTA: este INSERT es una reconstruccion/inferencia; el nodo DB Insert de KNIME no tiene script SQL capturado en este repositorio. La tabla temporal final es INCIERTA: el nombre #no_coco se reutiliza varias veces dentro del componente (patron generico de particion cocorretaje/no-cocorretaje) y no es evidente que sea la tabla de resultado consumida por el DB Insert; se tomo la ultima creada por numero de nodo DDL como mejor estimacion.

-- ----------------------------------------------------------------------------
-- COMPONENTE 8/8: Recobros_sin (#315) -- Descuentos comerciales de siniestros
-- Ajusta el change in case con los descuentos comerciales de siniestros
-- (PL_DESCUENTOS_COMERCIALES_SINIESTROS). Depende de CHANGE_IN_CA (#34).
-- Escribe en PL_COL_DATOS_COCO mediante el nodo DB Insert (#312) y ADEMAS hace
-- un INSERT INTO directo por SQL hacia PL_COL_DATOS_COCO_UNIFICADO_RC.
-- ----------------------------------------------------------------------------
-- ==== [Recobros_sin__315] sql/Recobros_sin__315/DDL/DB_SQL_Executor__313.sql ====
-- Nodo KNIME : P&G_COCO\Recobros_sin (#315)\DB SQL Executor (#313)
-- Clave      : statement
-- Que hace: calcula parte de los descuentos comerciales aplicados sobre siniestros.
-- Arma la tabla temporal #recobros a partir de LIBERTY_PRUEBAS_ACTUARIA.DBO.PL_Descuentos_comerciales_siniestros, liberty_pruebas_actuaria.dbo.PnL_Homologa_profit.

USE Liberty_pruebas_actuaria

DROP TABLE #RECOBROS

select 
t1.*
,coalesce(/*pc1.mapped_sapprofitcenter,*/ pc2.mapped_sapprofitcenter, pc3.mapped_sapprofitcenter, pc4.mapped_sapprofitcenter, pc5.mapped_sapprofitcenter, pc6.mapped_sapprofitcenter, pc7.mapped_sapprofitcenter, pc8.mapped_sapprofitcenter, pc9.mapped_sapprofitcenter) Profit_nuevo
,coalesce(/*pc1.[description],*/ pc2.[description], pc3.[description], pc4.[description], pc5.[description], pc6.[description], pc7.[description], pc8.[description], pc9.[description]) Descripcion_profit
,coalesce(/*pc1.[description],*/ pc2.lob_g1, pc3.lob_g1, pc4.lob_g1, pc5.lob_g1, pc6.lob_g1, pc7.lob_g1, pc8.lob_g1, pc9.lob_g1) LOB_SAP
into #recobros
from  LIBERTY_PRUEBAS_ACTUARIA.DBO.PL_Descuentos_comerciales_siniestros t1
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit  where opcion = 1) pc1
	on t1.ramo_contable = pc1.ramo_contable
	and t1.SPRODUC = pc1.ramo_producto_tecnico
	and t1.sucursal_prod = pc1.sucursal_contable
	and t1.vehicle_use_class_code = pc1.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit  where opcion = 2) pc2
	on t1.ramo_contable = pc2.ramo_contable
	and t1.SPRODUC = pc2.ramo_producto_tecnico
	and t1.sucursal_prod = pc2.sucursal_contable
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit  where opcion = 3) pc3
	on t1.ramo_contable = pc3.ramo_contable
	and t1.SPRODUC = pc3.ramo_producto_tecnico
	and t1.vehicle_use_class_code = pc3.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit  where opcion = 4) pc4
	on t1.ramo_contable = pc4.ramo_contable
	and t1.sucursal_prod = pc4.sucursal_contable
	and t1.vehicle_use_class_code = pc4.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit  where opcion = 5) pc5
	on t1.ramo_contable = pc5.ramo_contable
	and t1.vehicle_use_class_code = pc5.modalidad
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit where opcion = 6) pc6
	on t1.ramo_contable = pc6.ramo_contable
	and t1.sucursal_prod = pc6.sucursal_contable
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit  where opcion = 7) pc7
	on t1.ramo_contable = pc7.ramo_contable
	and t1.SPRODUC = pc7.ramo_producto_tecnico
left join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit  where opcion = 8) pc8
	on t1.ramo_contable = pc8.ramo_contable
cross join (select * from liberty_pruebas_actuaria.dbo.PnL_Homologa_profit  where opcion = 9) pc9


-- ==== [Recobros_sin__315] sql/Recobros_sin__315/DDL/DB_SQL_Executor__315.sql ====
-- Nodo KNIME : P&G_COCO\Recobros_sin (#315)\DB SQL Executor (#315)
-- Clave      : statement
-- Que hace: calcula parte de los descuentos comerciales aplicados sobre siniestros.
-- Arma la tabla temporal #recobros2 a partir de liberty.apoyo.dwh_sbu_ramo_prod.
-- Nota: PARTICIPACION: el porcentaje que le corresponde a cada intermediario sobre una poliza compartida.
-- Nota: SBU: segmento/unidad estrategica de negocio usada para agrupar ramos.
-- Nota: change in case (o CHANGE_IN_CA): la variacion, entre un periodo y otro, del valor estimado que se espera pagar por los siniestros abiertos.

USE Liberty_pruebas_actuaria

drop table #recobros2
SELECT  
getdate() as create_at,
PERIODO_CONTABLE,
SPRODUC as ramo_prod,
npoliza as poliza,
b.SBU,
[dbo].[F_Conv_Cod_Agente](CAGENTE) as INTERMEDIARIO_LIDE,
Profit_nuevo as cod_profitcenter,
Descripcion_profit as desc_profitcenter,
SUBSTRING(LOB_SAP, 1, charindex('-', LOB_SAP)-1) as cod_sbu_sap ,
SUBSTRING(LOB_SAP, charindex('-', LOB_SAP)+1, len(LOB_SAP)) as desc_sbu_sap,
'Recobros_comerciales' as Concepto_nivel_3,
'Interfaz_automatica' as Concepto_nivel_2,
'Change in CASE' as Concepto_nivel_1,
'TOTAL_CLAIMS' AS Concepto_nivel_0,
0 as Marca_corretaje,
[dbo].[F_Conv_Cod_Agente](CAGENTE) as COD_INTERMEDIARIO,
0 as PARTICIPACION,
sucursal_prod AS COD_SUCURSAL,
sucursal_prod AS SUC_CONT,
NULL AS Business_Area,
NULL AS Business_Area_Des,
NULL AS Channel,	
NULL AS Channel_Des,
NULL AS Tipo_Canal,
NULL AS Canal_comercial,
NULL AS Regional_comercial,
NULL AS Sucursal_comercial,
NULL AS Sucursal_plan_comercial,
sum(CONVERT(INT,VALOR_FINAL)) AS VALOR_CONCEPTO,
0 AS exc_consurso,
vehicle_use_class_code AS  MODALIDAD,
'' AS AGRUPADOR,
NULL AS TIPO_RIESGO,
NULL AS CANAL_HOMOLOGADO,
NULL AS SUB_CANAL_HOMOLOGADO,
NULL AS Regional_homologada,
NULL AS Sucursal_fusion_homologada,
NULL AS Sucursal_homologada,
NULL AS INTERMEDIARIO_HOMOLOGADO,
NULL AS TIPO_DOC_TOMADOR,
NULL AS DOCUMENTO_TOMADOR,
NULL AS TOMADOR,
'HDISC' AS COMPANIA,
NULL AS COD_CLAVE_LIDER,
0 AS TRASLADO,	
NULL AS INTERMEDIARIO_INICIAL_TRASLADO,
NULL AS SUC_INICIAL_TRASLADOS,
NULL AS INTERMEDIARIO_FINAL_TRASLADOS,
NULL AS SUC_FINAL_TRASLADOS,
NULL AS EXC_FACULTATIVO,
NULL AS EXC_LICITACIONES,
NULL AS EXC_REFERIDOS
,null as MACRORAMO
,null as GERENCIA
,NULL AS LOB_TALANX
INTO #recobros2
FROM #recobros a
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on SPRODUC = b.ramo_prod 
group by 
PERIODO_CONTABLE
,SPRODUC 
,npoliza
,b.SBU
,CAGENTE
,Profit_nuevo 
,Descripcion_profit 
,LOB_SAP
,sucursal_prod
,vehicle_use_class_code


-- ==== [Recobros_sin__315] sql/Recobros_sin__315/DML/DB_SQL_Executor__314.sql ====
-- Nodo KNIME : P&G_COCO\Recobros_sin (#315)\DB SQL Executor (#314)
-- Clave      : statement
-- Que hace: consulta (lee) los resultados ya calculados para los descuentos comerciales aplicados sobre siniestros,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

USE Liberty_pruebas_actuaria

insert into liberty_pruebas_actuaria.dbo.PL_COL_DATOS_COCO_UNIFICADO_RC

SELECT  
a.*
from #recobros2 a


-- ==== [Recobros_sin__315] sql/Recobros_sin__315/DML/DB_Query_Reader__316.sql ====
-- Nodo KNIME : P&G_COCO\Recobros_sin (#315)\DB Query Reader (#316)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los descuentos comerciales aplicados sobre siniestros,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.

SELECT *FROM #recobros


-- ==== [Recobros_sin__315] sql/Recobros_sin__315/DML/DB_Query_Reader__317.sql ====
-- Nodo KNIME : P&G_COCO\Recobros_sin (#315)\DB Query Reader (#317)
-- Clave      : sql_statement
-- Que hace: consulta (lee) los resultados ya calculados para los descuentos comerciales aplicados sobre siniestros,
-- dejandolos listos para que KNIME los tome y los inserte en la tabla final.
-- Nota: recobro (recovery): dinero que la aseguradora recupera de terceros responsables despues de haber pagado un siniestro.

SELECT *FROM #recobros2


-- >>> Aqui KNIME ejecuta un nodo "DB Insert (#312)" que hace: INSERT INTO liberty_pruebas_actuaria.dbo.PL_COL_DATOS_COCO SELECT * FROM #recobros2 ;
-- >>> NOTA: este INSERT es una reconstruccion/inferencia; el nodo DB Insert de KNIME no tiene script SQL capturado en este repositorio.
-- >>> NOTA ADICIONAL: este componente TAMBIEN inserta directamente (via script SQL, no nodo DB Insert) en liberty_pruebas_actuaria.dbo.PL_COL_DATOS_COCO_UNIFICADO_RC -- ver DB_SQL_Executor__314.sql (DML) mas arriba, que ya contiene el INSERT INTO explicito.
