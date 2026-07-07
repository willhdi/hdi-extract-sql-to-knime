-- Nodo KNIME : P&G_COCO\XL_Cost (#73)\DB Query Reader (#210)
-- Clave      : sql_statement

select concepto_nivel_1,sum(valor_concepto) from #neta_xl_co
group by concepto_nivel_1
--select count(*) from #costos_xl
