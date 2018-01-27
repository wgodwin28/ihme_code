//filename: disaggregate_categories.do
//Purpose: disaggregate categories that are too aggregate and are not consistent with 


**define program name and syntax
capture program drop disaggregate_categories_san
program define disaggregate_categories_san

syntax, filename(string)

**BEL- RHS**
if "`filename'"=="BLZ_RHS_1991_WN_Y2011M02D24.DTA" {
	replace t_type_i = 0.4667 if t_type_lab=="pit latrine" /*open/closed pit*/
	}

if "`filename'"=="BLZ_RHS_1999_WN.DTA" {
	replace t_type_i = 0 if t_type_lab==""
	}

**KGZ-IPUMS**
if regexm("`filename'", "KGZ_CENSUS_1999_WATER_SANITATION.DTA")	{
	replace t_type_i = 0.959 if t_type_lab == "Not connected to sewage disposal system" /*other improved : unimproved*/
	}

**TUR**
if regexm("`filename'", "TUR_CENSUS_2000_WATER_SANITATION_Y2012M06D19.DTA") {
	replace t_type_i = 0.5422 if t_type_lab == "Non-flush, other and unspecified" /*other improved/unimproved*/
	}
	
**DOM**
if regexm("`filename'", "DOM_MICS2_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.911 if t_type_lab == "letrina tradicional"
	}
	
**GUY**
	if regexm("`filename'", "GUY_MICS3_2006_2007_HH_Y2009M04D06.DTA") {
	**replace t_type_i = 0.824 if t_type_lab == "open latrine" /*open pit/closed pit*/
	replace t_type_i = 0.824 if t_type_lab == "traditional pit latrine"
	}
	
	if regexm("`filename'", "GUY_MICS2_2000_HH_Y2008M09D23.DTA") {
	**replace t_type_i = 0.824 if t_type_lab == "open latrine" /*open pit/closed pit*/
	replace t_type_i = 0.824 if t_type_lab == "traditional pit latrine"
	}

	if regexm("`filename'", "guyana_1993.dta") {
	replace t_type_i = 0.824 if t_type_lab == "pit latrine" /*open pit/closed pit*/
	}
	
**TTO**
 if regexm("`filename'", "TTO_MICS2_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.946 if t_type_lab == "open latrine" /*improved pit/unimproved pit*/
	}
	
 if regexm("`filename'", "TTO_DHS1_1987_WN_Y2008M09D23.DTA") {
	replace t_type_i = 0.946 if t_type_lab == "open latrine" /*improved pit/unimproved pit*/
	}
	
**ARM**
 if regexm("`filename'", "ARM_DHS4_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.841 if t_type_lab == "open latrine"
	}
	
**AZE**
if regexm("`filename'", "AZE_DHS5_2006_HH_Y2008M09D23.DTA")	{
	replace t_type_i = 0.7522 if t_type_lab == "open latrine"
	}
	
**GEO**
if regexm("`filename'", "GEO_RHS_2005_HH.DTA") {
	replace t_type_i = 0.9472 if t_type_lab == "open latrine"
}

**KAZ**
if regexm("`filename'", "KAZ_DHS3_1995_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.989 if t_type_lab == "open latrine" /*closed/open pit*/
	}

if regexm("`filename'", "KAZ_DHS4_1999_HH_Y2008M09D23.DTA")	{
	replace t_type_i = 0.989 if t_type_lab == "open latrine" /*closed/open pit*/
	}

if regexm("`filename'", "kazakhstan_1996.dta")	{	
	replace t_type_i = 0.978 if t_type_lab == "open latrine" /*other improved/unimproved*/
	}
	
**KGZ**
if regexm("`filename'", "KGZ_DHS3_1997_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.965 if t_type_lab == "open latrine" /*open/closed pit*/
}

if regexm("`filename'", "kyrgyzstan_1996.dta") {
	replace t_type_i = 0.965 if t_type_lab == "open latrine"
}

if regexm("`filename'", "kyrgyzstan_1997.dta") {
	replace t_type_i = 0.965 if t_type_lab == "open latrine"
}

if regexm("`filename'", "kyrgyzstan_1998.dta") {
	replace t_type_i = 0.965 if t_type_lab == "open latrine"
}

