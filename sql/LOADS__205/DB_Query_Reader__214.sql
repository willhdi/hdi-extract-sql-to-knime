-- Nodo KNIME : P&G_COCO\LOADS (#205)\DB Query Reader (#214)
-- Clave      : sql_statement

select * from #alae_co
where valor_concepto <> 0 and valor_concepto is not null
--select count(*) from #costos_xl
