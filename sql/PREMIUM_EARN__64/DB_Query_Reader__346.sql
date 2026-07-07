-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#64)\DB Query Reader (#346)
-- Clave      : sql_statement

SELECT ramo_prod,count(*) FROM #RT_reserva_inicial_terremoto
group by ramo_prod
