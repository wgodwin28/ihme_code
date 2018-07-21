//filename: disaggregate_categories.do
//Purpose: disaggregate categories that are too aggregate and are not consistent with 


**define program name and syntax
capture program drop disaggregate_categories_san
program define disaggregate_categories_san

syntax, filename(string)

**BLZ- RHS**
if regexm("`filename'", "BLZ_RHS_1991_WN_Y2011M02D24.DTA") {
	replace t_type_i = 0.914 if t_type_lab=="pit latrine" /*open/closed pit*/
	}

if regexm("`filename'", "BLZ_RHS_1999_WN.DTA") {
	replace t_type_i = 0 if t_type_lab==""
	}

**KGZ-IPUMS**
if regexm("`filename'", "KGZ_CENSUS_1999_WATER_SANITATION.DTA")	{
	replace t_type_i = 0.959 if t_type_lab == "Not connected to sewage disposal system" /*other improved : unimproved*/
	}

if regexm("`filename'", "kyrgyzstan_1996.dta")	{
	replace t_type_i = 0.959 if t_type_lab == "outdoor latrine"
	}

if regexm("`filename'", "kyrgyzstan_1997.dta")	{
	replace t_type_i = 0.959 if t_type_lab == "outdoor latrine" 
	}

if regexm("`filename'", "kyrgyzstan_1998.dta") 	{
	replace t_type_i = 0.959 if t_type_lab == "outdoor latrine"
	}

if regexm("`filename'", "KGZ_DHS3_1997_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.979 if t_type_lab == "trad. pit toilet" /*open and closed pit*/
	}
	
**TUR**
if regexm("`filename'", "TUR_CENSUS_2000_WATER_SANITATION_Y2012M06D19.DTA") {
	replace t_type_i = 0.5422 if t_type_lab == "Non-flush, other and unspecified" /*other improved/unimproved*/
	}
	
**DOM**
if regexm("`filename'", "DOM_MICS2_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.911 if t_type_lab == "letrina tradicional"
	}
	
if regexm("`filename'", "DOM_DHS4_1999_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.911 if t_type_lab == "tradicional pit toilet/latrine"
	}
	
if regexm("`filename'", "DOM_DHS2_1991_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.891 if t_type_lab == "private latrine" /*private closed/open latrine*/
	replace t_type_i = 0.930 if t_type_lab == "public latrine" /*public closed/open latrine*/
	}
	
**GUY**
	if regexm("`filename'", "GUY_MICS3_2006_2007_HH_Y2009M04D06.DTA") {
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
	replace t_type_i = 0.946 if t_type_lab == "pit" /*improved pit/unimproved pit*/
	}
	
 if regexm("`filename'", "TTO_DHS1_1987_WN_Y2008M09D23.DTA") {
	replace t_type_i = 0.946 if t_type_lab == "pit" /*improved pit/unimproved pit*/
	}
	
**ARM**
 if regexm("`filename'", "ARM_DHS4_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.841 if t_type_lab == "trad. pit toilet"
	}
	
**AZE**
if regexm("`filename'", "AZE_MICS2_2000_HH_Y2008M09D23.DTA")	{
	replace t_type_i = 0.7522 if t_type_lab == "traditional pit latrine"
	}
	
**GEO**
if regexm("`filename'", "GEO_RHS_2005_HH.DTA") {
	replace t_type_i = 0.9472 if t_type_lab == "pit latirne"
}

**KAZ**
if regexm("`filename'", "KAZ_DHS3_1995_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.989 if t_type_lab == "trad. pit toilet" /*closed/open pit*/
	}

if regexm("`filename'", "KAZ_DHS4_1999_HH_Y2008M09D23.DTA")	{
	replace t_type_i = 0.989 if t_type_lab == "pit toilet/latrine" /*closed/open pit*/
	}

if regexm("`filename'", "kazakhstan_1996.dta")	{	
	replace t_type_i = 0.978 if t_type_lab == "letrine" /*other improved/unimproved*/
	replace t_type_i = 0.978 if t_type_lab == "open toilet"
	}
	

**MNG**
if regexm("`filename'", "MNG_MICS2_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.841 if t_type_lab == "traditional pit latrine" /*open / closed pit*/
	}

if regexm("`filename'", "MNG_CENSUS_1989_WATER_SANITATION.DTA") {
	replace t_type_i = 0 if t_type_lab == "NIU (not in universe)"
	**replace t_type_i = 0.696 if t_type_lab == "Outside of house"
	}
	
if regexm("`filename'", "MNG_CENSUS_2000_WATER_SANITATION.DTA") {
	replace t_type_i = 0 if t_type_lab == "NIU (not in universe)"
	**replace t_type_i = 0.696 if t_type_lab == "Outside of house"
}

**UZB**
if regexm("`filename'", "UZB_MICS2_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.9875 if t_type_lab == "traditional pit latrine"
	}
	
if regexm("`filename'", "UZB_SP_DHS4_2002_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.9875 if t_type_lab == "traditional pit toilet"
	}
	
if regexm("`filename'", "UZB_DHS3_1996_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.9875 if t_type_lab == "trad. pit toilet"
	}	

**TJK**
if regexm("`filename'", "TJK_MICS2_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.934 if t_type_lab == "traditional pit latrine"
	}

if regexm("`filename'", "tajikistan_2003.dta") {
	replace t_sewer_i = 1 if (t_type_lab == "two or more wc inside" | t_type_lab == "wc inside the house")
	}

if regexm("`filename'", "tajikistan_2007.dta") {
	replace t_type_i = 0.934 if t_type_lab == "pit latrine"
	}
	
**ALB**
if regexm("`filename'", "ALB_MICS3_2005_HH_Y2009M08D03.DTA") {
	replace t_type_i = 0.908 if t_type_lab=="traditional"
	}
	
