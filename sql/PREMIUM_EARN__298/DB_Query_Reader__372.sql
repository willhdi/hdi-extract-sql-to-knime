-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#298)\DB Query Reader (#372)
-- Clave      : sql_statement

SELECT *
--sum(valor_concepto) 
FROM #change_comision_directa
where poliza = 527705 and certificado = 567
