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