if regexm("`filename'", "albania_2002.dta") {
	replace t_sewer_i = 1 if (t_type_lab=="WC inside the house" | t_type_lab=="Two or more WC inside") 
	}

if regexm("`filename'", "albania_2003.dta") {
	replace t_sewer_i = 1 if (t_type_lab=="WC inside the house" | t_type_lab=="Two or more WC inside") 
	}
	
if regexm("`filename'", "albania_2004.dta") {
	replace t_sewer_i = 1 if (t_type_lab=="wc inside the house" | t_type_lab=="two or more wc inside") 
	}
	
if regexm("`filename'", "albania_2005.dta") {
	replace t_sewer_i = 1 if (t_type_lab=="WC inside the house" | t_type_lab=="Two or more WC inside") 
	}
	
**BIH**
if regexm("`filename'", "bosnia herzegovina_2001.dta") {
	replace t_type_i = 0.843 if t_type_lab == "No, letrine only"
	}
	
**ROU**
if regexm("`filename'", "ROU_CENSUS_1992_WATER_SANITATION.DTA") {
	replace t_type_i = 0.92 if t_type_lab == "Not connected to sewage disposal system" /*regional average of other improved/unimproved*/
	}
	
if regexm("`filename'", "ROU_CENSUS_2002_WATER_SANITATION.DTA") {
	replace t_type_i = 0.92 if t_type_lab == "No flush toilet"
	}
	
**COL**
if regexm("`filename'", "COL_DHS3_1995_HH_Y2008M09D23.DTA") {
	replace t_type_i = 1 if t_type_lab == "toilet to pit"
	}

if regexm("`filename'", "COL_DHS4_2000_HH_Y2008M09D23.DTA")	{
	replace t_type_i = 1 if t_type_lab == "toilet to pit"
	}

**GTM**
if regexm("`filename'", "GTM_DHS1_1987_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.940 if t_type_lab == "letrina" /*other improved/unimproved*/
	}
	
if regexm("`filename'", "GTM_DHS3_1995_HH_Y2008M09D23.DTA")	{
	replace t_type_i = 0.940 if t_type_lab == "latrine"
	}
if regexm("`filename'", "GTM_ITR_DHS4_1998_1999_HH_Y2010M04D02.DTA") {
	replace t_type_i = 0.960 if t_type_lab == "traditional pit toilet" /*open/closed pit*/
	}
	
if regexm("`filename'", "guatemala_2000.dta") {
	replace t_sewer_i = 1 if t_type_lab == "excusado lavable"
	replace t_sewer_i = 0 if t_type_lab == "letrina o pozo ciego"
	}

if regexm("`filename'", "GTM_RHS_2008_2009_WN_Y2011M02D01.DTA") {
	replace t_sewer_i = 0 if t_type_lab == "letrina, pozo ciego, escusado"
	}
	
**URY**
if regexm("`filename'", "engih_uruguay_2005.dta") {
	replace t_type_i = 1 if t_type_lab == "no flush"
	}
	
**CRI**
if regexm("`filename'", "CRI_RHS_1993_WM_Y2011M01D26.DTA") {
	replace t_type_i = 0.466 if t_type_lab == "letrina o hueco"
	}
	
**HND** - use gtm ratio of closed/open pits
if regexm("`filename'", "HND_DHS6_2011_2012_HH_Y2013M06D26.DTA") {
	replace t_type_i = 0.960 if t_type_lab =="pit latrine"
	replace t_sewer_i = 0 if t_type_lab=="latrine with connection to open water"
	}

if regexm("`filename'", "HND_DHS5_2005_2006_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.960 if t_type_lab =="pit latrine"
	replace t_sewer_i = 0 if t_type_lab == "latrine with connection to open water"
	}

if regexm("`filename'", "HND_RHS_1991_1992_WN_Y2011M05D19.DTA") {
	replace t_type_i = 0.960 if t_type_lab =="letrina/fosa simple"
	replace t_sewer_i = 0 if t_type_lab == "letrina hidraulica/tasa campesina"
	}

if regexm("`filename'", "HND_RHS_1996_WN.DTA") {
	replace t_type_i = 1 if t_type_lab == "TASA CAMPESINA"
	replace t_type_i = 0.960 if t_type_lab == "FOSA SIMPLE"
	}

if regexm("`filename'", "HND_RHS_2001_WN.DTA") {
	replace t_type_i = 0.960 if t_type_lab =="Letrina de fosa simple"
	replace t_sewer_i = 1 if t_type_lab == "Inodoro(lavable)"
	replace t_sewer_i = 0 if t_type_lab=="Letrina hidraulica/tasa campesina"
	}

if regexm("`filename'", "encovi_honduras_2004.dta") {
	replace t_type_i = 0.960 if t_type_lab == "7. Letrina con pozo negro"
	replace t_sewer_i = 0 if (t_type_lab== "4. Letrina con descarga a río, laguna.." | t_type_lab == "7. Letrina con pozo negro" | ///
		t_type_lab == "6. Letrina con pozo séptico" | t_type_lab == "5. Letrina con cierre hidráulico")
	}

**MEX**
if regexm("`filename'", "MEX_DHS1_1987_HH_Y2008M09D23.DTA") {
	replace t_sewer_i = 1 if t_type_lab == "drenaje"
	replace t_sewer_i = 0 if t_type_lab == "fosa septica"
	}
	
if regexm("`filename'", "MEX_CENSUS_1990_WATER_SANITATION.DTA") {
	replace t_type_i = 0.918 if t_type_lab == "Non-flush, other and unspecified"
	replace t_sewer_i = 0.861 if t_type_lab == "Non-flush, other and unspecified"
	}

