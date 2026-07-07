-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#64)\DB SQL Executor (#280)
-- Clave      : statement

USE Liberty_Pruebas_Actuaria





declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$



if OBJECT_ID('tempdb.dbo.#RT_reserva_inicial_terremoto','U') is not null drop table #RT_reserva_inicial_terremoto



select convert(date,concat(A.periodo_contable_analisis,'01')) as fecha,
A.periodo_contable_analisis,
a.sucursal_lide as SUCURSAL_PROD,
trim(A.RAMO_PROD) as RAMO_PROD,
A.RAMO_CONTABLE,
A.POLIZA,
A.CERTIFICADO,
a.documento,
inter.INTERMEDIARIO_LIDE,
a.modalidad,
sum(A.valor_reserva_contable) as valor_res,
sum(A.valor_reserva) as RRCNC,
concat(trim(A.RAMO_PROD),'-',A.POLIZA,'-',A.CERTIFICADO,'-',a.documento) as LLAVE 
--LAG(convert(date,concat(A.periodo_contable_analisis,'01')), 1,convert(date,concat(A.periodo_contable_analisis,'01'))) OVER (PARTITION BY A.SUCURSAL_PROD,trim(A.RAMO_PROD),A.POLIZA,A.CERTIFICADO,a.INTERMEDIARIO_LIDE ORDER BY A.SUCURSAL_PROD,trim(A.RAMO_PROD),A.POLIZA,A.CERTIFICADO,a.INTERMEDIARIO_LIDE,PERIODO_CONTABLE_ANALISIS) as fec_ant,
--datediff(month,LAG(convert(date,concat(A.periodo_contable_analisis,'01')), 1,convert(date,concat(A.periodo_contable_analisis,'01'))) OVER (PARTITION BY A.SUCURSAL_PROD,trim(A.RAMO_PROD),A.POLIZA,A.CERTIFICADO,a.INTERMEDIARIO_LIDE ORDER BY A.SUCURSAL_PROD,trim(A.RAMO_PROD),A.POLIZA,A.CERTIFICADO,a.INTERMEDIARIO_LIDE,PERIODO_CONTABLE_ANALISIS),convert(date,concat(A.periodo_contable_analisis,'01'))) diff,
--max(convert(date,concat(A.periodo_contable_analisis,'01'))) OVER (PARTITION BY A.SUCURSAL_PROD,trim(A.RAMO_PROD),A.POLIZA,A.CERTIFICADO,a.INTERMEDIARIO_LIDE) as fecha_max
into #RT_reserva_inicial_terremoto
from liberty.[RESERVAS].[CEDIDAS_TERREMOTO_RESERVA_INTERFAZ] as A
left join  (select distinct ramo_prod,poliza,intermediario_lide from LIBERTY.RESERVAS.POLIZA_INTERMEDIARIO ) inter on inter.ramo_prod = a.ramo_prod and inter.poliza = a.poliza --and inter.certificado = a.certificado --and inter.PERIODO_CONTABLE =a.periodo_contable_analisis

where  A.periodo_contable_analisis = @periodo_contable and a.cuenta in ('410305','510305','419595') and fuente_interfaz = 'TERR' AND  a.libro <> 'AG'
group by 
A.periodo_contable_analisis,
A.SUCURSAL_LIDE,
trim(A.RAMO_PROD),
a.ramo_contable,
A.POLIZA,
A.CERTIFICADO,
a.documento
,inter.INTERMEDIARIO_LIDE
,a.modalidad


update a
set a.INTERMEDIARIO_LIDE = b.INTERMEDIARIO_LIDE
from #RT_reserva_inicial_terremoto a 
left join liberty_pruebas_actuaria.dbo.claves_por_poliza b on a.ramo_prod = b.ramo_prod and a.poliza = b.poliza and a.certificado = b.certificado and a.documento = b.documento 
where b.INTERMEDIARIO_LIDE is null
