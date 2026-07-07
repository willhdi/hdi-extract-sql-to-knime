-- Nodo KNIME : P&G_COCO\Gross Writte (#43)\DB SQL Executor (#222)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/*****************
CASO 1 DE COCORRETAJE interemdiario misma sucursal 
******************/

if OBJECT_ID('tempdb.dbo.#caso1','U') is not null drop table #caso1

select
a.*,
CASE WHEN b.COD_INTERMEDIARIO IS NULL THEN A.INTERMEDIARIO_LIDE ELSE b.COD_INTERMEDIARIO END AS COD_INTERMEDIARIO,
CASE WHEN b.PARTICIPACION IS NULL THEN 0 ELSE b.PARTICIPACION END  AS PARTICIPACION,
CASE WHEN b.DOCUMENTO IS NULL THEN A.DOCUMENTO ELSE b.DOCUMENTO END AS DOC,
--b.DOC_2,
--b.COD_SUCURSAL,
--CASE WHEN b.COD_SUCURSAL IS NULL THEN A.SUCURSAL_PROD ELSE B.COD_SUCURSAL END AS COD_SUCURSAL,
CASE WHEN b.PARTICIPACION IS NULL THEN a.GROSS_WRITTEN_PREMIUM 
	 ELSE a.GROSS_WRITTEN_PREMIUM * (b.PARTICIPACION/100) 
END as GROSS_WRITTEN_PREMIUM_CO,
b.COD_SUCURSAL
into #caso1
from  #si_coco a
left join #corretaje b 
on (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT AND A.documento>=B.documento and A.documento<B.doc_2)
where
b.PARTICIPACION is not null and (vr_p_p_sucursal = 0 or (vr_p_p_sucursal = 100 and vr_p_sucursal= 100))
