-- Nodo KNIME : P&G_COCO\COMMISSIONS_ (#287)\DB SQL Executor (#214)
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
,a.COD_SUCURSAL
,a.COD_INTERMEDIARIO_LIDER	
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
WHERE a.periodo_contable = @periodo_contable
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
