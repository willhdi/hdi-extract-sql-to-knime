-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#77)
-- Clave      : statement

USE Liberty_pruebas_actuaria



declare
@periodo_contable varchar(6)=$${Speriodo_contable}$$


if OBJECT_ID('tempdb.dbo.#reaseguro','U') is not null drop table #reaseguro



select
a.MDPEK as PERIODO_CONTABLE
,b.sbu as SBU
,a.MDSUL as SUCURSAL_PROD
,A.MDSUC AS sucursal_contable
,a.MDPRT AS RAMO_PROD
,a.MDRC AS ramo_contable
,a.MDPZA AS poliza
,a.MDCTD AS certificado 
,a.MDOBJ AS cuenta_LOCAL
,a.MDSCT AS subcuenta_local
,a.MDDL1 AS DESCRIPCION_CUENTA_SUB
,case when A.MDLT = 'AA' THEN A.MDAGL ELSE [dbo].[F_Conv_Cod_Agente](a.MDAGL) END AS INTERMEDIARIO_LIDE
,sum(case when MDNAT = 'H' THEN cast(MDAAG as float)*-1 ELSE MDAAG END)   as VALOR_REASEGURO
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,'Comision_reaseguro' AS Concepto_nivel_3
,'INTERFAZ_AUT' AS Concepto_nivel_2
,'REINSURANCE_COMMISSION' AS Concepto_nivel_1
,'COMMISSION EXPENSE' AS Concepto_nivel_0
,a.mdmod as modalidad
,mdobj as cuenta
,mdsct as subcuenta
into #reaseguro
from liberty.[MIDDLEWARE].[BASE_REASEGUROS_H] a
--left join
--liberty.prod.dwh_polizas_h t3 on t1.llave = t3.llave Validar cruce modalidad
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.MDPRT = b.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.MDPRT and t4.sucursal = a.MDSUL and t4.ramo_contable = a.MDRC
WHERE a.MDPEK>= @periodo_contable   and MDOBJ in (411631) AND MDSCT in (0101,0102,0108,0301,0302,0303,0304,0305,0306,0307,0308,0310,0315,0317,0325,0327
,0401,0402,0403,0404,405,0405,406,0406,408,0408,0411,0412,0418,425,0425,0107,400,0400,0324,0106,0115,0322,0309,0312,0407)
group by
a.MDPEK
,b.sbu
,a.MDSUL 
,A.MDSUC
,a.MDPRT 
,a.MDRC 
,a.MDPZA
,a.MDCTD 
,a.MDAGL
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,a.MDOBJ
,a.MDSCT 
,a.MDDL1
,a.MDLT
,a.MDNAT
,a.MDAAG
,a.mdmod
,mdobj 
,mdsct 


union all




select
a.MDPEK as PERIODO_CONTABLE
,b.sbu as SBU
,a.MDSUL as SUCURSAL_PROD
,A.MDSUC AS sucursal_contable
,a.MDPRT AS RAMO_PROD
,a.MDRC AS ramo_contable
,a.MDPZA AS poliza
,a.MDCTD AS certificado 
,a.MDOBJ AS cuenta_LOCAL
,a.MDSCT AS subcuenta_local
,a.MDDL1 AS DESCRIPCION_CUENTA_SUB
,case when A.MDLT = 'AA' THEN A.MDAGL ELSE [dbo].[F_Conv_Cod_Agente](a.MDAGL) END AS INTERMEDIARIO_LIDE
,/*sum(case when MDNAT = 'H' THEN cast(MDAAG as float)*-1 ELSE MDAAG END)*/ 
sum(cast(MDAAG as float)) as VALOR_REASEGURO
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,'Comision_reaseguro' AS Concepto_nivel_3
,'INTERFAZ_AUT_4' AS Concepto_nivel_2
,'REINSURANCE_COMMISSION' AS Concepto_nivel_1
,'COMMISSION EXPENSE' AS Concepto_nivel_0
,a.mdmod as modalidad
,mdobj as cuenta
,mdsct as subcuenta
from liberty.[MIDDLEWARE].[BASE_REASEGUROS_H] a
--left join
--liberty.prod.dwh_polizas_h t3 on t1.llave = t3.llave Validar cruce modalidad
left join 
liberty.apoyo.dwh_sbu_ramo_prod b on a.MDPRT = b.ramo_prod 
left join
liberty.apoyo.dwh_profitcenter t4 on t4.ramo_prod = a.MDPRT and t4.sucursal = a.MDSUL and t4.ramo_contable = a.MDRC
WHERE a.MDPEK>= @periodo_contable   and a.MDOBJ  in (511677) and  a.MDSCT  in (0102,0104,0303,0317,0413,0418,0435,0111,0313,0315,0322,101,108)
group by
a.MDPEK
,b.sbu
,a.MDSUL 
,A.MDSUC
,a.MDPRT 
,a.MDRC 
,a.MDPZA
,a.MDCTD 
,a.MDAGL
,t4.cod_profitcenter
,t4.desc_profitcenter
,t4.cod_sbu_sap
,t4.desc_sbu_sap
,a.MDOBJ
,a.MDSCT 
,a.MDDL1
,a.MDLT
,a.MDNAT
,a.MDAAG
,a.mdmod
,mdobj 
,mdsct 
---------


