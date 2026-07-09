-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#64)\DB Query Reader (#347)
-- Clave      : sql_statement

SELECT PERIODO_CONTABLE, SUM(VALOR_CONCEPTO) FROM #change_devengada_directa
GROUP BY PERIODO_CONTABLE
