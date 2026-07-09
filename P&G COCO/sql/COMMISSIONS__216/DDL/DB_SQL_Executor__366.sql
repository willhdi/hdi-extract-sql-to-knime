-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\DB SQL Executor (#366)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#pol','U') is not null drop table #pol

SELECT DISTINCT *
into #pol
FROM 
(
select 
ramo_prod,
poliza,
certificado,
max(documento) as documento 

from  liberty.prod.dwh_polizas_h 
where periodo_contable >=202001
group by ramo_prod,poliza,certificado
) a


if OBJECT_ID('#recibo','U') is not null drop table #recibo

SELECT DISTINCT *
into #recibo
FROM 
(
select 
ramo_prod,
poliza,
certificado,
recibo,
max(documento) as documento 

from  liberty.prod.dwh_polizas_h 
where periodo_contable >=202001
group by ramo_prod,poliza,certificado,recibo
) b
