-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#64)\DB SQL Executor (#261)
-- Clave      : statement

USE Liberty_Pruebas_Actuaria

if OBJECT_ID('tempdb.dbo.#Final_s','U') is not null drop table #Final_s

select LLAVE,
PERIODO_CONTABLE_ANALISIS as PERIODO_CONTABLE,
SUCURSAL_PROD,
--RAMO_CONTABLE,
trim(RAMO_PROD) as RAMO_PROD,
POLIZA,
CERTIFICADO,
--documento,
cod_profitcenter,
INTERMEDIARIO_LIDE,
fi_certificado,
ff_certificado,
sum(change) as VALOR_CONCEPTO
--LAG(sum(isnull(RRCNC,0)), 1,0) OVER (PARTITION BY LLAVE  ORDER BY LLAVE,PERIODO_CONTABLE_ANALISIS)-sum(isnull(RRCNC,0)) AS Change
into #Final_s
from  #RT_reserva_inicial_camara
group by 
LLAVE,
PERIODO_CONTABLE_ANALISIS,
SUCURSAL_PROD,
--RAMO_CONTABLE,
trim(RAMO_PROD),
POLIZA,
CERTIFICADO,
--documento,
INTERMEDIARIO_LIDE,
cod_profitcenter,
fi_certificado,
ff_certificado
