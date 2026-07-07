-- Nodo KNIME : P&G_COCO\PREMIUM EARN (#64)\DB SQL Executor (#286)
-- Clave      : statement

USE Liberty_pruebas_actuaria

if OBJECT_ID('tempdb.dbo.#devengada_dir_ter','U') is not null drop table #devengada_dir_ter


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


-- Directa Terremoto

select 
convert(date,concat(A.periodo_contable_analisis,'01')) as fecha
,a.PERIODO_CONTABLE_ANALISIS AS PERIODO_CONTABLE
,a.SUCURSAL_PROD
,a.sucursal_contable
,t2.SBU
,a.RAMO_PROD
,a.RAMO_CONTABLE
,a.POLIZA
,a.CERTIFICADO
,a.documento
,a.INTERMEDIARIO_LIDE
,a.fi_certificado
,a.ff_certificado
,sum(A.valor_reserva_contable) as valor_res
,sum(A.valor_reserva) as RRCNC
,concat(trim(A.RAMO_PROD),'-',A.POLIZA,'-',A.CERTIFICADO,'-',a.documento) as LLAVE 
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,a.modalidad
into #devengada_dir_ter
from liberty.[RESERVAS].[DIRECTA_TERREMOTO_RESERVA_INTERFAZ] a
left join 
liberty.apoyo.dwh_sbu_ramo_prod t2 on a.ramo_prod = t2.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.ramo_prod and a.sucursal_prod = t4.sucursal and a.ramo_contable = t4.ramo_contable
WHERE PERIODO_CONTABLE_analisis = @periodo_contable  and a.cuenta in ('410305','419595','510305') and fuente_interfaz ='TERR'
--PERIODO_CONTABLE_analisis >= 202112
group by 
a.PERIODO_CONTABLE_ANALISIS
,a.SUCURSAL_PROD
,a.sucursal_contable
,t2.SBU
,a.RAMO_PROD
,a.RAMO_CONTABLE
,a.POLIZA
,a.CERTIFICADO
,a.documento
,a.INTERMEDIARIO_LIDE	
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,a.fi_certificado
,a.ff_certificado
,a.modalidad
