-- Nodo KNIME : P&G_COCO\Written Prem (#33)\DB SQL Executor (#197)
-- Clave      : statement

USE Liberty_pruebas_actuaria

declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#cedidas','U') is not null drop table #cedidas


if OBJECT_ID('dbo.intermediarios_unicos','U') is not null drop table intermediarios_unicos
SELECT * 
INTO intermediarios_unicos
from (
		SELECT ramo_prod,
		       poliza AS pol,
		       intermediario_lide,
		       ROW_NUMBER() OVER (PARTITION BY ramo_prod, poliza ORDER BY intermediario_lide) AS rn
		FROM liberty.prod.dwh_polizas_h
		WHERE PERIODO_CONTABLE >= 202001
) a 
where rn = 1

select ced.* ,p.intermediario_lide
into #cedidas
from #profit_ced ced
left join 
intermediarios_unicos p on ced.RAMO_prod = p.ramo_prod and ced.poliza = p.pol --and ced.certificado = p.certi-- and ced.DOCUMENTO = p.documento
