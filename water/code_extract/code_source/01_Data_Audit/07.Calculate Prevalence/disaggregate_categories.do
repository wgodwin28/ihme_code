//filename: disaggregate_categories.do
//Purpose: disaggregate categories that are too aggregate and are not consistent with 


**define program name and syntax
capture program drop disaggregate_categories
program define disaggregate_categories

syntax, filename(string)


**KGZ**
if regexm("`filename'", "KGZ_CENSUS_1999_WATER_SANITATION.DTA")	{
	replace w_srcedrnk_i = 0.761 if w_sd_lab=="No piped water" /*other improved/unimproved*/
	
	}
	
**MAR**
if regexm("`filename'", "MAR_CENSUS_1982_WATER_SANITATION_Y2012M06D19.DTA")	{
	replace w_srcedrnk_i = 0.443 if w_sd_lab=="No piped water" /*other improved/unimproved*/
	
	}
	
if regexm("`filename'", "MAR_CENSUS_1994_WATER_SANITATION_Y2012M06D19.DTA")	{
	replace w_srcedrnk_i = 0.443 if w_sd_lab=="No piped water" /*other improved/unimproved*/
	
	}
	
if regexm("`filename'", "MAR_CENSUS_2004_WATER_SANITATION_Y2012M06D19.DTA")	{
	replace w_srcedrnk_i = 0.443 if w_sd_lab=="No piped water" /*other improved/unimproved*/
	
	}
	
if regexm("`filename'", "morocco_1991.dta") {
	replace w_srcedrnk_i = 0.733 if w_sd_lab=="puits/source/metfia/duer"

	}

**TUR**
if regexm("`filename'", "TUR_CENSUS_2000_WATER_SANITATION_Y2012M06D19.DTA") {
	replace w_srcedrnk_i = 0.446 if w_sd_lab=="No piped water" /*other improved/unimproved*/
	**replace t_type_i = 0.5422 if t_type_lab = "Non-flush, other and unspecified" /*other improved/unimproved*/
	
	}
	
**VNM**
if regexm("`filename'", "VNM_CENSUS_1989_WATER_SANITATION.DTA") {
	replace w_srcedrnk_i = 0.876 if w_sd_lab=="Well" /*Private : Public wells*/
	replace w_srcedrnk_i = 0.7899 if w_sd_lab=="Unknown" /*improved/unimproved*/	
	
	}
	
**MLI**
if regexm("`filename'", "MLI_CENSUS_1987_WATER_SANITATION.DTA") {
	replace w_srcedrnk_i = 0.295 if w_sd_lab == "Deep well, shallow well" /* protected well : unprotected well*/
	
	}

if regexm("`filename'", "MLI_CENSUS_1998_WATER_SANITATION.DTA") {
	replace w_srcedrnk_i = 0.292 if w_sd_lab == "Deep well" /* protected well : unprotected well*/
	replace w_srcedrnk_i = 0.292 if w_sd_lab == "Shallow well" /* protected well : unprotected well*/
	
	}
	
**KHM**
if regexm("`filename'", "KHM_CENSUS_1998_WATER_SANITATION.DTA") {
	replace w_srcedrnk_i = 0.125 if w_sd_lab == "Dug well" /*protected well: unprotected well*/
	replace w_srcedrnk_i = 0.028 if w_sd_lab=="Spring, river" /*protected spring : unprotected spring*/
	
	}

if regexm("`filename'", "KHM_CENSUS_2008_WATER_SANITATION.DTA") {	
	replace w_srcedrnk_i = 0.0098 if w_sd_lab == "Spring, river"
	
	}
	
	
**TZA**
if regexm("`filename'", "TZA_CENSUS_1988_WATER_SANITATION.DTA") {
	replace w_piped_i = 0.402 if w_sd_lab == "Outside piped" /* piped into yard/plot: overall piped outside*/
	replace w_srcedrnk_i = 0.362 if w_sd_lab == "Well water in plot or village"
	replace w_srcedrnk_i = 0.362 if w_sd_lab == "Well water outside village"
	replace w_srcedrnk_i = 0.244 if w_sd_lab == "Other inside plot or village"
	replace w_srcedrnk_i = 0.244 if w_sd_lab == "Other outside plot or village"
	replace w_srcedrnk_i = 0 if w_sd_lab == "Unknown"
	}

