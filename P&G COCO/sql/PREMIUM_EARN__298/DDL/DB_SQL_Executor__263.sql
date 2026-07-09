-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#298)\DB SQL Executor (#263)
-- Clave      : statement

USE Liberty_Pruebas_Actuaria

if OBJECT_ID('tempdb.dbo.#Final_cedidas','U') is not null drop table #Final_cedidas

select 
PERIODO_CONTABLE,
SBU,
SUCURSAL_PROD,
RAMO_CONTABLE,
trim(RAMO_PROD) as RAMO_PROD,
POLIZA,
CERTIFICADO,
DOCUMENTO,
INTERMEDIARIO_LIDE
, Concepto_nivel_3
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,sum(change)*-1 as change
--,sum(RRCNC) RRCNC
--,LAG(sum(isnull(RRCNC,0)), 1,0) OVER (PARTITION BY LLAVE  ORDER BY LLAVE,PERIODO_CONTABLE)-sum(isnull(RRCNC,0)) AS Change
into #Final_cedidas
from  #com_reserva_inicial_cedidas
group by 
PERIODO_CONTABLE,
SBU,
SUCURSAL_PROD,
RAMO_CONTABLE,
trim(RAMO_PROD),
POLIZA,
CERTIFICADO,
DOCUMENTO,
INTERMEDIARIO_LIDE,
cod_profitcenter,
desc_profitcenter,
cod_sbu_sap,
desc_sbu_sap,
Concepto_nivel_3
