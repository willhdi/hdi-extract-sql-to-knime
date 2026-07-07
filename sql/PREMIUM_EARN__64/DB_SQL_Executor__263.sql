-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#64)\DB SQL Executor (#263)
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
,cod_profitcenter
,desc_profitcenter
,SUBSTRING(LOB, 1, charindex('-', LOB)-1) as cod_sbu_sap 
,SUBSTRING(LOB, charindex('-', LOB)+1, len(LOB))  as desc_sbu_sap
,sum(change) as change
--,sum(RRCNC) RRCNC
--,LAG(sum(isnull(RRCNC,0)), 1,0) OVER (PARTITION BY LLAVE  ORDER BY LLAVE,PERIODO_CONTABLE)-sum(isnull(RRCNC,0)) AS Change
into #Final_cedidas
from  #profit4
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
LOB