if regexm("`filename'", "MEX_CENSUS_2000_WATER_SANITATION.DTA") {
	replace t_type_i = 0 if (t_type_lab ==  "NIU (not in universe)") 
	}
	
if regexm("`filename'", "MEX_CENSUS_2010_WATER_SAN_Y2014M03D26.DTA") {
	replace t_type_i = 0.918 if t_type_lab == "Non-flush, other and unspecified"
	replace t_sewer_i = 0.861 if t_type_lab == "Non-flush, other and unspecified"
	}

if regexm("`filename'", "MEX_DHS1_1987_WN_Y2008M09D23.DTA") {
	replace t_type_i = 0.918 if t_type_lab == "si, fuera de la viv"
	}

**NIC** - use ratio of regional neighbor GTM
if regexm("`filename'", "NIC_DHS3_1997_1998_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.937 if t_type_lab == "pit with no ventilation"
	}
	
if regexm("`filename'", "NIC_DHS4_2001_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.937 if t_type_lab == "traditional pit toilet"
	}
	
if regexm("`filename'", "nicaragua_2001.dta") {
	replace t_type_i = 0.937 if t_type_lab == "Excusado o letrina sin tratar"
	replace t_type_i = 0.937 if t_type_lab == "Excvusado o letrina con tratamiento"
	}
	
if regexm("`filename'", "nicaragua_2005.dta") {
	replace t_type_i = 0.937 if t_type_lab == "excusado o letrina sin tratar"
	replace t_type_i = 0.937 if t_type_lab == "excusado o letrina con tratamiento"
	}
	
if regexm("`filename'", "NIC_RHS_1992_1993_WN.DTA") {
	replace t_type_i = 0.937 if t_type_lab == "Letrina"
	}
	
if regexm("`filename'", "NIC_RHS_2006_2007_WN.DTA") {
	replace t_type_i = 0.937 if t_type_lab == "excusado o letrina"
	}
	
**PAN** - use regional (GTM) ratio of closed/open pit
if regexm("`filename'", "panama_2003.dta")	{
	replace t_type_i = 0.937 if t_type_lab == "De hueco o letrina"
	}
	
if regexm("`filename'", "panama_2008.dta")	{
	replace t_type_i = 0.937 if t_type_lab == "de hueco o letrina"
	}
	
**SLV**
if regexm("`filename'", "SLV_RHS_1988_WN_Y2011M02D01.DTA") {
	replace t_type_i = 0.9744 if t_type_lab == "letrina" /*open/closed pit*/
	}
	
if regexm("`filename'", "SLV_RHS_1993_WN_Y2011M01D25.DTA") {
	replace t_type_i = 0.9744 if t_type_lab == "letrina"
	}
	
if regexm("`filename'", "SLV_RHS_1998_WN_Y2011M01D25.DTA") {
	replace t_type_i = 0.9744 if t_type_lab == "letrina"
	}

if regexm("`filename'", "SLV_RHS_2002_2003_WN_Y2011M01D25.DTA") {
	replace t_type_i = 0.9744 if t_type_lab == "letrina (fosa)"
	}

**ECU**
if regexm("`filename'", "ECU_RHS_1989_WN.DTA") {
	replace t_sewer_i = 1 if t_type_lab == "inodoro"
	replace t_sewer_i = 0 if t_type_lab == "pozo ciego"
	replace t_type_i = 0.818 if t_type_lab == "letrina"
	}

if regexm("`filename'", "ECU_RHS_1994_WN_Y2011M01D26.DTA") {
	replace t_type_i = 0.818 if t_type_lab == "letrina" /*improved/unimproved latrine*/
	}
	
if regexm("`filename'", "ecuador_1994.dta") {
	replace t_type_i = 0.818 if t_type_lab == "latrine/pit"
	replace t_sewer_i = 0 if t_type_lab == "hole (pozo ciego)"
	}

if regexm("`filename'", "ecuador_1998.dta") {
	replace t_sewer_i = 0 if t_type_lab == "excusado y pozo ciego"
	}

if regexm("`filename'", "ECU_RHS_2004_WN_Y2011M02D16.DTA") {
	replace t_type_i = 0.832 if t_type_lab == "letrina" /*improved/unimproved pit*/
	}

**PER**
if regexm("`filename'", "PER_DHS1_1986_WN_Y2011M02D09.DTA") {
	replace t_sewer_i = 1 if (t_type_lab=="excusado" | t_type_lab=="inodoro")
	}

if regexm("`filename'", "PER_DHS5_2003_2008_HH_Y2012M06D13.DTA") {
	replace t_sewer_i = 1 if (t_type_lab == "inside dwelling" | t_type_lab=="septic well") 
	replace t_sewer_i = 0 if t_type_lab == "latrine (ciego o negro)"
	}
	
if regexm("`filename'", "PER_DHS6_2009_HH_Y2013M08D28.DTA") {
	replace t_sewer_i = 1 if (t_type_lab == "Inside dwelling" | t_type_lab=="Septic well") 
	replace t_sewer_i = 0 if t_type_lab == "Latrine (ciego o negro)"
	}
	
if regexm("`filename'", "PER_DHS6_2010_HH_Y2013M09D03.DTA") {
	replace t_sewer_i = 1 if (t_type_lab == "inside dwelling" | t_type_lab=="septic well") 
	replace t_sewer_i = 0 if t_type_lab == "latrine (ciego o negro)"
	}
	
if regexm("`filename'", "PER_DHS6_2011_HH_Y2013M09D13.DTA") {
	replace t_sewer_i = 1 if (t_type_lab == "Inside dwelling" | t_type_lab=="Septic well") 
	replace t_sewer_i = 0 if t_type_lab == "Latrine (ciego o negro)"
	}
	
