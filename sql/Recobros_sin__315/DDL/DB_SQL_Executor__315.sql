-- Nodo KNIME : P&G_COCO\Recobros_sin (#315)\DB SQL Executor (#315)
-- Clave      : statement

USE Liberty_pruebas_actuaria

drop table #recobros2
SELECT  
getdate() as create_at,
PERIODO_CONTABLE,
SPRODUC as ramo_prod,
npoliza as poliza,
b.SBU,
[dbo].[F_Conv_Cod_Agente](CAGENTE) as INTERMEDIARIO_LIDE,
Profit_nuevo as cod_profitcenter,
Descripcion_profit as desc_profitcenter,
SUBSTRING(LOB_SAP, 1, charindex('-', LOB_SAP)-1) as cod_sbu_sap ,
SUBSTRING(LOB_SAP, charindex('-', LOB_SAP)+1, len(LOB_SAP)) as desc_sbu_sap,
'Recobros_comerciales' as Concepto_nivel_3,
'Interfaz_automatica' as Concepto_nivel_2,
'Change in CASE' as Concepto_nivel_1,
'TOTAL_CLAIMS' AS Concepto_nivel_0,
0 as Marca_corretaje,
[dbo].[F_Conv_Cod_Agente](CAGENTE) as COD_INTERMEDIARIO,
0 as PARTICIPACION,
sucursal_prod AS COD_SUCURSAL,
sucursal_prod AS SUC_CONT,
NULL AS Business_Area,
NULL AS Business_Area_Des,
NULL AS Channel,	
NULL AS Channel_Des,
NULL AS Tipo_Canal,
NULL AS Canal_comercial,
NULL AS Regional_comercial,
NULL AS Sucursal_comercial,
NULL AS Sucursal_plan_comercial,
sum(CONVERT(INT,VALOR_FINAL)) AS VALOR_CONCEPTO,
0 AS exc_consurso,
vehicle_use_class_code AS  MODALIDAD,
'' AS AGRUPADOR,
NULL AS TIPO_RIESGO,
NULL AS CANAL_HOMOLOGADO,
NULL AS SUB_CANAL_HOMOLOGADO,
NULL AS Regional_homologada,
NULL AS Sucursal_fusion_homologada,
NULL AS Sucursal_homologada,
NULL AS INTERMEDIARIO_HOMOLOGADO,
NULL AS TIPO_DOC_TOMADOR,
NULL AS DOCUMENTO_TOMADOR,
NULL AS TOMADOR,
'HDISC' AS COMPANIA,
NULL AS COD_CLAVE_LIDER,
0 AS TRASLADO,	
NULL AS INTERMEDIARIO_INICIAL_TRASLADO,
NULL AS SUC_INICIAL_TRASLADOS,
NULL AS INTERMEDIARIO_FINAL_TRASLADOS,
NULL AS SUC_FINAL_TRASLADOS,
NULL AS EXC_FACULTATIVO,
NULL AS EXC_LICITACIONES,
NULL AS EXC_REFERIDOS
,null as MACRORAMO
,null as GERENCIA
,NULL AS LOB_TALANX
INTO #recobros2
FROM #recobros a
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on SPRODUC = b.ramo_prod 
group by 
PERIODO_CONTABLE
,SPRODUC 
,npoliza
,b.SBU
,CAGENTE
,Profit_nuevo 
,Descripcion_profit 
,LOB_SAP
,sucursal_prod
,vehicle_use_class_code
