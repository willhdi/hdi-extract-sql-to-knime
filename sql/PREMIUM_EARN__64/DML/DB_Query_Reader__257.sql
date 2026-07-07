-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#64)\DB Query Reader (#257)
-- Clave      : sql_statement

select 
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
,0 AS Marca_corretaje
,INTERMEDIARIO_LIDE AS COD_INTERMEDIARIO
,0 AS PARTICIPACION
,SUCURSAL_PROD AS COD_SUCURSAL
,sum(valor_concepto) as VALOR_CONCEPTO
from #change_devengada_soat
--WHERE PERIODO_CONTABLE = $${Speriodo_contable}$$
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
,SUCURSAL_PROD
