-- Nodo KNIME : P&G_COCO\RECOBROS (#230)\DB SQL Executor (#250)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/*****************
CASO 1 DE COCORRETAJE interemdiario misma sucursal 
******************/

if OBJECT_ID('tempdb.dbo.#caso1','U') is not null drop table #caso1

select
a.*,
row_number() over(order by ramo_prod) as id,
CASE WHEN b.COD_INTERMEDIARIO IS NULL THEN A.INTERMEDIARIO_LIDE ELSE b.COD_INTERMEDIARIO END AS COD_INTERMEDIARIO,
CASE WHEN b.PARTICIPACION IS NULL THEN 0 ELSE b.PARTICIPACION END  AS PARTICIPACION,
CASE WHEN b.DOCUMENTO IS NULL THEN A.DOCUMENTO ELSE b.DOCUMENTO END AS DOC,
CASE WHEN b.PARTICIPACION IS NULL THEN a.VLR_PAGADO_REC
	 ELSE a.VLR_PAGADO_REC  * (b.PARTICIPACION/100) 
END as VLR_PAGADO_REC_CO,
b.COD_SUCURSAL
into #caso1
from  #si_coco a
left join #corretaje b 
on (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT AND A.documento>=B.documento and A.documento<B.doc_2)
--where
--b.PARTICIPACION is not null
