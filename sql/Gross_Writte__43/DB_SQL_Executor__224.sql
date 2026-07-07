-- Nodo KNIME : P&G_COCO\Gross Writte (#43)\DB SQL Executor (#224)
-- Clave      : statement

USE Liberty_pruebas_actuaria

/*****************
CASO 1 DE COCORRETAJE interemdiario misma sucursal 
******************/

if OBJECT_ID('tempdb.dbo.#caso2_1','U') is not null drop table #caso2_1


select distinct 
a.*,
b.COD_INTERMEDIARIO,
b.PARTICIPACION,
b.DOCUMENTO AS DOC,
case when a.vr_p_sucursal = 100 and a.vr_p_p_sucursal in (100,50)  then a.GROSS_WRITTEN_PREMIUM * (b.PARTICIPACION/100)
else GROSS_WRITTEN_PREMIUM  end as GROSS_WRITTEN_PREMIUM_CO,
B.COD_SUCURSAL
--,null as agente2,null as partici2
into #caso2_1
from  #si_coco a
left join #corretaje b 
on  (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT AND A.documento>=B.documento and A.documento<B.doc_2)  and a.vr_p_p_sucursal = b.participacion
where
b.PARTICIPACION is not null and
vr_p_p_sucursal <> 0
--AND vr_p_sucursal  <= 100



----- Este segundo cruce validarlo para los casos donde el cocorretaje es  entre varias sucursales
----- y varios intermediarios en una de esas sucursales

--drop table #caso2_2

if OBJECT_ID('tempdb.dbo.#caso2_2','U') is not null drop table #caso2_2

select  
a.PERIODO_CONTABLE
,a.SSEGURO
--,a.SUCURSAL_PROD
,a.RAMO_PROD
,a.RAMO_TECNICO
,a.RAMO_CONTABLE
,a.POLIZA
,a.CERTIFICADO
,a.DOCUMENTO
,a.ANEXO
,a.SBU
,a.FI_CERTIFICADO
,a.FF_CERTIFICADO
,a.FI_DOCUMENTO
,a.FF_DOCUMENTO
,a.FECHA_EXPE
,a.INTERMEDIARIO_LIDE
,a.vr_p_sucursal
,a.vr_p_p_sucursal
,a.FI_ANEXO
,a.FF_ANEXO
,a.cod_modalidad
,a.GROSS_WRITTEN_PREMIUM
,a.cod_profitcenter
,a.desc_profitcenter
,a.cod_sbu_sap
,a.desc_sbu_sap
,a.Concepto_nivel_3
,a.Concepto_nivel_2
,a.Concepto_nivel_1
,a.Concepto_nivel_0
,a.marca_corretaje
,b.COD_INTERMEDIARIO
,b.PARTICIPACION
,b.DOCUMENTO as DOC
,case when b.participacion IS NULL then a.GROSS_WRITTEN_PREMIUM * (b.PARTICIPACION/100) / (a.vr_p_p_sucursal/100) 
	  when a.vr_p_p_sucursal = 100 then a.GROSS_WRITTEN_PREMIUM * (b.PARTICIPACION/100)
 	  else
 	  a.GROSS_WRITTEN_PREMIUM
	   end as GROSS_WRITTEN_PREMIUM_CO
,b.COD_SUCURSAL
into #caso2_2
from #caso2_1 a
left join #corretaje b
on  (concat(ltrim(rtrim(A.RAMO_PROD)),'_',ltrim(rtrim(A.poliza)),'_',A.certificado)=B.LLAVE_CERT AND A.documento>=B.documento and A.documento<B.doc_2)
and NOT exists (select * from #caso2_1 aa where aa.ramo_prod=b.cod_ramo_prod and aa.poliza=b.nro_poliza and aa.certificado=b.nro_certificado and aa.participacion=b.participacion)
where a.participacion is null



--select 
--d.*,
--c.COD_INTERMEDIARIO,
--c.PARTICIPACION,
--c.DOCUMENTO AS DOC,
--c.COD_SUCURSAL,
--d.GROSS_WRITTEN_PREMIUM * (c.PARTICIPACION/100) as GROSS_WRITTEN_PREMIUM_CO
--into #caso2_2
--from
--(
--	select
--	a.*
--	--into #caso2_2
--	from  #si_coco a
--	left join #corretaje b 
--	on a.ramo_prod = b.cod_ramo_prod and a.poliza = b.nro_poliza and a.certificado = b.nro_certificado and  a.DOCUMENTO = b.documento  and a.vr_p_p_sucursal = b.participacion
--	where
--	b.PARTICIPACION is  null and
--	vr_p_p_sucursal <> 0
--) d
--left join #corretaje c 
--on d.ramo_prod = c.cod_ramo_prod and d.poliza = c.nro_poliza and d.certificado = c.nro_certificado and  d.DOCUMENTO = c.documento
--DROP TABLE #caso2_u

--select * 
--into #caso2_u
--from #caso2_1
--where PARTICIPACION is not null
--union
--select * from #caso2_2










---GROSS_WRITTEN_PREMIUM_CO