if regexm("`filename'", "TZA_CENSUS_2002_WATER_SANITATION.DTA") {
	replace w_piped_i = 0.498 if w_sd_lab == "Piped water"  /*piped into dwelling/yard/plot: overall piped outside*/
	}
	
if regexm("`filename'", "TZA_DHS3_1996_HH_Y2008M09D23.DTA") {
	replace w_srcedrnk_i = 0.554 if w_sd_lab == "public /private well" /*pro/unpro well*/
	replace w_srcedrnk_i = 0.554 if w_sd_lab == "well in residence"
	replace w_srcedrnk_i = 0.383 if w_sd_lab == "spring"
	}
	
if regexm("`filename'", "TZA_DHS2_1991_1992_HH_Y2008M09D23.DTA") {
	replace w_srcedrnk_i = 0.554 if w_sd_lab ==  "public well"
	replace w_srcedrnk_i = 0.554 if w_sd_lab == "well in residence" /*pro/unpro well*/
	replace w_srcedrnk_i = 0.383 if w_sd_lab == "spring" /*pro/unpro spring*/
	}
	
if regexm("`filename'", "hbs_tanzania_1991.dta") {
	replace w_piped_i = 0 if w_sd_lab == "Piped water on community supply"
	}
	
if regexm("`filename'", "hbs_tanzania_2000.dta") {
	replace w_piped_i = 1 if (w_sd_lab == "Priv. in house"  | w_sd_lab == "Priv. outside")
	}
	
if regexm("`filename'", "hbs_tanzania_2007.dta") {
	replace w_piped_i = 0 if w_sd_lab == "Piped water on community supply"
	}
	
**MNE**
if regexm("`filename'", "MNE_MICS3_2005_2006_HH_Y2008M09D23.DTA") {
	replace w_srcedrnk_i = 1 if w_sd_lab == "local watersupply"
	replace w_srcedrnk_i = 1 if w_sd_lab == "public watersupply"
	}
	
**SRB**
if regexm("`filename'", "SRB_MICS3_2005_2006_HH_Y2008M09D23.DTA") {
	replace w_srcedrnk_i = 1 if w_sd_lab == "local watersupply"
	replace w_srcedrnk_i = 1 if w_sd_lab == "public watersupply"
	}
	
**MEX**
if regexm("`filename'", "mxfls_mexico_2002.dta") {
	replace w_srcedrnk_i = 1 if w_sd_lab == "decanter"
	}

if regexm("`filename'", "enigh_mexico_1992.dta") {
	replace w_piped_i = 1 if w_sd_lab == "agua entubada fuera de la vivienda pero si en el edificio, vecindad o terreno"
	}
	
if regexm("`filename'", "enigh_mexico_1994.dta") {
	replace w_piped_i = 1 if w_sd_lab == "agua entubada fuera de la vivienda pero si en el edificio, vecindad o terreno"
	}
	
if regexm("`filename'", "enadid_mexico_2009.dta") {
	replace w_piped_i = 1 if w_sd_lab == "tiene agua de la red publica fuera de la vivienda, pero dentro del terreno"
	}

if regexm("`filename'", "MEX_CENSUS_2010_WATER_SAN_Y2014M03D26.DTA") {
	replace w_srcedrnk_i = 0.893 if w_sd_lab == "Water from a well, river, lake, stream or another source"
	}

/**SLV**
 if regexm("`filename'", "SLV_CENSUS_1992_WATER_SANITATION_Y2012M06D19.DTA") {
	replace w_srcedrnk_i = if w_sd_lab == "Public well"
	replace w_srcedrnk_i = if w_sd_lab == "Private well"
	replace w_srcedrnk_i = if w_sd_lab == "Spring"
	}
	
 if regexm("`filename'", "SLV_CENSUS_2007_WATER_SAN_Y2013M03D26.DTA") {
	 replace w_srcedrnk_i = if w_sd_lab == "Public well"
	 replace w_srcedrnk_i = if w_sd_lab == "Private well"
	}*/
	
