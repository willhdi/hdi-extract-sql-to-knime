-- Nodo KNIME : P&G_COCO\Recobros_sin (#315)\DB SQL Executor (#313)
-- Clave      : statement

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
