-- Nodo KNIME : P&G_COCO\XL_Cost (#73)\DB Query Reader (#193)
-- Clave      : sql_statement

select * from #costos_xl_co
where valor_concepto <> 0 and valor_concepto is not null

--select count(*) from #costos_xl