if regexm("`filename'", "PER_DHS6_2012_HH_Y2013M09D13.DTA") {
	replace t_sewer_i = 1 if (t_type_lab == "inside dwelling" | t_type_lab=="septic well") 
	replace t_sewer_i = 0 if t_type_lab == "latrine (ciego o negro)"
	}

if regexm("`filename'", "PER_DHS3_1996_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.999 if t_type_lab == "private latrine"
	}

if regexm("`filename'", "PER_DHS4_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.999 if t_type_lab == "own pit toilet/latrine"
	replace t_type_i = 0.999 if t_type_lab == "share pit toilet/letrine"
	}

if regexm("`filename'",	"PER_DHS6_2009_HH_Y2013M08D28.DTA") {
	replace t_type_i = 0.999 if t_type_lab == "Latrine (ciego o negro)"
	}
	
**BOL** -- use ECU ratio
if regexm("`filename'", "BOL_DHS1_1989_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.818 if t_type_lab == "letrina"
	}

if regexm("`filename'", "BOL_DHS3_1993_1994_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.832 if t_type_lab == "trad. pit toilet" 
	}

if regexm("`filename'", "BOL_DHS3_1998_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.832 if t_type_lab == "private pit toilet latrine"
	replace t_type_i = 0.832 if t_type_lab == "shared pit toilet latrine"
}

if regexm("`filename'", "BOL_DHS4_2003_2004_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.832 if t_type_lab == "pit toilet"
	}

**MDA**
if regexm("`filename'", "MDA_MICS2_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.575 if t_type_lab == "traditional pit latrine"
	}
	
**JAM**
if regexm("`filename'", "JAM_MICS2_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.927 if t_type_lab == "pit"
	}
	
if regexm("`filename'", "JAM_RHS_1997_WN_Y2011M03D24.dta") {
	replace t_type_i = 0.927 if t_type_lab == "Pit"
	replace t_sewer_i = 1 if t_type_lab == "WC not linked to sewer"
	}

if regexm("`filename'", "JAM_RHS_2002_2003_WN_Y2011M03D24.DTA") {
	replace t_type_i = 0.927 if t_type_lab == "Pit"
	replace t_sewer_i = 1 if t_type_lab == "WC not linked to sewer"
	}

if regexm("`filename'", "jamaica_1997.dta") {
	replace t_type_i = 0.927 if t_type_lab == "pit"
	replace t_sewer_i = 1 if t_type_lab == "w.c. not linked"
	}

if regexm("`filename'","jamaica_2007.dta") {
	replace t_type_i = 0.927 if t_type_lab == "pit"
	}

if regexm("`filename'","jamaica_2001.dta") {
	replace t_type_i = 0.927 if t_type_lab == "pit"
	replace t_sewer_i = 1 if t_type_lab == "w.c. not linked"
	}

if regexm("`filename'", "JAM_CENSUS_1982_WATER_SANITATION.DTA") {
	replace t_type_i = 0.927 if t_type_lab == "Pit"
	replace t_sewer_i = 1 if t_type_lab == "W.C. not linked to sewer"
	}
	
if regexm("`filename'", "JAM_CENSUS_1991_WATER_SANITATION.DTA") {
	replace t_type_i = 0.927 if t_type_lab == "Pit"
	replace t_sewer_i = 1 if t_type_lab == "WC not linked to sewer"
	}
	
if regexm("`filename'", "JAM_CENSUS_2001_WATER_SANITATION.DTA") {
	replace t_type_i = 0.927 if t_type_lab == "Pit"
	replace t_sewer_i = 1 if t_type_lab == "WC not linked to sewer"
	}
	
*********************************
*****AFRICA******
*********************************
**DZA** 
if regexm("`filename'", "papfam_algeria_2002.dta") {
	replace t_sewer_i = 0 if t_type_lab == "flush toilet - sewer"
	}
	
**AGO**
if regexm("`filename'", "AGO_MICS2_2001_HH_Y2008M09D23.DTA") {
	replace t_type_i = 1 if t_type_lab == "latrina seca/latrina com descarga manual"
	}

**CAF**
if regexm("`filename'", "CAF_DHS3_1994_1995_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.322 if t_type_lab == "traditional pit toil"
	}

if regexm("`filename'", "CAF_MICS2_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 1 if t_type_lab == "latrines traditionnelle ameliorees"
	replace t_type_i = 0.322 if t_type_lab == "latrines traditionnelles"
	}
	
	
**COG**
if regexm("`filename'", "COG_DHS5_2005_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.238 if t_type_lab == "traditional pit toilet"
	}

if regexm("`filename'", "COG.dta") {
	replace t_type_i = 0.238 if (t_type_lab == "Covered dry latrine (with privacy)" | t_type_lab == "Uncovered dry latrine (without privacy)")
	}
	
	
**COD**
if regexm("`filename'", "COD_MICS4_2010_HH_FR_Y2012M01D10.DTA") {
	replace t_type_i = 0.391 if t_type_lab == "Latrines à fosse sans dalle / trou ouvert"
	}

**BDI**
if regexm("`filename'", "BDI_DHS1_1987_WN_Y2008M09D23.DTA") {
	replace t_type_i = 0.272 if t_type_lab == "ex.pr. sans ch d eau"
	}
	
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
	