**NIC**
if regexm("`filename'", "NIC_DHS4_2001_HH_Y2008M09D23.DTA") {
	replace w_srcedrnk_i = 1 if w_sd_lab == "outside dwelling / within resinct"
	}
	
if regexm("`filename'", "NIC_CENSUS_1995_WATER_SANITATION_Y2012M06D19.DTA") {
	replace w_srcedrnk_i = 0.446 if w_sd_lab == "No piped water"
	}
	
if regexm("`filename'", "NIC_CENSUS_2005_WATER_SANITATION_Y2012M06D19.DTA") {
	replace w_srcedrnk_i = 0.446 if w_sd_lab == "No piped water"
	}

**BLR**
if regexm("`filename'", "BLR_CENSUS_1999_WATER_SANITATION.DTA") {
	replace w_srcedrnk_i = 0.906 if w_sd_lab == "No piped water"
	}
	
**TUN**
if regexm("`filename'", "TUN_DHS1_1988_WN_Y2008M09D23.DTA") {
	replace w_srcedrnk_i = 1 if w_sd_lab == "sonede"
	replace w_piped_i = 1 if w_sd_lab=="sonede"
	replace w_srcedrnk = 0.579 if w_sd_lab == "puits.public/priv."
	}
	
**DJI**
if regexm("`filename'", "papfam_djibouti_2002.dta") {
	replace w_srcedrnk_i = 0.255 if w_sd_lab == "other"
	}
	
**RWA**
if regexm("`filename'", "RWA_ITR_DHS5_2007_2008_HH_Y2010M08D25.DTA") {
	replace w_srcedrnk_i = 0.728 if w_sd_lab == "spring"
	}
	
if regexm("`filename'", "RWA_DHS4_2005_HH_Y2008M09D23.DTA") {
	replace w_srcedrnk_i = 0.728 if w_sd_lab == "spring"
	}

if regexm("`filename'", "RWA_DHS4_2000_HH_Y2008M09D23.DTA") {
	replace w_srcedrnk_i = 0.728 if w_sd_lab == "spring"
	}

if regexm("`filename'", "RWA_DHS2_1992_HH_Y2008M09D23.DTA") {
	replace w_srcedrnk_i = 0.728 if w_sd_lab == "spring"
	}

if regexm("`filename'", "RWA_CENSUS_1991_WATER_SANITATION.DTA") {
	replace w_srcedrnk_i = 0.725 if w_sd_lab == "Spring/well, built"
	replace w_srcedrnk_i = 0.725 if w_sd_lab == "Spring/well, natural"
	}
	
**GHA**
if regexm("`filename'", "GHA_DHS4_1998_1999_HH_Y2008M09D23.DTA") {
	replace w_piped_i = 0 if w_sd_lab == "public tap/neighbours house"
	}
	
if regexm("`filename'", "GHA_SP_DHS5_2007_2008_HH_PH2_Y2009M06D01.DTA") {
	replace w_piped_i = 0.328 if w_sd_lab == "piped water" 
	}

if regexm("`filename'", "gcls_ghana_2001.dta") {
	replace w_piped_i = 0.328 if w_sd_lab == "pipe-borne outside house"
	}
	
if regexm("`filename'", "GHA_CENSUS_2000_WATER_SANITATION.DTA") {
	replace w_piped_i = 0.328 if w_sd_lab == "Pipe-borne outside"
	}
	
**BWA**
if regexm("`filename'", "BWA_DHS1_1988_WN_Y2008M09D23.DTA") {
	replace w_piped_i = 0 if w_sd_lab == "pipe outside plot"
	}
	
**SDN**
if regexm("`filename'", "SDN_DHS1_1989_1990_WN_Y2008M09D23.DTA") {
	replace w_piped_i = 0.736 if w_sd_lab == "piped outside"
	}
	
**IDN**
if regexm("`filename'", "IDN_DHS1_1987_WN_Y2008M09D23.DTA") {
	replace w_srcedrnk_i = 1 if w_sd_lab == "Pump" 
	replace w_srcedrnk_i = 0.591 if w_sd_lab=="Well" /*pro/unpro well*/
	replace w_srcedrnk_i = 0.477 if w_sd_lab=="Spring" /*pro/unpro spring*/
	}

