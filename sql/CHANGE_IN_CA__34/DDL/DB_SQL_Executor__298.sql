-- Nodo KNIME : P&G_COCO\CHANGE_IN_CA (#34)\DB SQL Executor (#298)
-- Clave      : statement

USE Liberty_Pruebas_Actuaria

declare
@periodo_contable varchar(6)='201501'


if OBJECT_ID('tempdb.dbo.#RT_Apoyo_p_coaseg','U') is not null drop table #RT_Apoyo_p_coaseg


select row_number()over(partition by clasi.poliza,clasi.certificado,clasi.RECIBO order by clasi.VR_P_COASEGURO desc) as Id_Row,
*
into #RT_Apoyo_p_coaseg
from	(
		select distinct
		pol_h_A.poliza,
		pol_h_A.certificado,
		pol_h_A.SUCURSAL_PROD,
		pol_h_A.RAMO_PROD,
		--pol_h_A.documento,
		pol_h_A.RECIBO,
		pol_h_A.VR_P_COASEGURO
		from Liberty.PROD.DWH_POLIZAS_H as pol_h_A
		where
		pol_h_A.tipo_coaseguro=1
		and pol_h_A.PERIODO_CONTABLE>=@periodo_contable
		) as clasi

CREATE INDEX IDX_p_coaseg
ON #RT_Apoyo_p_coaseg(poliza,certificado,RECIBO)
