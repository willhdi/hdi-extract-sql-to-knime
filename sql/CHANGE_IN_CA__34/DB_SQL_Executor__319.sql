-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#319)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/*****************
CASO 1 DE COCORRETAJE interemdiario misma sucursal 
******************/

if OBJECT_ID('tempdb.dbo.#caso1','U') is not null drop table #caso1

select
a.*,
case when b.participacion is null then a.intermediario_lide else
			b.COD_INTERMEDIARIO END AS COD_INTERMEDIARIO,
case when b.participacion is null then 0 		
			ELSE b.PARTICIPACION END AS PARTICIPACION,
case when b.participacion is null then a.DOCUMENTO 
			ELSE b.DOCUMENTO END AS DOC,
case when b.participacion is null then a.SUCURSAL_PROD
			else b.COD_SUCURSAL END as COD_SUCURSAL,
CASE WHEN b.PARTICIPACION IS NULL THEN a.VALOR_CONCEPTO
	 ELSE a.VALOR_CONCEPTO * (b.PARTICIPACION/100) 
END as VALOR_CONCEPTO_CO
into #caso1
from  #si_coco a
left join #corretaje_sin b 
on (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT AND A.documento>=B.documento and A.documento<B.doc_2)
--where
--b.PARTICIPACION is not null