if regexm("`filename'", "KGZ_CENSUS_1999_WATER_SANITATION.DTA") {
	replace t_type_i = 0.959 if t_type_lab == "unimproved, other" /*other improved/unimproved*/
}

**MNG**
if regexm("`filename'", "MNG_MICS2_2000_HH_Y2008M09D23.DTA") {
	**replace t_type_i = 0.841 if t_type_lab == "traditional pit latrine" /*open / closed pit*/
	replace t_type_i = 0.841 if t_type_lab == "open latrine" /*open / closed pit*/
	}

if regexm("`filename'", "MNG_CENSUS_1989_WATER_SANITATION.DTA") {
	replace t_type_i = 0 if t_type_lab == "missing"
	}
	
if regexm("`filename'", "MNG_CENSUS_2000_WATER_SANITATION.DTA") {
	replace t_type_i = 0 if t_type_lab == "missing"
}

**UZB**
if regexm("`filename'", "UZB_MICS2_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.9875 if t_type_lab == "open latrine"
	}
	
if regexm("`filename'", "UZB_SP_DHS4_2002_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.9875 if t_type_lab == "open latrine"
	}
	
if regexm("`filename'", "UZB_DHS3_1996_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.9875 if t_type_lab == "open latrine"
	}	

**TJK**
if regexm("`filename'", "TJK_MICS2_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.934 if t_type_lab == "traditional pit latrine"
	}

if regexm("`filename'", "tajikistan_2007.dta") {
	replace t_type_i = 0.934 if t_type_lab == "open latrine"
	}
	
**ALB**
if regexm("`filename'", "ALB_MICS3_2005_HH_Y2009M08D03.DTA") {
	replace t_type_i = 0.908 if t_type_lab=="open latrine"
	}
	
**BIH**
if regexm("`filename'", "bosnia herzegovina_2001.dta") {
	replace t_type_i = 0.843 if t_type_lab == "open latrine"
}

**GTM**
if regexm("`filename'", "GTM_DHS1_1987_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.937 if t_type_lab == "open latrine"
	}
	
if regexm("`filename'", "GTM_DHS3_1995_HH_Y2008M09D23.DTA")	{
	replace t_type_i = 0.937 if t_type_lab == "open latrine"
	}
if regexm("`filename'", "GTM_ITR_DHS4_1998_1999_HH_Y2010M04D02.DTA") {
	replace t_type_i = 0.937 if t_type_lab == "open latrine"
	}
	
**MEX**
if regexm("`filename'", "MEX_CENSUS_1990_WATER_SANITATION.DTA") {
	replace t_type_i = 0.918 if t_type_lab == "unimproved, other"
}

if regexm("`filename'", "MEX_CENSUS_2010_WATER_SAN_Y2014M03D26.DTA") {
	replace t_type_i = 0.918 if t_type_lab == "unimproved, other"
}

**NIC** - use ratio of regional neighbor GTM
if regexm("`filename'", "NIC_DHS3_1997_1998_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.937 if t_type_lab == "open latrine"
	}
	
if regexm("`filename'", "NIC_DHS4_2001_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.937 if t_type_lab == "open latrine"
	}
	
if regexm("`filename'", "nicaragua_2001.dta") {
	replace t_type_i = 0.937 if t_type_lab == "open latrine"
	}
	
if regexm("`filename'", "nicaragua_2005.dta") {
	replace t_type_i = 0.937 if t_type_lab == "open latrine"
	}
	
if regexm("`filename'", "NIC_RHS_1992_1993_WN.DTA") {
	replace t_type_i = 0.937 if t_type_lab == "open latrine"
	}
	
if regexm("`filename'", "NIC_RHS_2006_2007_WN.DTA") {
	replace t_type_i = 0.937 if t_type_lab == "open latrine"
	}
	
**PAN** - use regional (GTM) ratio of closed/open pit
if regexm("`filename'", "panama_2003.dta")	{
	replace t_type_i = 0.937 if t_type_lab == "open latrine"
	}
	
if regexm("`filename'", "panama_2008.dta")	{
	replace t_type_i = 0.937 if t_type_lab == "open latrine"
	}
	
