-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#218)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/************************
Separamos casos  si
**************************/

if OBJECT_ID('tempdb.dbo.#si_coco','U') is not null drop table #si_coco

select 
periodo_contable ,
--ANNO_SINIESTRO,
--RADICACION,
SUCURSAL_PROD,
RAMO_PROD,
POLIZA,
CERTIFICADO,
CASE WHEN DOCUMENTO = 0 THEN 1 ELSE DOCUMENTO END AS DOCUMENTO,
intermediario_lide,
SBU,
ramo_contable,
VALOR_CONCEPTO,
cod_profitcenter,
desc_profitcenter,
cod_sbu_sap,
desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2 
,Concepto_nivel_1 
,Concepto_nivel_0 
,Marca_corretaje
into #si_coco
from #cocorretaje_sn_sin
where marca_corretaje =1



--select *  
--into #si_coco
--from #cocorretaje_sn
--where cocorretaje =1
