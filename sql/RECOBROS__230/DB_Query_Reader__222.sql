-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB Query Reader (#222)
-- Clave      : sql_statement

select
cast(periodo_contable as int) as PERIODO_CONTABLE
,cast(SUCURSAL_PROD as varchar) as sucursal_prod
,INTERMEDIARIO_LIDE
,SBU
,sum(VLR_PAGADO_REC) as VALOR_CONCEPTO
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2 
,Concepto_nivel_1 
,Concepto_nivel_0 
from #r_as400_d
group by 
periodo_contable 
,SUCURSAL_PROD
,INTERMEDIARIO_LIDE
,SBU
,cod_profitcenter
,desc_profitcenter
,cod_sbu_sap
,desc_sbu_sap
,Concepto_nivel_3
,Concepto_nivel_2 
,Concepto_nivel_1 
,Concepto_nivel_0
