-- Nodo KNIME : P&G_COCO\IMPUESTOS (#225)\DB Query Reader (#226)
-- Clave      : sql_statement

select * from #impuestos_co
where valor_concepto <> 0 and valor_concepto is not null

--select count(*) from #costos_xl
