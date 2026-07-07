-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#280)
-- Clave      : statement

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
