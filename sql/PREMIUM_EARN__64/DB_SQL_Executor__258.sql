-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#64)\DB SQL Executor (#258)
-- Clave      : statement

USE Liberty_Pruebas_Actuaria



declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#RT_reserva_inicial_camara','U') is not null drop table #RT_reserva_inicial_camara
--drop table RT_reserva_inicial_dev
--INSERT into #RT_reserva_inicial_camara


select convert(date,concat(A.periodo_contable_analisis,'01')) as fecha,
A.periodo_contable_analisis,
int_suc.SUCURSAL_PROD,
trim(A.RAMO_PROD) as RAMO_PROD,
A.POLIZA,
A.CERTIFICADO,
--1 AS documento,
'RCO1011002' as cod_profitcenter,
int_suc.INTERMEDIARIO_LIDE,
a.fi_certificado,
a.ff_certificado,
sum(A.valor_camara) as valor_camara,
sum(A.valor_reserva) as RRCNC,
sum(A.valor_camara*A.factor_reserva) as RRC,
sum(valor_reserva_contable) as change,
concat(trim(A.RAMO_PROD),'-',A.POLIZA,'-',A.CERTIFICADO,'-',a.fi_certificado,'-',a.ff_certificado) as LLAVE 
--LAG(convert(date,concat(A.periodo_contable_analisis,'01')), 1,convert(date,concat(A.periodo_contable_analisis,'01'))) OVER (PARTITION BY A.SUCURSAL_PROD,trim(A.RAMO_PROD),A.POLIZA,A.CERTIFICADO,a.INTERMEDIARIO_LIDE ORDER BY A.SUCURSAL_PROD,trim(A.RAMO_PROD),A.POLIZA,A.CERTIFICADO,a.INTERMEDIARIO_LIDE,PERIODO_CONTABLE_ANALISIS) as fec_ant,
--datediff(month,LAG(convert(date,concat(A.periodo_contable_analisis,'01')), 1,convert(date,concat(A.periodo_contable_analisis,'01'))) OVER (PARTITION BY A.SUCURSAL_PROD,trim(A.RAMO_PROD),A.POLIZA,A.CERTIFICADO,a.INTERMEDIARIO_LIDE ORDER BY A.SUCURSAL_PROD,trim(A.RAMO_PROD),A.POLIZA,A.CERTIFICADO,a.INTERMEDIARIO_LIDE,PERIODO_CONTABLE_ANALISIS),convert(date,concat(A.periodo_contable_analisis,'01'))) diff,
--max(convert(date,concat(A.periodo_contable_analisis,'01'))) OVER (PARTITION BY A.SUCURSAL_PROD,trim(A.RAMO_PROD),A.POLIZA,A.CERTIFICADO,a.INTERMEDIARIO_LIDE) as fecha_max
into #RT_reserva_inicial_camara
from liberty.[RESERVAS].[CAMARA_CONTABLE_RESERVA_INTERFAZ] as A
left join (
			select distinct * from LIBERTY.RESERVAS.POLIZA_INTERMEDIARIO i
			left join (select distinct  ramo_prod as ramo,poliza as pol,CERTIFICADO as certifi, documento as doc ,sucursal_prod from liberty.prod.DWH_POLIZAS_H
			where ramo_prod in ('900730','AO')) p  on  i.RAMO_PROD = p.RAMO and i.POLIZA = p.pol and i.CERTIFICADO = p.CERTIFI and i.DOCUMENTO = p.doc
			) int_suc on int_suc.ramo_prod = a.ramo_prod and int_suc.poliza = a.poliza and int_suc.certificado = a.certificado ---and int_suc.PERIODO_CONTABLE =a.periodo_contable_analisis

where  A.periodo_contable_analisis = @periodo_contable  and a.cuenta in ('410315','510315') --AND  a.libro <> 'AG'
group by 
A.periodo_contable_analisis,
int_suc.SUCURSAL_PROD,
trim(A.RAMO_PROD),
A.POLIZA,
A.CERTIFICADO,
int_suc.INTERMEDIARIO_LIDE,
a.fi_certificado,
a.ff_certificado