----select a.fuente,
----			rtrim(ltrim(cast(a.MDSS   as nvarchar(500)))) as SISTEMA --MDSS
----			,rtrim(ltrim(cast(a.MDINT  as nvarchar(500)))) as INTERFACE --MDINT
----			,rtrim(ltrim(cast(a.MDPEK  as nvarchar(500)))) as PERIODO --MDPEK
----			,rtrim(ltrim(cast(a.MDCNT  as nvarchar(500)))) as FECHA --MDCNT
----			,rtrim(ltrim(cast(a.MDCO   as nvarchar(500)))) as COMPANIA --MDCO
----			,rtrim(ltrim(cast(a.MDRC   as nvarchar(500)))) as RAMO_CONTABLE --MDRC
----			,rtrim(ltrim(cast(a.MDSUL  as nvarchar(500)))) as SUCURSAL_PROD --MDSUL
----			,rtrim(ltrim(cast(a.MDSUC  as nvarchar(500)))) as SUCURSAL_CONTABLE --MDSUC
----			,rtrim(ltrim(cast(a.MDMCU  as nvarchar(500)))) as UNIDAD_NEGOCIOS --MDMCU
----			,rtrim(ltrim(cast(a.MDDCT  as nvarchar(500)))) as TIPO_DOC_CONTABLE --MDDCT
----			,rtrim(ltrim(cast(a.MDICUT as nvarchar(500)))) as TIPO_BATCH_CONT --MDICUT
----			,rtrim(ltrim(cast(a.MDLT   as nvarchar(500)))) as LIBRO --MDLT
----			,rtrim(ltrim(cast(a.MDOBJ  as nvarchar(500)))) as CUENTA_LOCAL --MDOBJ
----			,rtrim(ltrim(cast(a.MDSCT  as nvarchar(500)))) as SUBCUENTA_LOCAL --MDSCT
----			,rtrim(ltrim(cast(a.MDDL1  as nvarchar(500)))) as DESCRIPCION_CUENTA_SUB --MDDL1
----			,rtrim(ltrim(cast(a.MDARE  as nvarchar(500)))) as AFILIADO_REASEGUROS --MDARE
----			,rtrim(ltrim(cast(a.MDCEN  as nvarchar(500)))) as CODIGO_ENTIDAD --MDCEN
----			,rtrim(ltrim(cast(a.MDREA  as nvarchar(500)))) as CODIGO_REASEGURADOR --MDREA
----			,rtrim(ltrim(cast(a.MDNAT  as nvarchar(500)))) as NATURALEZA_CONTABLE --MDNAT
----			,rtrim(ltrim(cast(a.MDORR  as nvarchar(500)))) as ORIGEN_REASEGUROS --MDORR
----			,rtrim(ltrim(cast(a.MDPRT  as nvarchar(500)))) as CODIGO_RAMO_PRODUCTO --MDPRT
----			,rtrim(ltrim(cast(a.MDPRR  as nvarchar(500)))) as RAMO_PRODUCTO_REASEGUROS --MDPRR
----			,rtrim(ltrim(cast(a.MDCOR  as nvarchar(500)))) as CONCEPTO_RECAUDO --MDCOR
----			,rtrim(ltrim(cast(a.MDCIR  as nvarchar(500)))) as CIA_REASEGUROS --MDCIR
----			,rtrim(ltrim(cast(a.MDPZA  as nvarchar(500)))) as NUMERO_POLIZA --MDPZA
----			,rtrim(ltrim(cast(a.MDCTD  as nvarchar(500)))) as CERTIFICADO_POLIZA --MDCTD
----			,rtrim(ltrim(cast(a.MDREP  as nvarchar(500)))) as DOC_RECIBO_POLIZA --MDREP
----			,rtrim(ltrim(cast(a.MDMTR  as nvarchar(500)))) as TERCERO_REQUERIDO_SAP --MDMTR
----			,rtrim(ltrim(cast(a.MDTXP  as nvarchar(500)))) as TIPO_ID_TERCERO --MDTXP
----			,rtrim(ltrim(cast(a.MDTXN  as nvarchar(500)))) as NUM_ID_TERCERO --MDTXN
----			,rtrim(ltrim(cast(a.MDDV   as nvarchar(500)))) as DIGITO_VERIFICACION --MDDV
----			,rtrim(ltrim(cast(a.MDTCO  as nvarchar(500)))) as TIPO_CONTRATO --MDTCO
----			,rtrim(ltrim(cast(a.MDACO  as nvarchar(500)))) as ANO_CONTRATO --MDACO
----			,rtrim(ltrim(cast(a.MDCON  as nvarchar(500)))) as NUMERO_CONTRATO --MDCON
----			,rtrim(ltrim(cast(a.MDVCT  as nvarchar(500)))) as VERSION_CONTRATO --MDVCT
----			,rtrim(ltrim(cast(a.MDTMP  as nvarchar(500)))) as TIPO_MOV_POLIZA --MDTMP
----			,rtrim(ltrim(cast(a.MDAGL  as nvarchar(500)))) as AGENTE_LIDER --MDAGL
----			,rtrim(ltrim(cast(a.MDAGC  as nvarchar(500)))) as AGENTE_COCORRETAJE --MDAGC
----			,rtrim(ltrim(cast(a.MDDIV  as nvarchar(500)))) as FECHA_EXPEDICION --MDDIV
----			,rtrim(ltrim(cast(a.MDFIE  as nvarchar(500)))) as FECHA_VIGENCIA --MDFIE
----			,rtrim(ltrim(cast(a.MDFFE  as nvarchar(500)))) as FECHA_FIN_VIG --MDFFE
----			,rtrim(ltrim(cast(a.MDFIC  as nvarchar(500)))) as FECHA_INICIO_DOC --MDFIC
----			,rtrim(ltrim(cast(a.MDFFC  as nvarchar(500)))) as FECHA_FIN_DOC --MDFFC
----			,rtrim(ltrim(cast(a.MDFFS  as nvarchar(500)))) as FECHA_SINIESTRO --MDFFS
----			,rtrim(ltrim(cast(a.MDFMV  as nvarchar(500)))) as FECHA_MOVIMIENTO --MDFMV
----			,rtrim(ltrim(cast(a.MDNSN  as nvarchar(500)))) as NUMERO_SINIESTRO --MDNSN
----			,rtrim(ltrim(cast(a.MDMOD  as nvarchar(500)))) as MODALIDAD --MDMOD
----			,rtrim(ltrim(cast(a.MDTNV  as nvarchar(500)))) as TIPO_NOV_SINIESTRO --MDTNV
----			,rtrim(ltrim(cast(a.MDTRS  as nvarchar(500)))) as TIPO_RESERVA_SINIES --MDTRS
----			,rtrim(ltrim(cast(a.MDOPG  as nvarchar(500)))) as ORDEN_PAGO_SINIEST --MDOPG
----			,rtrim(ltrim(cast(a.MDCPG  as nvarchar(500)))) as CONCEPTO_PAGO_SINIEST --MDCPG
----			,rtrim(ltrim(cast(a.MDMCT  as nvarchar(500)))) as MARCA_CATAST_SINIEST --MDMCT
----			,rtrim(ltrim(cast(a.MDCRCD as nvarchar(500)))) as MONEDA --MDCRCD
----			,rtrim(ltrim(cast(a.MDAAG  as nvarchar(500)))) as VALOR_RUBRO --MDAAG
----			,rtrim(ltrim(cast(a.MDTCP  as nvarchar(500)))) as TIPO_ID --MDTCP
----			,rtrim(ltrim(cast(a.MDTCN  as nvarchar(500)))) as NUMERO_ID --MDTCN
----			,rtrim(ltrim(cast(a.MDFUT1 as nvarchar(500)))) as FUTURO_1 --MDFUT1
----			,rtrim(ltrim(cast(a.MDFUT2 as nvarchar(500)))) as FUTURO_2 --MDFUT2
----			,rtrim(ltrim(cast(a.MDFUT3 as nvarchar(500)))) as FUTURO_3 --MDFUT3
----			,rtrim(ltrim(cast(a.MDFUT4 as nvarchar(500)))) as FUTURO_4 --MDFUT4
----			,rtrim(ltrim(cast(a.MDFGN  as nvarchar(500)))) as FECHA_GENERA_INTERFACE --MDFGN
----			,rtrim(ltrim(cast(a.MDHGN  as nvarchar(500)))) as HORA_GENERA_INTERFACE --MDHGN
----			,rtrim(ltrim(cast(a.MDPID  as nvarchar(500)))) as PROGRAMA_INTERFACE --MDPID
----			,rtrim(ltrim(cast(a.MDUSU  as nvarchar(500)))) as USUARIO_INTERFACE --MDUSU
----			,rtrim(ltrim(cast(a.MDFCG  as nvarchar(500)))) as FECHA_CARGUE_DWH --MDFCG
----			,rtrim(ltrim(cast(a.MDHCG  as nvarchar(500)))) as HORA_CARGUE_DWH --MDHCG
----from liberty.[MIDDLEWARE].[BASE_REASEGUROS_H] a
----where MDPEK = 202504 and MDOBJ  in (411631) and  MDSCT in (0101,0102,0108,0301,0302,0303,0304,0305,0306,0307,0308,0310,0315,0317,0325,0327,0401,0402,0403
----,0404,405,0405,406,0406,408,0408,0411,0412,0418,425,0425,0107,400,0400,0324,0106,0115,0322,0309,0312,0
