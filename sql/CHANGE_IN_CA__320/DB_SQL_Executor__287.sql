-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB SQL Executor (#287)
-- Clave      : statement

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
