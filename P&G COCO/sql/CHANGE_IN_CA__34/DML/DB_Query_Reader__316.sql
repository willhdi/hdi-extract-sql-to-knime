-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB Query Reader (#316)
-- Clave      : sql_statement

SELECT * 
FROM  #cocorretaje_completo
WHERE VALOR_CONCEPTO_CO <> 0
