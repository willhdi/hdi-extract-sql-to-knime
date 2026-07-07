-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#298)\DB Query Reader (#365)
-- Clave      : sql_statement

SELECT 
--*
PERIODO_CONTABLE,concepto_nivel_3,SUM(Change) 
FROM #com_reserva_inicial_cedidas
GROUP BY PERIODO_CONTABLE,concepto_nivel_3
