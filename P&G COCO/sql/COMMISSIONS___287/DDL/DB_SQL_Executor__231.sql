-- Nodo KNIME : P&G_COCO\COMMISSIONS_ (#287)\DB SQL Executor (#231)
-- Clave      : statement

USE Liberty_pruebas_actuaria


declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#retorno_2','U') is not null drop table #retorno_2

----liberty.[AS400].[F590475]

select 
SUBSTRING(cast(a.IVFECI as varchar),0,7) AS PERIODO_CONTABLE
,b.SBU
,a.IVSUCL as sucursal_prod
,a.IVRAMO as ramo_prod
,a.IV$RAC AS RAMO_CONTABLE
,a.IVPOLI as poliza
,a.IVCERT as certificado
,a.IVDOCU as documento
--,a.IVCTIV AS CODIGO
,a.IVCLVI AS INTERMEDIARIO_LIDE
,SUM(a.IVIA15)*-1 AS VALOR_RETORNO
--,t4.cod_profitcenter
--,t4.desc_profitcenter
--,t4.cod_sbu_sap
--,t4.desc_sbu_sap
,case when a.IVRAMO = 'E1' AND a.IV$RAC = 149 THEN 'RCO3130004' ELSE t4.cod_profitcenter end as cod_profitcenter
,case when a.IVRAMO = 'E1' AND a.IV$RAC = 149 THEN 'Eventos Criticos Individual' ELSE t4.desc_profitcenter end as desc_profitcenter
,case when a.IVRAMO = 'E1' AND a.IV$RAC = 149 THEN '7150' ELSE t4.cod_sbu_sap end as cod_sbu_sap
,case when a.IVRAMO = 'E1' AND a.IV$RAC = 149 THEN ' Individual Health, Dental, Disabi' ELSE t4.desc_sbu_sap end as desc_sbu_sap
,'Retornos_a' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'COMMISSION EXPENSE' AS Concepto_nivel_1
,'COMMISSION EXPENSE' AS Concepto_nivel_0
into #retorno_2
FROM liberty.[AS400].[F590475] a
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.IVRAMO = b.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.IVRAMO and t4.sucursal = a.IVSUCL and t4.ramo_contable = a.IV$RAC
WHERE IVCTIV = 181 and SUBSTRING(cast(a.IVFECI as varchar),0,7) =  @periodo_contable
GROUP BY 
a.IVSUCL 
,a.IVRAMO 
,a.IVPOLI 
,a.IVCERT
,a.IVDOCU
,a.IVCTIV
,a.IVFECI
,a.IV$RAC
,a.IVCLVI
,b.SBU
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap


union all

--liberty.[AS400].[REFPAGOS]

select 
b.DCPEKN as periodo_contable
,c.SBU
,b.DCSCLD AS SUCURSAL_PROD
,b.DCRACG as RAMO_PROD
,b.ramo_contable
,b.DCPZNU AS POLIZA
,b.DCCTNU AS CERTIFICADO
,b.DCDCNU AS DOCUMENTO
,b.DCITCG AS INTERMEDIARIO_LIDE
,SUM(b.DCCMPO) AS VALOR_RETORNO
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,'Retornos_a' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'COMMISSION EXPENSE' AS Concepto_nivel_1
,'COMMISSION EXPENSE' AS Concepto_nivel_0
from
(
select a.*,
case when a.DCRACG = '462' then '748' 
	 when a.DCRACG = '463' then '735' 	
	 when a.DCRACG = '411' then '411'
	 when a.DCRACG = '410' then '3'
	 when a.DCRACG = 'Z1' then '237'
	 when a.DCRACG = 'ADU' then '267'
	 ELSE '' END AS RAMO_CONTABLE
from liberty.[AS400].[REFPAGOS] a
) b
left join 
liberty.apoyo.dwh_sbu_ramo_prod c on b.DCRACG = c.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = b.DCRACG and t4.sucursal = b.DCSCLD and t4.ramo_contable = b.ramo_contable
where DCPEKN = @periodo_contable and DCTNNU = 181 
group by
b.DCPEKN
,c.SBU
,b.DCRACG
,b.ramo_contable
,b.DCPZNU
,b.DCCTNU
,b.DCDCNU
,b.DCSCLD
,b.DCITCG
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
