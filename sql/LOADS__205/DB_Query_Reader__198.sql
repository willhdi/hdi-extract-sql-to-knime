-- Nodo KNIME : P&G_COCO\LOADS (#205)\DB Query Reader (#198)
-- Clave      : sql_statement

select * from #alae
where valor_concepto <> 0 and valor_concepto is not null
--select count(*) from #costos_xl
