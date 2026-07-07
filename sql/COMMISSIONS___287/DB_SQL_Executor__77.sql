-- Nodo KNIME : P&G_COCO\COMMISSIONS_ (#287)\DB SQL Executor (#77)
-- Clave      : statement

USE Liberty_pruebas_actuaria



declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#reaseguro','U') is not null drop table #reaseguro



select
a.periodo as PERIODO_CONTABLE
,b.sbu as SBU
,a.SUCURSAL_PROD as SUCURSAL_PROD
,A.SUCURSAL_CONTABLE
,a.CODIGO_RAMO_PRODUCTO AS RAMO_PROD
,a.ramo_contable
,a.MDPZA AS poliza
,a.MDCTD AS certificado 
,a.cuenta_LOCAL
,a.subcuenta_local
,a.DESCRIPCION_CUENTA_SUB
,case when A.libro = 'AA' THEN A.AGENTE_LIDER ELSE [dbo].[F_Conv_Cod_Agente](a.AGENTE_LIDER) END AS INTERMEDIARIO_LIDE
,sum(cast(VALOR_RUBRO as float))*-1 as VALOR_REASEGURO
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,'Comision_reaseguro' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'COMMISSION EXPENSE' AS Concepto_nivel_1
,'COMMISSION EXPENSE' AS Concepto_nivel_0
into #reaseguro
from LIBERTY.[MIDDLEWARE].[DWH_REASEGURO_H] a
--left join
--liberty.prod.dwh_polizas_h t3 on t1.llave = t3.llave Validar cruce modalidad
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.CODIGO_RAMO_PRODUCTO = b.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.CODIGO_RAMO_PRODUCTO and t4.sucursal = a.SUCURSAL_PROD and t4.ramo_contable = a.ramo_contable
WHERE a.periodo= @periodo_contable   and cuenta_local in (411631,
411655,
511677
) AND SUBCUENTA_LOCAL in (101,102,106,107,108,111,115,301,302,303,304,305
,306,307,308,309,310,311,312,315,316,317,320,322,324,325,327,400,401,402
,403,404,405,406,407,408,411,412,413,418,425,102)
group by
a.periodo
,b.sbu
,a.libro
,a.SUCURSAL_PROD
,A.SUCURSAL_CONTABLE
,a.CODIGO_RAMO_PRODUCTO
,a.ramo_contable
,a.MDPZA 
,a.MDCTD
,a.AGENTE_LIDER
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,a.cuenta_LOCAL
,a.subcuenta_local
,a.DESCRIPCION_CUENTA_SUB
