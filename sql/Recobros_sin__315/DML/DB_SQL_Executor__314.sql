-- Nodo KNIME : P&G_COCO\Recobros_sin (#315)\DB SQL Executor (#314)
-- Clave      : statement

USE Liberty_pruebas_actuaria

insert into liberty_pruebas_actuaria.dbo.PL_COL_DATOS_COCO_UNIFICADO_RC

SELECT  
a.*
from #recobros2 a
