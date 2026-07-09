-- Nodo KNIME : P&G_COCO\COMMISSIONS (#216)\PROFIT (#275)\DB Query Reader (#271)
-- Clave      : sql_statement

select distinct
nit_cc,
INTERMEDIARIO_LIDE
from 
(
select 
COD_INTERMEDIARIO
,RAZON_SOCIAL
,CAST(NIT_CC AS BIGINT) AS NIT_CC
,TIPO_IDENTIFICACION
,CAST(COD_SUCURSAL AS INT) AS COD_SUCURSAL
,lider.llave
,lider.clave_lider as intermediario_lide
FROM liberty.apoyo.dwh_intermediarios_total total
left join  LIBERTY.[APOYO].[DWH_REDCOMERCIAL_INTERMEDIARIOS] lider on total.cod_intermediario = lider.llave
) a
