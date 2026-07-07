-- Nodo KNIME : P&G_COCO\COMMISSIONS (#278)\DB SQL Executor (#76)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#directa','U') is not null drop table #directa

---DIRECTA

select
a.periodo_contable_analisis as PERIODO_CONTABLE
,b.sbu as SBU
,a.SUCURSAL_PROD
,a.RAMO_PROD
,a.ramo_contable
,a.poliza
,a.certificado
,a.documento
,a.fi_documento
,a.ff_documento
,a.INTERMEDIARIO_LIDE
,sum(VALOR_MENSUAL_COMISION_BAS_COA + VALOR_MENSUAL_COMISION_WEB_COA)*-1 as VALOR_COMISION
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,'Comision_intermediacion' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'COMMISSION EXPENSE' AS Concepto_nivel_1
,'COMMISSION EXPENSE' AS Concepto_nivel_0
into #directa
from liberty.amocom.directa a
--left join
--liberty.prod.dwh_polizas_h t3 on t1.llave = t3.llave Validar cruce modalidad
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.ramo_prod = b.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.ramo_prod and t4.sucursal = a.sucursal_prod and t4.ramo_contable = a.ramo_contable
WHERE a.periodo_contable_analisis = @periodo_contable   and tipo_coaseguro <> 'A' 
group by
a.periodo_contable_analisis 
,b.sbu
,a.sucursal_prod
,a.RAMO_PROD
,a.ramo_contable
,a.poliza
,a.certificado
,a.documento
,a.fi_documento
,a.ff_documento
,a.INTERMEDIARIO_LIDE
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap

UNION ALL
--DIRECTA COASEGURO
select
a.periodo_contable_analisis as PERIODO_CONTABLE
,b.sbu as SBU
,a.SUCURSAL_PROD
,a.RAMO_PROD
,a.ramo_contable
,a.poliza
,a.certificado
,A.DOCUMENTO
,a.fi_documento
,a.ff_documento
,a.INTERMEDIARIO_LIDE
,sum(VALOR_MENSUAL_COMISION_BAS_COA + VALOR_MENSUAL_COMISION_WEB_COA)*-1 as VALOR_COMISION
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,'Comision_coaseguro' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'COMMISSION EXPENSE' AS Concepto_nivel_1
,'COMMISSION EXPENSE' AS Concepto_nivel_0
from liberty.amocom.directa a
--left join
--liberty.prod.dwh_polizas_h t3 on t1.llave = t3.llave Validar cruce modalidad
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.ramo_prod = b.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.ramo_prod and t4.sucursal = a.sucursal_prod and t4.ramo_contable = a.ramo_contable
WHERE a.periodo_contable_analisis = @periodo_contable and tipo_coaseguro = 'A' 
group by
a.periodo_contable_analisis 
,b.sbu
,a.sucursal_prod
,a.RAMO_PROD
,a.ramo_contable
,a.poliza
,a.certificado
,a.documento
,a.fi_documento
,a.ff_documento
,a.INTERMEDIARIO_LIDE
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