if regexm("`filename'", "IDN_DHS2_1991_HH_Y2008M09D23.DTA")	{
	replace w_srcedrnk_i = 1 if w_sd_lab == "pump" 
	replace w_srcedrnk_i = 0.591 if w_sd_lab=="well" /*pro/unpro well*/
	replace w_srcedrnk_i = 0.477 if w_sd_lab=="spring" /*pro/unpro spring*/
	}
	
if regexm("`filename'", "IDN_DHS4_2002_2003_HH_Y2008M09D23.DTA")	{
	replace w_srcedrnk_i = 0.477 if w_sd_lab=="spring" /*pro/unpro spring*/
	}
	
if regexm("`filename'", "IDN_DHS5_2007_HH_Y2009M05D05.DTA")	{
	replace w_srcedrnk_i = 0.477 if w_sd_lab=="spring" /*pro/unpro spring*/
	}
	
if regexm("`filename'", "IDN_DHS6_2012_HH_Y2013M09D25.DTA") {
	replace w_srcedrnk_i = 0.477 if w_sd_lab=="spring" /*pro/unpro spring*/
	replace w_srcedrnk_i = 1 if w_sd_lab == "refill water"
	}
	
if regexm("`filename'", "IDN_DHS_2012_HH_AGE_CORRECTED_Y2013M10D02.DTA")	{
	replace w_srcedrnk_i = 0.477 if w_sd_lab=="spring" /*pro/unpro spring*/
	replace w_srcedrnk_i = 1 if w_sd_lab == "refill water"
	}

if regexm("`filename'", "IDN_CENSUS_1980_WATER_SAN_Y2014M03D26.DTA") {
	replace w_srcedrnk_i = 0.591 if w_sd_lab == "Well" /*pro/unpro well*/
	replace w_srcedrnk_i = 0.477 if w_sd_lab== "Spring" /*pro/unpro spring*/
	}
	
if regexm("`filename'", "IDN_INTERCENSAL_POP_SURVEY_SUPAS_1985_WATER_SAN_Y2014M03D26.DTA") {
	replace w_srcedrnk_i = 0.591 if w_sd_lab == "Well" /*pro/unpro well*/
	replace w_srcedrnk_i = 0.477 if w_sd_lab== "Spring" /*pro/unpro spring*/
	}
	
if regexm("`filename'", "IDN_CENSUS_1990_WATER_SAN_Y2014M03D26.DTA") {
	replace w_srcedrnk_i = 0.591 if w_sd_lab == "Well" /*pro/unpro well*/
	replace w_srcedrnk_i = 0.477 if w_sd_lab== "Spring" /*pro/unpro spring*/
	}

	if regexm("`filename'", "IDN_INTERCENSAL_POP_SURVEY_SUPAS_1995_WATER_SAN_Y2014M03D26.DTA") {
	replace w_srcedrnk_i = 0.591 if w_sd_lab == "Well" /*pro/unpro well*/
	replace w_srcedrnk_i = 0.477 if w_sd_lab== "Spring" /*pro/unpro spring*/
	}
	
	if regexm("`filename'", "susenas_indonesia_2009.dta") {
	replace w_srcedrnk_i = 1 if w_sd_lab == "Water refill"
	}
	
	if regexm("`filename'", "susenas_indonesia_2010.dta") {
	replace w_srcedrnk_i = 1 if w_sd_lab == "Water refill"
	}

**THA**
	if regexm("`filename'", "nangrong_thailand_1984.dta") {
	replace w_srcedrnk_i = 0.703 if w_sd_lab == "dug well" /*pro/unpro well*/
	}
	
**NPL**
	if regexm("`filename'", "NPL_CENSUS_2001_WATER_SANITATION.DTA") {
	replace w_piped_i = 0.281 if w_sd_lab=="Tap (pipe)" /*standpipe and household connections*/
	}
	
	if regexm("`filename'", "NPL_DHS4_2001_HH_Y2008M10D22.DTA") {
	replace w_piped_i = 0 if w_sd_lab ==  "public/nieghbor's tap"
	}
	