**SLV**
if regexm("`filename'", "SLV_RHS_1988_WN_Y2011M02D01.DTA") {
	replace t_type_i = 0.9744 if t_type_lab == "open latrine" /*open/closed pit*/
	}
	
if regexm("`filename'", "SLV_RHS_1993_WN_Y2011M01D25.DTA") {
	replace t_type_i = 0.9744 if t_type_lab == "open latrine"
	}
	
if regexm("`filename'", "SLV_RHS_1998_WN_Y2011M01D25.DTA") {
	replace t_type_i = 0.9744 if t_type_lab == "open latrine"
	}

if regexm("`filename'", "SLV_RHS_2002_2003_WN_Y2011M01D25.DTA") {
	replace t_type_i = 0.9744 if t_type_lab == "open latrine"
	}

**ECU**
if regexm("`filename'", "ECU_RHS_1994_WN_Y2011M01D26.DTA") {
	replace t_type_i = 0.818 if t_type_lab == "open latrine" /*improved/unimproved latrine*/
	}

if regexm("`filename'", "ECU_RHS_2004_WN_Y2011M02D16.DTA") {
	replace t_type_i = 0.832 if t_type_lab == "open latrine" /*improved/unimproved pit*/
	}

**PER**
if regexm("`filename'", "PER_DHS3_1996_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.999 if t_type_lab == "open latrine"
	}

if regexm("`filename'", "PER_DHS4_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.999 if t_type_lab == "own pit toilet/latrine"
	replace t_type_i = 0.999 if t_type_lab == "share pit toilet/letrine"
	}

**MDA**
if regexm("`filename'", "MDA_MICS2_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.575 if t_type_lab == "traditional pit latrine"
	}

*********************************
*****AFRICA******
*********************************

**COG**
if regexm("`filename'", "COG_DHS5_2005_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.238 if t_type_lab == "traditional pit toilet"
	}
	

**BDI**
if regexm("`filename'", "BDI_MICS2_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.272 if t_type_lab == "traditional pit latrine"
	}

**COM**
if regexm("`filename'", "COM_MICS2_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.292 if t_type_lab == "latrine traditionnelle"
	}

if regexm("`filename'", "COM_DHS3_1996_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.292 if t_type_lab == "trad. pit toilet"
	}
	
**ETH**
if regexm("`filename'", "ETH_DHS4_2000_HH_Y2008M10D22.DTA") {
	replace t_type_i = 0.3726 if t_type_lab=="traditional pit latrine"
	}
	
**KEN**
if regexm("`filename'", "KEN_DHS1_1988_1989_WN_Y2012M04D24.DTA") {
	replace t_type_i = 0.358 if t_type_lab == "pit latrine"
	}

if regexm("`filename'", "KEN_DHS4_2003_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.358 if t_type_lab == "traditional pit toilet"
	}
	
if regexm("`filename'", "KEN_DHS3_1993_HH_Y2008M09D23.DTA")	{
	replace t_type_i = 0.358 if t_type_lab == "trad. pit toilet"
	}
	
if regexm("`filename'",  "KEN_DHS3_1998_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.358 if t_type_lab == "trad. pit toilet"
	} 
	
if regexm("`filename'",  "KEN_MICS2_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.358 if t_type_lab == "traditional pit latrine"
	}
	
if regexm("`filename'", "KEN_CENSUS_1989_WATER_SANITATION.DTA") {
	replace t_type_i = 0.358 if  t_type_lab == "Pit latrine"
	}
	
if regexm("`filename'", "KEN_CENSUS_1999_WATER_SANITATION.DTA") {
	replace t_type_i = 0.358 if t_type_lab == "Pit-latrine"
	}
	
**MDG**
if regexm("`filename'", "MDG_DHS2_1992_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.05 if t_type_lab == "trad. pit toilet"
	replace t_type_i = 0 if t_type_lab == "lavaka voavoatra"
}
if regexm("`filename'", "MDG_DHS3_1997_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.05 if t_type_lab == "traditional pit toilet"
}

if regexm("`filename'", "MDG_DHS4_2003_2004_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.05 if t_type_lab == "traditional pit toilet"
	replace t_type_i = 0.05 if t_type_lab == "pit latrine with drainage"
}

