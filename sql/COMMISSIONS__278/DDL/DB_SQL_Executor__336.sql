-- Nodo KNIME : P&G_COCO\COMMISSIONS (#278)\DB SQL Executor (#336)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/*****************
CASO 1 DE COCORRETAJE interemdiario misma sucursal 
******************/

if OBJECT_ID('tempdb.dbo.#caso1_r','U') is not null drop table #caso1_r

select
a.*,
CASE WHEN b.COD_INTERMEDIARIO IS NULL THEN A.INTERMEDIARIO_LIDE ELSE b.COD_INTERMEDIARIO END AS COD_INTERMEDIARIO,
CASE WHEN b.PARTICIPACION IS NULL THEN 0 ELSE b.PARTICIPACION END  AS PARTICIPACION,
CASE WHEN b.DOCUMENTO IS NULL THEN A.DOCUMENTO ELSE b.DOCUMENTO END AS DOC,
CASE WHEN b.PARTICIPACION IS NULL THEN a.VALOR_CONCEPTO
	 ELSE a.VALOR_CONCEPTO * (b.PARTICIPACION/100) 
END as VALOR_CONCEPTO_CO,
b.COD_SUCURSAL
into #caso1_r
from  #si_coco_r a
left join #corretaje b 
on (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT AND A.documento>=B.documento and A.documento<B.doc_2)
where
b.PARTICIPACION is not null