**PHL**
	if regexm("`filename'", "PHL_CENSUS_1990_WATER_SANITATION.DTA") {
	replace w_piped_i = 0.515 if w_sd_lab == "Shared faucet" /*standpipe and hhconnection in yard/plot*/
	}

	if regexm("`filename'", "PHL_CENSUS_2000_WATER_SANITATION.DTA") {
	replace w_piped_i = 0 if w_sd_lab == "Own use, tubed/piped deep well"
	replace w_piped_i = 0.515 if w_sd_lab == "Shared, faucet, community water system" /*standpipe and hhconnection in yard/plot*/
	}
	
	if regexm("`filename'", "PHL_DHS3_1993_HH_Y2008M09D23.DTA") {
	replace w_piped_i = 0 if w_sd_lab == "faucet not in reside"
	}
	
**PRI**
	if regexm("`filename'", "PRI_RHS_1995_1996_WN_Y2011M01D25.DTA") {
	replace w_srcedrnk_i = 1 if w_sd_lab == "de la pluma"
	}
	
**BOL**
	if regexm("`filename'", "BOL_CENSUS_1992_WATER_SANITATION.DTA") {
	replace w_srcedrnk_i = 0.228 if w_sd_lab == "Well or water wheel" /*pro/unpro well*/
	}
	
	if regexm("`filename'", "BOL_CENSUS_2001_WATER_SANITATION.DTA") {
	replace w_srcedrnk_i = 0.228 if w_sd_lab == "Well or water wheel with pump"
	replace w_srcedrnk_i = 0.228 if w_sd_lab == "Well or water wheel without pump"
	}
	
	if regexm("`filename'", "BOL_DHS3_1993_1994_HH_Y2008M09D23.DTA") {
	replace w_srcedrnk_i = 0.228 if w_sd_lab == "well in residence"
	}
	
	if regexm("`filename'", "BOL_DHS3_1998_HH_Y2008M09D23.DTA") {
	replace w_srcedrnk_i = 0.228 if w_sd_lab=="well or water wheel"
	}
	
	if regexm("`filename'", "eih_bolivia_1990.dta") {
	replace w_piped_i = 0 if w_sd_lab == "Fuera viv.y edif."
	}

	if regexm("`filename'", "eih_bolivia_1991.dta") {
	replace w_piped_i = 0 if w_sd_lab == "Fuera viv.y edif."
	}
	
	if regexm("`filename'", "eih_bolivia_1992.dta") {
	replace w_piped_i = 0 if w_sd_lab == "Fuera de vivienda"
	}
	
	if regexm("`filename'", "eih_bolivia_1993.dta") {
	replace w_piped_i = 0 if w_sd_lab == "Fuera viv. y edif."
	}
	
	if regexm("`filename'", "eih_bolivia_1994.dta") {
	replace w_piped_i = 0 if w_sd_lab == "Fuera viv.y edificio "
	}
	
**ECU**
	if regexm("`filename'", "ECU_CENSUS_1982_WATER_SANITATION.DTA") { 
	replace w_srcedrnk_i = 0.841 if w_sd_lab ==  "Well"
	}
	
	if regexm("`filename'", "ECU_CENSUS_1990_WATER_SANITATION.DTA") { 
	replace w_srcedrnk_i = 0.841 if w_sd_lab == "Well"
	}
	
	if regexm("`filename'", "ECU_CENSUS_2001_WATER_SANITATION.DTA") {
	replace w_srcedrnk_i = 0.841 if w_sd_lab == "Well"
	}
	
	if regexm("`filename'", "ECU_CENSUS_2010_WATER_SAN_Y2014M03D26.DTA") {
	replace w_srcedrnk_i = 0.841 if w_sd_lab ==  "Well"
	}
	
	if regexm("`filename'", "ecuador_1994.dta") {
	replace w_srcedrnk_i = 0.841 if w_sd_lab == "Well"
	}
	
	if regexm("`filename'", "ecuador_1995.dta") {
	replace w_srcedrnk_i = 0.841 if w_sd_lab == "Well"
	}
	
	if regexm("`filename'", "ecuador_1998.dta") {
	replace w_srcedrnk_i = 0.841 if w_sd_lab == "pozo"
	}
	
	