if regexm("`filename'", "MDG_MICS2_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.05 if t_type_lab == "latrine traditionnelle"
	}
	
**MWI**
if regexm("`filename'", "MWI_DHS2_1992_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.081 if t_type_lab == "trad. pit toilet"
	}
	
if regexm("`filename'", "MWI_DHS4_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.081 if t_type_lab == "traditional pit toilet"
	}
	
if regexm("`filename'", "MWI_DHS4_2004_2005_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.081 if t_type_lab == "traditional pit toilet"
	}
	
**RWA**

if regexm("`filename'", "RWA_DHS2_1992_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.759 if t_type_lab=="pit toilet /latrine"
	}
	
if regexm("`filename'", "RWA_DHS4_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.760 if t_type_lab ==  "traditional pit toilet"
	}
	
if regexm("`filename'","RWA_DHS4_2005_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.760 if t_type_lab == "latrine"
	}
	
if regexm("`filename'", "RWA_ITR_DHS5_2007_2008_HH_Y2010M08D25.DTA") {
	replace t_type_i = 0.760 if t_type_lab == "traditional pit toilet"
	}
	
if regexm("`filename'", "RWA_MICS2_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.760 if t_type_lab == "latrines traditionnelles"
	}
	
if regexm("`filename'", "RWA_CENSUS_1991_WATER_SANITATION.DTA"){
	replace t_type_i = 0.760 if t_type_lab == "Pit latrine, individual"
	replace t_type_i = 0.760 if t_type_lab == "Pit latrine, shared"
	}

if regexm("`filename'", "RWA_CENSUS_2002_WATER_SANITATION.DTA"){
	replace t_type_i = 0.760 if t_type_lab == "Pit latrine, individual"
	replace t_type_i = 0.760 if t_type_lab == "Pit latrine, shared"
	}

**TZA**
if regexm("`filename'", "TZA_CENSUS_2002_WATER_SANITATION.DTA") {
	replace t_type_i = 0.221 if t_type_lab == "Traditional pit latrine" /*improved/unimproved pit*/
	}

if regexm("`filename'", "TZA_CENSUS_1988_WATER_SANITATION.DTA") {
	replace t_type_i = 0.221 if t_type_lab == "Pit"
	}
	
if regexm("`filename'","TZA_DHS4_2004_2005_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.196 if t_type_lab == "traditional pit toilet" /*open/closed pit*/
	}

if regexm("`filename'", "TZA_DHS4_1999_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.196 if t_type_lab == "trad. pit toilet" 
	}
	
if regexm("`filename'", "TZA_DHS3_1996_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.196 if t_type_lab == "trad. pit toilet"
	}
	
if regexm("`filename'",	"TZA_DHS2_1991_1992_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.196 if t_type_lab == "trad. pit toilet"
	}
	
if regexm("`filename'",	"hbs_tanzania_1991.dta") {
	replace t_type_i = 0.196 if t_type_lab == "Pit latrine"
	}
	
if regexm("`filename'",	"hbs_tanzania_2000.dta") {
	replace t_type_i = 0.196 if t_type_lab == "Pit latrine"
	}

if regexm("`filename'",	"hbs_tanzania_2007.dta") {
	replace t_type_i = 0.196 if t_type_lab == "Pit latrine (traditional)"
	}

**UGA**
if regexm("`filename'", "UGA_DHS4_2000_2001_HH_Y2008M10D22.DTA") {
	replace t_type_i = 0.262 if t_type_lab == "traditional pit toilet"
	}
	
if regexm("`filename'", "UGA_DHS3_1995_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.262 if t_type_lab == "trad. pit toilet"
	}
	
if regexm("`filename'", "UGA_DHS1_1988_1989_WN_Y2008M09D23.DTA") {
	replace t_type_i = 0.262 if t_type_lab == "Latrine, Pit"
	}
	
if regexm("`filename'", "UGA_CENSUS_1991_WATER_SANITATION.DTA") {
	replace t_type_i = 0.262 if t_type_lab == "Pit latrine, not shared"
	replace t_type_i = 0.262 if t_type_lab == "Pit latrine, shared"
	}

end
