-- Nodo KNIME : P&G_COCO\COMMISSIONS (#278)\DB SQL Executor (#77)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#reaseguro','U') is not null drop table #reaseguro


select
a.periodo_contable as PERIODO_CONTABLE
,b.sbu as SBU
,a.sucursal as SUCURSAL_PROD
,a.RAMO_PROD
,a.ramo_contable
,a.poliza
,a.riesgo as certificado
,a.n_movimiento
,a.nombre_reasegurador
,a.tipo_reaseguro
,[dbo].[F_Conv_Cod_Agente](a.AGENTE) as INTERMEDIARIO_LIDE
,case when a.periodo_contable=a.periodo_contable_ANALISIS then sum(valor_comision_reaseguro) else 0 end as VALOR_REASEGURO --VALOR_CAUSACION
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,'Causacion_reaseguro' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'COMMISSION EXPENSE' AS Concepto_nivel_1
,'COMMISSION EXPENSE' AS Concepto_nivel_0
into #reaseguro
from liberty.amocom.REASEGURO a
--left join
--liberty.prod.dwh_polizas_h t3 on t1.llave = t3.llave Validar cruce modalidad
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.ramo_prod = b.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.ramo_prod and t4.sucursal = a.sucursal and t4.ramo_contable = a.ramo_contable
WHERE a.periodo_contable = @periodo_contable and a.fuente = 'L' and a.agente is not null
group by
a.periodo_contable 
,a.periodo_contable_ANALISIS
,b.sbu
,a.sucursal
,a.RAMO_PROD
,a.ramo_contable
,a.poliza
,a.riesgo
,a.n_movimiento
,a.nombre_reasegurador
,a.tipo_reaseguro
,[dbo].[F_Conv_Cod_Agente](a.AGENTE)
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap

union all


select
a.periodo_contable as PERIODO_CONTABLE
,b.sbu as SBU
,a.sucursal as SUCURSAL_PROD
,a.RAMO_PROD
,a.ramo_contable
,a.poliza
,a.riesgo as certificado
,a.n_movimiento
,a.nombre_reasegurador
,a.tipo_reaseguro
,p.INTERMEDIARIO_LIDE
,case when a.periodo_contable=a.periodo_contable_ANALISIS then sum(valor_comision_reaseguro) else 0 end as VALOR_REASEGURO --VALOR_CAUSACION
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,'Causacion_reaseguro' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'COMMISSION EXPENSE' AS Concepto_nivel_1
,'COMMISSION EXPENSE' AS Concepto_nivel_0
from liberty.amocom.REASEGURO a
--left join
--liberty.prod.dwh_polizas_h t3 on t1.llave = t3.llave Validar cruce modalidad
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.ramo_prod = b.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.ramo_prod and t4.sucursal = a.sucursal and t4.ramo_contable = a.ramo_contable
left join 
	(select  distinct ramo_prod,poliza,documento,intermediario_lide from liberty.prod.dwh_polizas_h) p on a.ramo_prod = p.ramo_prod and a.poliza = p.poliza and a.n_movimiento = p.documento
WHERE a.periodo_contable = @periodo_contable and a.fuente = 'L' and a.agente is null
group by
a.periodo_contable 
,a.periodo_contable_ANALISIS
,b.sbu
,a.sucursal
,a.RAMO_PROD
,a.ramo_contable
,a.poliza
,a.riesgo
,a.n_movimiento
,a.nombre_reasegurador
,a.tipo_reaseguro
,p.intermediario_lide
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap

UNION ALL

---USAR CUANDO EXISTA ALGÚN MANUAL ADICIONAL EN CONTABILIDAD
--select
--a.periodo_contable as PERIODO_CONTABLE
--,b.sbu as SBU
--,a.sucursal as SUCURSAL_PROD
--,a.RAMO_PROD
--,a.ramo_contable
--,a.poliza
--,a.riesgo as certificado
--,a.n_movimiento as documento
--,a.nombre_reasegurador
--,a.tipo_reaseguro
--,[dbo].[F_Conv_Cod_Agente](a.AGENTE) as INTERMEDIARIO_LIDE
--,case when a.periodo_contable=a.periodo_contable_ANALISIS then sum(valor_comision_reaseguro) else 0 end as VALOR_REASEGURO --VALOR_CAUSACION
--,t4.cod_profitcenter
--,t4.desc_profitcenter
--,t4.cod_sbu_sap
--,t4.desc_sbu_sap
--,'Causacion_reaseguro_iaxis' AS Concepto_nivel_3
--,'INTERFAZ_AUT' AS Concepto_nivel_2
--,'COMMISSION EXPENSE' AS Concepto_nivel_1
--,'COMMISSION EXPENSE' AS Concepto_nivel_0
--from liberty.amocom.REASEGURO a
----left join
----liberty.prod.dwh_polizas_h t3 on t1.llave = t3.llave --Validar cruce modalidad
--left join 
--liberty.apoyo.dwh_sbu_ramo_prod b on a.ramo_prod = b.ramo_prod 
--left join
--liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.ramo_prod and t4.sucursal = a.sucursal and t4.ramo_contable = a.ramo_contable
--WHERE a.periodo_contable = @periodo_contable and a.fuente = 'B' and a.agente is not null
--group by
--a.periodo_contable 
--,a.periodo_contable_ANALISIS
--,b.sbu
--,a.sucursal
--,a.RAMO_PROD
--,a.ramo_contable
--,a.poliza
--,a.riesgo
--,n_movimiento
--,a.nombre_reasegurador
--,a.tipo_reaseguro
--,[dbo].[F_Conv_Cod_Agente](a.AGENTE)
--,t4.cod_profitcenter
--,t4.desc_profitcenter
--,t4.cod_sbu_sap
--,t4.desc_sbu_sap

----union all

select
a.periodo_contable_analisis as PERIODO_CONTABLE
,b.sbu as SBU
,a.sucursal as SUCURSAL_PROD
,a.RAMO_PROD
,a.ramo_contable
,a.poliza
,a.riesgo as certificado
,n_movimiento as documento
,a.nombre_reasegurador
,a.tipo_reaseguro
,[dbo].[F_Conv_Cod_Agente](a.AGENTE) as INTERMEDIARIO_LIDE
,sum(A.COMISION_AMORTIZADO_MES) as VALOR_REASEGURO --VALOR_COMISION_REASEGURO
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,'Comisiones_reaseguro' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'COMMISSION EXPENSE' AS Concepto_nivel_1
,'COMMISSION EXPENSE' AS Concepto_nivel_0
from liberty.amocom.REASEGURO a
--left join
--liberty.prod.dwh_polizas_h t3 on t1.llave = t3.llave Validar cruce modalidad
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.ramo_prod = b.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.ramo_prod and t4.sucursal = a.sucursal and t4.ramo_contable = a.ramo_contable
WHERE a.periodo_contable_analisis = @periodo_contable and a.agente is not null
group by
a.periodo_contable_analisis 
,b.sbu
,a.sucursal
,a.RAMO_PROD
,a.ramo_contable
,a.poliza
,a.riesgo
,a.n_movimiento
,a.nombre_reasegurador
,a.tipo_reaseguro
,[dbo].[F_Conv_Cod_Agente](a.AGENTE)
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap

union all


select
a.periodo_contable_analisis as PERIODO_CONTABLE
,b.sbu as SBU
,a.sucursal as SUCURSAL_PROD
,a.RAMO_PROD
,a.ramo_contable
,a.poliza
,a.riesgo as certificado
,a.n_movimiento
,a.nombre_reasegurador
,a.tipo_reaseguro
,p.INTERMEDIARIO_LIDE
,sum(A.COMISION_AMORTIZADO_MES) as VALOR_REASEGURO --VALOR_COMISION_REASEGURO
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,'Comisiones_reaseguro' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'COMMISSION EXPENSE' AS Concepto_nivel_1
,'COMMISSION EXPENSE' AS Concepto_nivel_0
from liberty.amocom.REASEGURO a
--left join
--liberty.prod.dwh_polizas_h t3 on t1.llave = t3.llave Validar cruce modalidad
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.ramo_prod = b.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.ramo_prod and t4.sucursal = a.sucursal and t4.ramo_contable = a.ramo_contable
left join 
	(select  distinct ramo_prod,poliza,documento,intermediario_lide from liberty.prod.dwh_polizas_h) p on a.ramo_prod = p.ramo_prod and a.poliza = p.poliza and a.n_movimiento = p.documento
WHERE a.periodo_contable_analisis = @periodo_contable and  a.agente is  null
group by
a.periodo_contable_analisis 
,b.sbu
,a.sucursal
,a.RAMO_PROD
,a.ramo_contable
,a.poliza
,a.riesgo
,a.n_movimiento
,a.nombre_reasegurador
,a.tipo_reaseguro
,p.INTERMEDIARIO_LIDE
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
