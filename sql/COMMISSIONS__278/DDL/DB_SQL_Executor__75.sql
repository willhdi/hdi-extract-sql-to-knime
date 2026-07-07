-- Nodo KNIME : P&G_COCO\COMMISSIONS (#278)\DB SQL Executor (#75)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#retorno','U') is not null drop table #retorno



select
a.periodo_contable_analisis as PERIODO_CONTABLE
,b.sbu as SBU
,a.sucursal as SUCURSAL_PROD
,a.RAMO_PROD
,a.ramo_contable
,a.poliza
,a.certificado
,a.recibo
,a.NRO_ID_BENEFICIARIO
,a.RAZON_SOCIAL_BENEFICIARIO
,a.tipo_retorno
,[dbo].[F_Conv_Cod_Agente](a.CAGENTE) as INTERMEDIARIO_LIDE
,sum(a.VALOR_MENSUAL_RETORNO) * -1 as VALOR_RETORNO
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,'Retornos' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'COMMISSION EXPENSE' AS Concepto_nivel_1
,'COMMISSION EXPENSE' AS Concepto_nivel_0
into #retorno
from liberty.amocom.retornos a
--left join
--liberty.prod.dwh_polizas_h t3 on t1.llave = t3.llave Validar cruce modalidad
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.ramo_prod = b.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.ramo_prod and t4.sucursal = a.sucursal and t4.ramo_contable = a.ramo_contable
WHERE a.periodo_contable_analisis = @periodo_contable
group by
a.periodo_contable_analisis 
,b.sbu
,a.sucursal
,a.RAMO_PROD
,a.ramo_contable
,a.poliza
,a.certificado
,a.recibo
,a.NRO_ID_BENEFICIARIO
,a.RAZON_SOCIAL_BENEFICIARIO
,a.tipo_retorno
,[dbo].[F_Conv_Cod_Agente](a.CAGENTE)
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
