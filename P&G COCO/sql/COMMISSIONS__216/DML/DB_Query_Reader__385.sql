-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB Query Reader (#385)
-- Clave      : sql_statement



select
PERIODO_CONTABLE,
cuenta_LOCAL,
subcuenta_local,
sum(VALOR_reaseguro)
from #reaseguro
--where poliza = 515244 and certificado = 213
group by periodo_contable,cuenta_LOCAL,subcuenta_local
