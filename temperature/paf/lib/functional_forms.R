cubspline <- list(
	eval = function(m1, m2, m3, m4, e1, e2, params){
		out <- ((params$beta_m1 * m1)+(params$beta_m2 * m2)+(params$beta_m3 * m3)+(params$beta_m4 * m4)+
			(params$beta_e1 * e1)+(params$beta_e2 * e2)+(params$beta_m1e1 * m1 * e1)+
			(params$beta_m2e1 * m2 * e1)+(params$beta_m3e1 * m3 * e1)+(params$beta_m4e1 * m4 * e1)+
			(params$beta_m1e2 * m1 * e2)+(params$beta_m2e2 * m2 * e2)+(params$beta_m3e2 * m3 * e2)+(params$beta_m4e2 * m4 * e2))}
)

cubspline.sdi.old <- list(
  eval = function(m1, m2, m3, m4, e1, e2, sdi, params){
    out <- ((params$beta_m1 * m1)+(params$beta_m2 * m2)+(params$beta_m3 * m3)+(params$beta_m4 * m4)+(params$beta_sdi * sdi)+
              (params$beta_e1 * e1)+(params$beta_e2 * e2)+(params$beta_m1e1 * m1 * e1)+
              (params$beta_m2e1 * m2 * e1)+(params$beta_m3e1 * m3 * e1)+(params$beta_m4e1 * m4 * e1)+
              (params$beta_m1e2 * m1 * e2)+(params$beta_m2e2 * m2 * e2)+(params$beta_m3e2 * m3 * e2)+(params$beta_m4e2 * m4 * e2)
              (params$beta_sdie1 * sdi * e1)+(params$beta_sdie2 * sdi * e2)+
              (params$beta_sdim1 * sdi * m1)+(params$beta_sdim2 * sdi * m2)+(params$beta_sdim3 * sdi * m3)+(params$beta_sdim4 * sdi * m4))}
)

cubspline.sdi.mmt4 <- list(
  eval = function(m1, m2, m3, m4, e1, e2, sdi, params){
    out <- ((params$mmt_S1 * m1)+(params$mmt_S2 * m2)+(params$mmt_S3 * m3)+(params$mmt_S4 * m4)+(params$sdi * sdi)+
              (params$dev_S1 * e1)+(params$dev_S2 * e2)+
              (params$`mmt_S1:dev_S1` * m1 * e1)+(params$`mmt_S2:dev_S1` * m2 * e1)+(params$`dev_S1:mmt_S3` * m3 * e1)+(params$`dev_S1:mmt_S4` * m4 * e1)+
              (params$`mmt_S1:dev_S2` * m1 * e2)+(params$`dev_S2:mmt_S2` * m2 * e2)+(params$`dev_S2:mmt_S3` * m3 * e2)+(params$`dev_S2:mmt_S4` * m4 * e2)+
              (params$`sdi:dev_S1` * sdi * e1)+(params$`dev_S2:sdi` * sdi * e2)+
              (params$`mmt_S1:sdi` * sdi * m1)+(params$`sdi:mmt_S2` * sdi * m2)+(params$`sdi:mmt_S3` * sdi * m3)+(params$`sdi:mmt_S4` * sdi * m4)+
              (params$`mmt_S1:dev_S2:sdi` * e2 * sdi * m1)+(params$`sdi:mmt_S2:dev_S1` * e1 * sdi * m2)+(params$`dev_S2:sdi:mmt_S3` * e2 * sdi * m3)+(params$`sdi:dev_S1:mmt_S4` * e1 * sdi * m4)+
              (params$`mmt_S1:sdi:dev_S1` * e1 * sdi * m1)+(params$`dev_S2:sdi:mmt_S2` * e2 * sdi * m2)+(params$`sdi:dev_S1:mmt_S3` * e1 * sdi * m3)+(params$`dev_S2:sdi:mmt_S4` * e2 * sdi * m4))}
)

cubspline.sdi.mmt3 <- list(
  eval = function(m1, m2, m3, e1, e2, sdi, params){
    out <- ((params$mmt_S1 * m1)+(params$mmt_S2 * m2)+(params$mmt_S3 * m3)+(params$sdi * sdi)+
              (params$dev_S1 * e1)+(params$dev_S2 * e2)+
              (params$`mmt_S1:dev_S1` * m1 * e1)+(params$`mmt_S2:dev_S1` * m2 * e1)+(params$`dev_S1:mmt_S3` * m3 * e1)+
              (params$`mmt_S1:dev_S2` * m1 * e2)+(params$`dev_S2:mmt_S2` * m2 * e2)+(params$`dev_S2:mmt_S3` * m3 * e2)+
              (params$`sdi:dev_S1` * sdi * e1)+(params$`dev_S2:sdi` * sdi * e2)+
              (params$`mmt_S1:sdi` * sdi * m1)+(params$`sdi:mmt_S2` * sdi * m2)+(params$`sdi:mmt_S3` * sdi * m3)+
              (params$`mmt_S1:dev_S2:sdi` * e2 * sdi * m1)+(params$`sdi:mmt_S2:dev_S1` * e1 * sdi * m2)+(params$`dev_S2:sdi:mmt_S3` * e2 * sdi * m3)+
              (params$`mmt_S1:sdi:dev_S1` * e1 * sdi * m1)+(params$`dev_S2:sdi:mmt_S2` * e2 * sdi * m2)+(params$`sdi:dev_S1:mmt_S3` * e1 * sdi * m3))}
)

cubspline.sdi.mmt3.nosdi <- list(
  eval = function(m1, m2, m3, e1, e2, sdi, params){
    out <- ((params$mmt_S1 * m1)+(params$mmt_S2 * m2)+(params$mmt_S3 * m3)+
              (params$dev_S1 * e1)+(params$dev_S2 * e2)+
              (params$`mmt_S1:dev_S1` * m1 * e1)+(params$`mmt_S2:dev_S1` * m2 * e1)+(params$`dev_S1:mmt_S3` * m3 * e1)+
              (params$`mmt_S1:dev_S2` * m1 * e2)+(params$`dev_S2:mmt_S2` * m2 * e2)+(params$`dev_S2:mmt_S3` * m3 * e2)+
              (params$`sdi:dev_S1` * sdi * e1)+(params$`dev_S2:sdi` * sdi * e2)+
              (params$`mmt_S1:sdi` * sdi * m1)+(params$`sdi:mmt_S2` * sdi * m2)+(params$`sdi:mmt_S3` * sdi * m3)+
              (params$`mmt_S1:dev_S2:sdi` * e2 * sdi * m1)+(params$`sdi:mmt_S2:dev_S1` * e1 * sdi * m2)+(params$`dev_S2:sdi:mmt_S3` * e2 * sdi * m3)+
              (params$`mmt_S1:sdi:dev_S1` * e1 * sdi * m1)+(params$`dev_S2:sdi:mmt_S2` * e2 * sdi * m2)+(params$`sdi:dev_S1:mmt_S3` * e1 * sdi * m3))}
)