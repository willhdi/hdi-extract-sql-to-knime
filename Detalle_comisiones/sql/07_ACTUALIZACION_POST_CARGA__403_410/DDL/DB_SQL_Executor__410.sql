-- Nodo KNIME : Detalle_comisiones\DB SQL Executor (#410)
-- Clave      : statement

USE Liberty_pruebas_actuaria


/**********************
Porcentaje comisiones
**********************/


drop table #comisiones
select  periodo_contable,
ramo_prod,poliza,certificado,
round(sum(vr_comision_bas)/nullif(sum(vr_prima_documento),0),3) as por
into #comisiones
from liberty.prod.dwh_pol_amp_h a1
where periodo_contable >= 202601 
group by periodo_contable,ramo_prod,poliza,certificado
order by ramo_prod,poliza,certificado

UPDATE a 
SET porcentaje = b.por
from liberty_pruebas_actuaria.dbo.pl_col_datos_coco_comisiones  a
left join #comisiones b on A.RAMO_PROD = B.RAMO_PROD  AND a.poliza = B.poliza
where  a.PERIODO_CONTABLE >= 202601 and Concepto_nivel_3 = 'Comision_intermediacion'


drop table #comisiones
select  periodo_contable,
ramo_prod,poliza,certificado,
round(sum(vr_comision_bas)/nullif(sum(vr_prima_documento),0),3) as por
into #comisiones_2
from liberty.prod.dwh_pol_amp_h a1
where periodo_contable >= 202601 and tipo_transaccion in (1,2,9)
group by periodo_contable,ramo_prod,poliza,certificado
order by ramo_prod,poliza,certificado

UPDATE a 
SET porcentaje = b.por
from liberty_pruebas_actuaria.dbo.pl_col_datos_coco_comisiones  a
left join #comisiones_2 b on A.RAMO_PROD = B.RAMO_PROD  AND a.poliza = B.poliza
where  a.PERIODO_CONTABLE >= 202601 and Concepto_nivel_3 = 'Comision_intermediacion' and porcentaje is null
