-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#64)\DB SQL Executor (#287)
-- Clave      : statement

USE Liberty_Pruebas_Actuaria

if OBJECT_ID('tempdb.dbo.#Final_dir_terr','U') is not null drop table #Final_dir_terr

select LLAVE,
PERIODO_CONTABLE
,SUCURSAL_PROD
,trim(RAMO_PROD) as RAMO_PROD
,POLIZA
,CERTIFICADO
,DOCUMENTO
,SBU
,INTERMEDIARIO_LIDE
,cod_profitcenter2 as cod_profitcenter
,desc_profitcenter2 as desc_profitcenter
,SUBSTRING(LOB, 1, charindex('-', LOB)-1) as cod_sbu_sap 
,SUBSTRING(LOB, charindex('-', LOB)+1, len(LOB))  as desc_sbu_sap
,sum(valor_res) as Change
--,modalidad
---,sum(RRCNC) RRCNC
--,LAG(sum(isnull(RRCNC,0)), 1,0) OVER (PARTITION BY LLAVE  ORDER BY LLAVE,PERIODO_CONTABLE)-sum(isnull(RRCNC,0)) AS Change
into #Final_dir_terr
from  #profit2
group by 
LLAVE,
PERIODO_CONTABLE,
SBU,
SUCURSAL_PROD,
RAMO_CONTABLE,
trim(RAMO_PROD),
POLIZA,
CERTIFICADO,
DOCUMENTO,
INTERMEDIARIO_LIDE,
cod_profitcenter2,
desc_profitcenter2,
LOB
--modalidad
