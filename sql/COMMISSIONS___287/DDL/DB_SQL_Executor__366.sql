-- Nodo KNIME : P&G_COCO\COMMISSIONS_ (#287)\DB SQL Executor (#366)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#pol','U') is not null drop table #pol


select 
ramo_prod,
poliza,
certificado,
max(documento) as documento 
into #pol
from  liberty.prod.dwh_polizas_h 
where periodo_contable >=202001
group by ramo_prod,poliza,certificado