**PER**
	if regexm("`filename'", "PER_CENSUS_1993_WATER_SANITATION.DTA")  {
	replace w_srcedrnk_i = 0.593 if w_sd_lab == "Well"
	}
	
	if regexm("`filename'", "PER_CENSUS_2007_WATER_SANITATION.DTA") {
	replace w_srcedrnk_i = 0.593 if w_sd_lab == "Well"
	replace w_piped_i = 1 if w_sd_lab == "Public network outside the dwelling but within the building (potable water)"
	}
	
	if regexm("`filename'", "peru_1985.dta") {
	replace w_srcedrnk_i = 0.593 if w_sd_lab == "Well"
	}

**URY**
	if regexm("`filename'", "URY_CENSUS_1985_WATER_SAN_Y2014M03D26.DTA") {
	replace w_srcedrnk_i = 0.989 if w_sd_lab == "Spring/well"
	}
	
	if regexm("`filename'", "URY_CENSUS_1996_WATER_SAN_Y2014M03D26.DTA") {
	replace w_srcedrnk_i = 0.989 if w_sd_lab == "Well"
	}
	
	if regexm("`filename'", "URY_EXTENDED_NATIONAL_HOUSEHOLD_SURVEY_ENHA_2006_WATER_SAN_Y2014M03D26.DTA") {
	replace w_srcedrnk_i = 0.989 if w_sd_lab == "Well"
	}

	

**AZE**

**CAF**
	if regexm("`filename'", "CAF_DHS3_1994_1995_HH_Y2008M09D23.DTA") {
	replace w_srcedrnk_i = 0.245 if w_sd_lab == "spring" /*pro/unpro spring*/
	}
	
**KEN**
	if regexm("`filename'", "KEN_CENSUS_1999_WATER_SANITATION.DTA") { 
	replace w_srcedrnk_i = 0.410 if w_sd_lab == "Well" /*pro-unpro well*/
	replace w_srcedrnk_i = 0.410 if w_sd_lab == "Spring"
	}
	
	if regexm("`filename'", "KEN_CENSUS_1989_WATER_SANITATION.DTA") {
	replace w_srcedrnk_i = 0.410 if w_sd_lab == "Well"
	}
	
	if regexm("`filename'", "KEN_DHS1_1988_1989_WN_Y2012M04D24.DTA") {
		replace w_srcedrnk_i = 0.410 if w_sd_lab == "well with handpump"
		replace w_srcedrnk_i = 0.410 if w_sd_lab == "well without pump"
	}
	
	if regexm("`filename'", "KEN_DHS3_1993_HH_Y2008M09D23.DTA") {
		replace w_srcedrnk_i = 0.410 if w_sd_lab == "well with pump"
		replace w_srcedrnk_i = 0.410 if w_sd_lab == "well without pump"
	}
	
	if regexm("`filename'", "KEN_DHS4_2003_HH_Y2008M09D23.DTA") {
		replace w_srcedrnk_i = 0.410 if w_sd_lab == "spring"
	}

**LBR**
	if regexm("`filename'", "LBR_DHS1_1986_WN_Y2008M09D23.DTA") {
		replace w_piped_i = 0.346 if w_sd_lab == "outside pipe"
	}

**SEN**
	if regexm("`filename'", "SEN_CENSUS_1988_WATER_SANITATION.DTA") {
		replace w_piped_i = 0.455 if w_sd_lab == "Tap, outside house" /*public tap | tap in yard*/
	}

	if regexm("`filename'", "SEN_CENSUS_2002_WATER_SANITATION.DTA") {
		replace w_piped_i = 0.455 if w_sd_lab == "Tap, outside house" /*public tap | tap in yard*/
	}
	
**TGO**
	if regexm("`filename'", "TGO_DHS1_1988_WN_Y2008M09D23.DTA") {
		replace w_srcedrnk_i = 0.452 if w_sd_lab == "Puits, forage"
		replace w_piped_i = 0.501 if w_sd_lab=="piped elsewhere"
	}
	
	if regexm("`filename'", "TGO_MICS3_2006_HH_Y2008M09D23.DTA") {
		replace w_piped_i = 1 if w_sd_lab == "dans la concession/parcelle" 
	}
	
	if regexm("`filename'", "TGO_MICS4_2010_HH_Y2013M06D05.DTA") {
		replace w_piped_i = 1 if w_sd_lab=="Robinet dans concession, cour ou parcelle"
		}

**COD**

end
