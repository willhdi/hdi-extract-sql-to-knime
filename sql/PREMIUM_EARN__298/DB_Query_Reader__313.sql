-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#298)\DB Query Reader (#313)
-- Clave      : sql_statement

USE Liberty_pruebas_actuaria


select 
PERIODO_CONTABLE
,RAMO_PROD
,POLIZA
,SBU
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,convert(varchar,cod_sbu_sap) as cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,Marca_corretaje
,COD_INTERMEDIARIO
,PARTICIPACION
,COD_SUCURSAL
,sum(valor_concepto_co) as VALOR_CONCEPTO
from #cocorretaje_completo
group by 
PERIODO_CONTABLE
,RAMO_PROD
,POLIZA
,SBU
,INTERMEDIARIO_LIDE
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2
,Concepto_nivel_1
,Concepto_nivel_0
,Marca_corretaje
,COD_INTERMEDIARIO
,PARTICIPACION
,COD_SUCURSAL
