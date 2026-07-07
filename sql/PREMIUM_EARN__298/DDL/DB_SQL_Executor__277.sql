-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#298)\DB SQL Executor (#277)
-- Clave      : statement

USE Liberty_Pruebas_Actuaria

if OBJECT_ID('tempdb.dbo.#Final_tcc','U') is not null drop table #Final_tcc

select LLAVE,
PERIODO_CONTABLE_ANALISIS,
SUCURSAL_PROD,
RAMO_CONTABLE,
trim(RAMO_PROD) as RAMO_PROD,
POLIZA,
CERTIFICADO,
DOCUMENTO,
INTERMEDIARIO_LIDE,
sum(valor_res) as VALOR_CONCEPTO
--LAG(sum(isnull(RRCNC,0)), 1,0) OVER (PARTITION BY LLAVE  ORDER BY LLAVE,PERIODO_CONTABLE_ANALISIS)-sum(isnull(RRCNC,0)) AS Change
into #Final_tcc
from  #RT_reserva_comisiones_cedida_terremoto
group by 
LLAVE,
PERIODO_CONTABLE_ANALISIS,
SUCURSAL_PROD,
RAMO_CONTABLE,
DOCUMENTO,
trim(RAMO_PROD),
POLIZA,
CERTIFICADO,
INTERMEDIARIO_LIDE
