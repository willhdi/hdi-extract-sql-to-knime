-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#320)\DB SQL Executor (#17)
-- Clave      : statement

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