if regexm("`filename'", "KEN.dta") {
	replace t_type_i = 0.358 if t_type_lab == "Covered dry latrine (with privacy)"
	replace t_type_i = 0.358 if t_type_lab == "Uncovered dry latrine (without privacy)"
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
	
**MOZ**
if regexm("`filename'", "MOZ_DHS3_1997_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.273 if t_type_lab == "traditional pit toilet" /*open/closed pit*/
	}

if regexm("`filename'", "MOZ_DHS4_2003_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.401 if t_type_lab == "latrine"  /*other improved/unimproved latrine*/
	replace t_type_i = 0.401 if t_type_lab == "no flush toilet" /*other improved/unimproved latrine*/
	}
 
if regexm("`filename'", "MOZ_MICS3_2008_2009_HH_Y2011M06D30.DTA") {
	replace t_type_i = 1 if t_type_lab == "Latrina tradicional melhorada"
	replace t_type_i = 0 if t_type_lab == "Latrina não melhorada (laje)"
	}
	
**MWI** - use DHS ratios (bigger sample size)
if regexm("`filename'", "MWI_DHS2_1992_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.081 if t_type_lab == "trad. pit toilet"
	}
	
if regexm("`filename'", "MWI_DHS4_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.081 if t_type_lab == "traditional pit toilet"
	}
	
if regexm("`filename'", "MWI_DHS4_2004_2005_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.081 if t_type_lab == "traditional pit toilet"
	}
	
if regexm("`filename'", "MWI_CENSUS_1987_WATER_SANITATION.DTA") {
	replace t_type_i = 0.106 if t_type_lab == "Pit latrine, exclusive" /*improved/unimproved pit*/
	replace t_type_i = 0.106 if t_type_lab == "Pit latrine, shared"
	}

if regexm("`filename'", "MWI_CENSUS_1998_WATER_SANITATION.DTA") {
	replace t_type_i = 0.081 if t_type_lab == "Traditional pit" /*open/closed pit*/
	}

if regexm("`filename'", "MWI_CENSUS_2008_WATER_SANITATION.DTA") {
	replace t_type_i = 0.081 if t_type_lab == "Traditional pit toilet"
	}
	
if regexm("`filename'", "MWI.dta") {
	replace t_type_i = 0.081 if t_type_lab == "Covered dry latrine (with privacy)"
	replace t_type_i = 0.081 if t_type_lab == "Uncovered dry latrine (without privacy)"
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
	replace t_type_i = 0.760 if t_type_lab == "trou ouvert"
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
	replace t_type_i = 0.196 if t_type_lab == "Pit Latrine"
	}

if regexm("`filename'",	"hbs_tanzania_2007.dta") {
	replace t_type_i = 0.196 if t_type_lab == "Pit latrine (traditional)"
	}

if regexm("`filename'", "cwiq_tanzania_2006.dta") {
	replace t_type_i = 0.196 if t_type_lab == "Covered pit latrine"
	replace t_type_i = 0.196 if t_type_lab == "Uncovered pit latrine"
	}
	
**UGA** - use ratio of covered/uncovered pit from census 2000
if regexm("`filename'", "UGA_DHS4_2000_2001_HH_Y2008M10D22.DTA") {
	replace t_type_i = 0.746 if t_type_lab == "traditional pit toilet"
	}
	
if regexm("`filename'", "UGA_DHS3_1995_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.746 if t_type_lab == "trad.pit toilet"
	}
	
if regexm("`filename'", "UGA_DHS1_1988_1989_WN_Y2008M09D23.DTA") {
	replace t_type_i = 0.746 if t_type_lab == "Latrine, Pit"
	}
	
if regexm("`filename'", "UGA_CENSUS_1991_WATER_SANITATION.DTA") {
	replace t_type_i = 0.746 if t_type_lab == "Pit latrine, not shared"
	replace t_type_i = 0.746 if t_type_lab == "Pit latrine, shared"
	}

**SLE**
if regexm("`filename'", "SLE_CENSUS_2004_WATER_SANITATION.DTA") {
	replace t_type_i = 0.473 if t_type_lab == "Pit" /*improved/unimproved pit*/
	}

if regexm("`filename'",	"SLE_MICS2_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.466 if t_type_lab == "traditional pit latrine" /*open/closed pit*/
	}
	
**SEN**
if regexm("`filename'", "SEN_DHS1_1986_WN_Y2008M09D23.DTA") {
	replace t_type_i = 0.376 if t_type_lab == "pit"
	replace t_type_i = 0.461 if t_type_lab == "latrine"
	}
	
if regexm("`filename'", "SEN_DHS2_1992_1993_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.376 if t_type_lab == "trad. pit toilet"
	}
	
if regexm("`filename'", "SEN_DHS3_1997_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.376 if t_type_lab == "trad. pit toilet"
	}
	
if regexm("`filename'",	"SEN_DHS4_1999_HH_Y2008M11D03.DTA") {
	replace t_type_i = 0.376 if t_type_lab == "fosse" /*open/closed pit*/
	replace t_type_i = 0.461 if t_type_lab == "latrine" /*improved/unimproved latrine*/
	}
	
if regexm("`filename'", "SEN_DHS4_2005_HH_Y2008M09D23.DTA") {
	replace t_sewer_i = 0 if t_type_lab == "flush toilet"
	}
	
if regexm("`filename'", "SEN_DHS6_2010_2011_HH_Y2012M05D08.DTA") {
	replace t_sewer_i = 0 if t_type_lab == "latrine with manual flush"
	}
	
if regexm("`filename'", "SEN.dta") {
	replace t_sewer_i = 0 if t_type_lab == "Pour flush latrine"
	}
	
if regexm("`filename'",	"SEN_CENSUS_1988_WATER_SANITATION.DTA") {
	replace t_type_i = 0.461 if t_type_lab == "Cesspool"
	replace t_sewer_i = 0 if t_type_lab == "Cesspool"
	}
	
if regexm("`filename'",	"SEN_CENSUS_2002_WATER_SANITATION.DTA") {
	replace t_type_i = 0.461 if t_type_lab == "Cesspool, latrine"
	replace t_sewer_i = 0 if t_type_lab == "Cesspool, latrine"
	}

if regexm("`filename'",	"SEN_MICS2_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.376 if t_type_lab == "latrine seches traditionnelles"
	}
	

**SWZ**
if regexm("`filename'",	"SWZ_MICS2_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.881 if t_type_lab == "traditional pit latrine"
	}

if regexm("`filename'",	"SWZ_DHS5_2006_2007_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.881 if t_type_lab == "ordinary pit latrine"
	}
	
**ZAF**
if regexm("`filename'", "ZAF_CENSUS_1996_WATER_SANITATION.DTA") {
	replace t_type_i = 0.860 if t_type_lab == "Pit latrine"
	}
	
if regexm("`filename'", "ZAF_CENSUS_2001_WATER_SANITATION.DTA") {
	replace t_type_i = 0.860 if t_type_lab == "Pit latrine without ventilation"
	}

if regexm("`filename'", "ZAF_COMMUNITY_SURVEY_2007_WATER_SANITATION.DTA") {	
	replace t_type_i = 0.860 if t_type_lab == "Pit latrine without ventilation"
	}

if regexm("`filename'", "ZAF_DHS3_1998_HH_Y2011M01D24.DTA") {
	replace t_type_i = 0.860 if t_type_lab == "pit latrine"
	}
	
if regexm("`filename'", "south africa_1993.dta") {
	replace t_type_i = 0.860 if t_type_lab == "other pit latrine"
	}
	
**ZMB**
if regexm("`filename'", "ZMB_DHS2_1992_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.259 if t_type_lab == "trad. pit toilet"
}

if regexm("`filename'", "ZMB_DHS3_1996_1997_HH_Y2008M09D23.DTA") { 
	replace t_type_i = 0.259 if t_type_lab == "trad. pit toilet"
}

if regexm("`filename'", "ZMB_DHS4_2001_2002_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.259 if t_type_lab == "traditional pit latrine"
}

if regexm("`filename'", "ZMB_MICS2_1999_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.259 if t_type_lab=="traditional pit latrine"
}

if regexm("`filename'", "lcms_zambia_2004.dta") {
	replace t_type_i = 0.259 if t_type_lab == "own pit latrine"
	replace t_type_i = 0.259 if t_type_lab == "communal pit latrine"
	replace t_type_i = 0.259 if t_type_lab == "neighbour's/another household's pit lat"
	}
	
if regexm("`filename'", "ZMB.dta") {
	replace t_type_i = 0.259 if t_type_lab == "Covered dry latrine (with privacy)"
	replace t_type_i = 0.259 if t_type_lab == "Uncovered dry latrine (without privacy)"
	}
	
**BWA**
if regexm("`filename'", "BWA_DHS1_1988_WN_Y2008M09D23.DTA") {
	replace t_type_i = 0.343 if t_type_lab == "own pit latrine"
	}
	
**MLI**
if regexm("`filename'", "MLI_CENSUS_1998_WATER_SANITATION.DTA") {
	replace t_type_i = 0.258 if t_type_lab == "Private cesspool"
	replace t_type_i = 0.258 if t_type_lab == "Common cesspool"
	replace t_sewer_i = 0 if (t_type_lab == "Common cesspool" | t_type_lab == "Private cesspool") 
	}
	
if regexm("`filename'", "MLI_CENSUS_1987_WATER_SANITATION.DTA") {
	replace t_type_i = 0.262 if t_type_lab == "Pit latrine"
	}
	
if regexm("`filename'", "MLI_DHS1_1987_WN_Y2008M09D23.DTA") {
	replace t_type_i = 0.262 if t_type_lab == "Latrine"
	}

if regexm("`filename'", "MLI_DHS3_1995_1996_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.262 if (t_type_lab == "latrine" | t_type_lab == "trad. pit toilet") 
	}
	
if regexm("`filename'", "MLI_DHS4_2001_HH_Y2008M10D22.DTA") {
	replace t_type_i = 0.262 if t_type_lab == "traditional pit toilet"
	}
	
if regexm("`filename'", "MLI_DHS5_2006_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.262 if t_type_lab == "traditional pit toilet"
	}

**GNB**
if regexm("`filename'", "GNB_MICS2_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.84 if t_type_lab == "latrina tradicional ou cerco" /*closed/open pit*/
	}
	
if regexm("`filename'", "GNB_MICS3_2006_HH_Y2009M04D06.DTA") {
	replace t_sewer_i = 0 if (t_type_lab ==  "chasse branchee a autre chose" | t_type_lab == "chasse branchee a latrines")
	}
	
**GMB**
if regexm("`filename'", "GMB_MICS3_2005_2006_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.876 if t_type_lab == "traditional pit latrine" /*open/closed pit*/
	}
	
if regexm("`filename'", "GMB_MICS2_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.731 if t_type_lab== "traditional pit latrine"
	}
	
**GIN**
if regexm("`filename'", "GIN_DHS4_1999_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.433 if t_type_lab == "pit toilet latrine"
	replace t_type_i = 0.433 if t_type_lab == "basic pit"
	}
	
**GHA**
if regexm("`filename'", "GHA_CENSUS_2000_WATER_SANITATION.DTA") {
	replace t_type_i = 0.657 if t_type_lab == "Pit latrine"
	}

if regexm("`filename'", "lsms_ghana_2005.dta") {
	replace t_type_i = 0.657 if t_type_lab == "pit latrine"
	}
	
**CMR**
if regexm("`filename'", "CMR_DHS2_1991_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.278 if t_type_lab == "pit latrine"
	}
	
if regexm("`filename'", "CMR_MICS2_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.278 if t_type_lab == "latrines traditionelles"
	}
	
**BFA**
if regexm("`filename'", "quibb_burkina faso_2007.dta") {
	replace t_type_i = 0.617 if t_type_lab == "Latrines ordinaires"
	}

if regexm("`filename'", "BFA_MICS3_2006_HH_Y2009M06D11.DTA") {
	replace t_type_i = 0.617 if t_type_lab == "latrines a fosses/trou ouvert"
	}
	
if regexm("`filename'", "BFA_DHS2_1992_1993_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.617 if t_type_lab == "trad. pit toilet"
	}
	
if regexm("`filename'", "BFA_DHS3_1998_1999_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.617 if t_type_lab == "simple latrine"
	}

**CIV**
if regexm("`filename'", "CIV_DHS3_1994_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.577 if t_type_lab == "trad. pit toilet"
	}

if regexm("`filename'", "CIV_DHS3_1998_1999_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.577 if regexm(t_type_lab, "pit toilet")
	}

if regexm("`filename'", "CIV_MICS2_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.577 if t_type_lab == "traditional pit latrine"
	}

if regexm("`filename'", "CIV_MICS3_2006_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.577 if t_type_lab =="latrines traditionnelles"
	}

if regexm("`filename'", "CIV.dta") {
	replace t_sewer_i = 0 if t_type_lab == "Pour flush latrine"
	}
	
**NGA**
if regexm("`filename'", "NGA_DHS2_1990_WN_Y2008M09D23.DTA") {
	replace t_type_i = 0.723 if t_type_lab == "pit"
	}
	
if regexm("`filename'", "NGA_DHS4_2003_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.723 if t_type_lab == "traditional pit toilet"
	}

	
**MRT**
if regexm("`filename'", "MRT_DHS_2000_2001_HH_Y2008M09D23.DTA") {
	replace t_type_i = 1 if regexm(t_type_lab, "rudimentary latrine") 
	}
	
if regexm("`filename'", "MRT.dta") {
	replace t_sewer_i = 0 if t_type_lab == "Pour flush latrine"
	}
	
**BRA**
if regexm("`filename'", "BRA_DHS1_1986_HH_Y2013M05D13.DTA") {
	replace t_type_i = 0.757 if t_type_lab == "fossa rudimentar"
	}
	
if regexm("`filename'", "BRA_DHS3_1996_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.757 if t_type_lab == "traditional latrine" /*closed/open pit*/
	replace t_type_i = 1 if t_type_lab == "toilet to river /lake"
	replace t_type_i = 0.757 if t_type_lab == "latrine no-connected"
}

if regexm("`filename'", "BRA_DHS2_1991_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.757 if t_type_lab == "trad. pit toilet"
}

if regexm("`filename'", "BRA_CENSUS_1980_WATER_SANITATION.DTA") {
	replace t_sewer_i = 0 if t_type_lab == "Cesspool, cess pit, septic pit"
	}

if regexm("`filename'", "BRA_CENSUS_1991_WATER_SANITATION.DTA") {
	replace t_sewer_i = 0 if t_type_lab == "Rudimentary Cesspit"
	}
	
if regexm("`filename'", "BRA_CENSUS_2000_WATER_SANITATION.DTA") {
	replace t_sewer_i = 0 if t_type_lab == "Cesspool, cess pit, septic pit"
	}

**PRY**
if regexm("`filename'", "PRY_RHS_1998_WN.DTA") {
	replace t_type_i = 0.490 if t_type_lab == "LETRINA MUNIC." /*other improved/unimproved latrines*/
	replace t_type_i = 0.490 if t_type_lab == "LETRINA COMUN"
	replace t_sewer_i = 1 if t_type_lab == "BANO MODERNO"
	}
	
if regexm("`filename'", "PRY_RHS_1995_1996_WN.DTA") {
	replace t_type_i = 0.490 if t_type_lab == "letrina tipo municipal" /*other improved/unimproved latrines*/
	replace t_type_i = 0.490 if t_type_lab == "letrina comun"
	}
	
	
**SDN**
if regexm("`filename'", "SDN_CENSUS_2008_WATER_SANITATION_SPLIT_SDN_AND_SSD_Y2013M09D23.DTA") {
	replace t_type_i = 0.449 if t_type_lab == "Pit latrine private"
	replace t_type_i = 0.449 if t_type_lab == "Pit latrine shared"
	}
	
**TGO**
if regexm("`filename'", "TGO_DHS1_1988_WN_Y2008M09D23.DTA") {
	replace t_sewer_i = 0 if t_type_lab == "Puits perdu"
	replace t_type_i = 0.495 if t_type_lab == "Fosse etanche"
	}
	
***********************************
*******ASIA************************
**********************************
**YEM**
if regexm("`filename'", "YEM_DHS2_1991_1992_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.20 if t_type_lab == "pit"
	replace t_type_i = 0.415 if t_type_lab == "shared latrine"
	}
	
if regexm("`filename'", "papfam_yemen_2003.dta") {
	replace t_sewer_i = 0 if t_type_lab == "flush toilet - sewer"
	}

if regexm("`filename'", "YEM_MICS3_2006_HH_Y2009M04D06.DTA") {
	replace t_sewer_i = 0 if (t_type_lab == "flush to pit (latrine)" | t_type_lab == "flush to somewhere else" | ///
		t_type_lab == "flush to unknown place/not sure/dk where") 
	}
	
**SYR**
if regexm("`filename'", "papfam_syria_2001.dta") {
	replace t_sewer_i = 0 if t_type_lab == "flush toilet - sewer"
	}

**BGD**
if regexm("`filename'", "BGD_DHS4_2004_HH_Y2008M09D23.DTA")	{
	replace t_type_i = 0.483 if t_type_lab == "pit latrine"
	}

if regexm("`filename'", "BGD_SP_DHS4_2001_HH_Y2008M11D03.DTA") {
	replace t_type_i = 0.483 if t_type_lab == "pit latrine"
	}

if regexm("`filename'", "BGD.dta") {
	replace t_type_i = 0.483 if t_type_lab == "Covered dry latrine (with privacy)"
	replace t_type_i = 0.483 if t_type_lab == "Uncovered dry latrine (without privacy)"
	}
	
**BTN**
if regexm("`filename'", "census_bhutan_2005.dta") {
	replace t_type_i = 0.386 if t_type_lab == "Pit latrine"
	}
	
**NPL**
if regexm("`filename'", "NPL_DHS3_1996_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.344 if t_type_lab == "pit /latrine" /*covered/uncovered pit*/
	}

if regexm("`filename'", "NPL_DHS4_2001_HH_Y2008M10D22.DTA") {
	replace t_type_i = 0.344 if t_type_lab == "traditional pit toilet" /*covered/uncovered pit*/
	}

if regexm("`filename'", "NPL_CENSUS_2001_WATER_SANITATION.DTA") {
	replace t_type_i = 0.405 if t_type_lab == "Ordinary" /*other improved/unimproved*/
	}

**PAK**
if regexm("`filename'", "pakistan_1991.dta") {
	replace t_type_i = 0.62 if t_type_lab == "household non-flush" /*other improved/unimproved non-flush*/
	}

**KHM**
if regexm("`filename'", "KHM_CENSUS_2008_WATER_SANITATION.DTA") {
	replace t_type_i = 0 if t_type_lab == "Not available"
	}

**LKA**
if regexm("`filename'", "LKA_DHS1_1987_WN_Y2008M09D23.DTA") {
	replace t_type_i = 0.639 if t_type_lab == "pit"
	}

if regexm("`filename'", "LKA.dta") {
	replace t_sewer_i = 0 if t_type_lab == "Pour flush latrine"
	}

**MMR**
if regexm("`filename'", "MMR.dta") {
	replace t_sewer_i = 0 if t_type_lab == "Pour flush latrine"
	}
	
**MDV**
if regexm("`filename'", "MDV_DHS5_2009_HH_Y2010M12D16.DTA") {
	replace t_sewer_i = 0 if (t_type_lab == "flush - don't know where"  | t_type_lab == "flush - to pit latrine" | ///
		t_type_lab == "flush - to somewhere else") 
	}
	
**PHL**
if regexm("`filename'", "PHL_CENSUS_1990_WATER_SANITATION.DTA") {
	replace t_sewer_i = 1 if t_type_lab == "Other depository- own use" 
	replace t_sewer_i = 1 if t_type_lab == "Other depository- share"
	replace t_type_i = 1 if t_type_lab == "Other depository- own use"
	replace t_type_i = 1 if  t_type_lab == "Other depository- own use"
	}

if regexm("`filename'", "PHL_CENSUS_2000_WATER_SANITATION.DTA") {
	replace t_sewer_i = 1 if t_type_lab == "Water-sealed, other depository used exclusively by household"
	replace t_sewer_i = 1 if t_type_lab == "Water-sealed, other depository, shared"
	}
	
if regexm("`filename'", "PHL_DHS3_1993_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.495 if (t_type_lab == "trad. own pit toilet" | t_type_lab == "trad. shared pit toi")
	}

**TLS**
if regexm("`filename'", "timor leste_2001.dta") {
	replace t_type_i = 0.849 if t_type_lab == "traditional latrine"
	}
	
if regexm("`filename'", "TLS_DHS6_2009_2010_HH_Y2011M01D07.DTA") {
	replace t_sewer_i = 0 if (t_type_lab == "flush - don't know where" | t_type_lab == "flush - to pit latrine" | ///
		t_type_lab == "flush - to somewhere else") 
	}

**VNM**
if regexm("`filename'", "VNM_CENSUS_1999_WATER_SANITATION.DTA") {
	replace t_type_i = 0.533 if t_type_lab == "Simple toilet" /*other improved/unimproved*/
	}
	
if regexm("`filename'", "VNM_MICS2_2000_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.326 if t_type_lab == "traditional pit latrine"
	} 
	
if regexm("`filename'", "VNM_DHS3_1997_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.326 if t_type_lab == "trad. pit toilet"
	}
	
if regexm("`filename'", "VNM_DHS4_2002_HH_Y2008M09D23.DTA") {
	replace t_type_i = 0.326 if t_type_lab == "trad. pit toilet"
	}
	
**THA**
if regexm("`filename'", "THA_DHS1_1987_WN_Y2008M09D23.DTA") {
	replace t_type_i = 0.714 if t_type_lab=="pit"
	}
	
if regexm("`filename'", "THA_CENSUS_1980_WATER_SANITATION.DTA") {
	replace t_type_i = 1 if (t_type_lab == "Moulded bucket latrine, exclusive" | t_type_lab == "Moulded latrine, shared")
	replace t_type_i = 0.714 if t_type_lab == "Pits"
	}

if regexm("`filename'", "THA_CENSUS_1990_WATER_SANITATION.DTA") {
	replace t_type_i = 1 if t_type_lab == "Moulded bucket latrine, exclusive"
	replace t_type_i = 1 if t_type_lab == "Moulded bucket latrine, shared"
	replace t_type_i = 1 if t_type_lab == "Flush and moulded latrine, exclusive"
	replace t_type_i = 1 if t_type_lab == "Flush and moulded latrine, shared"
	replace t_type_i = 0.714 if t_type_lab == "Pits and others"
	}

if regexm("`filename'", "THA_CENSUS_2000_WATER_SANITATION.DTA") {
	replace t_type_i = 1 if t_type_lab == "Molded bucket latrine"
	replace t_type_i = 1 if t_type_lab == "Flush and molded bucket latrine"
	}
	
if regexm("`filename'", "THA_MICS3_2005_2006_HH_Y2008M09D23.DTA") {
	replace t_sewer_i = 0 if (t_type_lab == "flush to pit (latrine)" | t_type_lab == "flush to somewhere else" | ///
		t_type_lab == "flush to unknown place/not sure/dk wh..") 
	}
	
end
