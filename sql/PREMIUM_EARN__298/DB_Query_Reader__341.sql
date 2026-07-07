-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#298)\DB Query Reader (#341)
-- Clave      : sql_statement

SELECT 
--*
PERIODO_CONTABLE,concepto_nivel_3,SUM(VALOR_CONCEPTO) 
FROM #change_comisiones_cedidas
GROUP BY PERIODO_CONTABLE,concepto_nivel_3
