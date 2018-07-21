**Purpose: Prep prevalence data extracted from published literature for handwashing. 
**Date: 05/15/2014
**Author: Astha KC
**Notes: Data extracted from published iterature was sent as is by Annette Pruss et al in 05/2014

**Housekeeping**
clear all
set more off

**Set relevant locals**
local source_data 		"J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/00_documentation/materials from annette"
local country_codes 	"J:/DATA/IHME_COUNTRY_CODES/IHME_COUNTRY_CODES_Y2013M07D26.DTA"
local data_folder 		"J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/prevalence/literature"
local nid_folder		"J:/DATA/Incoming Data/WORK/05_risk/1_ready/final_risk_citation_lists"

**Prep source information	
	import excel using "`nid_folder'/studies_HWWS_prevalence_05152014_gdntmoon_20150805.xlsx", firstrow clear
	
	**standardize variable names
	rename (Country Yearofstudyconduct Reference_Original) (location_name year reference) 
	
	**standardize country names
	replace location_name = "United States" if location_name=="USA"
	replace location_name = "United Kingdom" if location_name=="UK"
	replace location_name = "Netherlands" if location_name=="The Netherlands"
	replace location_name = "South Korea" if location_name=="Korea"
	
	tempfile sources
	save `sources', replace 

**Prep data**

	**import data
	insheet using "`source_data'/studies_HWWS_prevalence_05152014.csv", clear
	
	**clean up/standardize variables and data
	rename country location_name 
	replace location_name = "United States" if location_name=="USA"
	replace location_name = "United Kingdom" if location_name=="UK"
	replace location_name = "Netherlands" if location_name=="The Netherlands"
	replace location_name = "South Korea" if location_name=="Korea"
	
	gen year = yearofstudyconduct
	**replace year = "" if yearofstudyconduct=="NA"
	**destring(year), replace 
	
	**Add relevant variables**
	preserve
	use "`country_codes'", clear
	drop if iso3==""
	tempfile codes
	save `codes', replace
	restore

	merge m:1 location_name using `codes', keepusing(gbd_analytical_region_name gbd_analytical_superregion_name iso3 indic_cod) keep(1 3) nogen
	drop if indic_cod != 1
	drop region 
	
		/*replace missing years with year of publication - can track down actual years after going through paper*/
		replace year = 2009 if iso3=="BGD" & year==.
		replace year = 2006 if reference=="CDC. Hygiene Promotion Survey Report, Sichuan, Chengdu.  2006: CDC;"
		replace year = 2005 if reference=="Xian PDU. Hygiene Promotion Survey Report (Shaanxi).  2nd ed.  CDC; 2005."
		replace year = 2012 if iso3=="GHA" & year==.
		replace year = 2003 if iso3=="IND" & year==.
		replace year = 2007 if iso3=="KEN" & reference=="Steadman International. Formative and baseline survey on Handwashing with Soap. Final Report."
		replace year = 2011 if iso3=="KEN" & regexm(reference, "Pickering, A.")
		replace year = 2005 if iso3=="KGZ" & year==. 
		replace year = 2004 if iso3=="PER" & year==.
		replace year = 2007 if iso3=="KOR" & year==.
		replace year = 2006 if iso3=="TZA" & year==.
		replace year = 2007 if iso3=="UGA" & year==.
		replace year = 2003 if regexm(reference, "Curtis V, Biran A,")
		replace year = 2009 if regexm(reference, "Judah G, Aunger R,") 
		replace year = 2004 if regexm(reference, "the shocking truth.") 
		replace year = 2003 if regexm(reference, "Johnson, H. D., Sholcosky, D., Gabello, K., Ragni, R., & Ogonosky, N.") 
		replace year = 1997 if regexm(reference, "Guinan, M. E., McGuckinGuinan, M., & Sevareid, A.") 
		replace year = 2013 if regexm(reference, "Borchgrevink, C. P., Cha, J., & Kim, S.")  

	order reference, last
	
	**calculate prevalence and se of proportion of individuals who wash their hands with soap
	gen hwws_prev = hwwsevents/totalopportunities
	gen hwws_se = sqrt((hwws_prev*(1-hwws_prev))/totalopportunities)
	
	**check if calculated prev is different from Annette's extracted prev
	gen hwws_round = round(hwws_prev, 0.01)
	br if hwws_round != combinedstudyprevalence /*they are equal*/
	drop hwws_round combined* yearofstudy*
	
	**Merge nids assigned to all of the literature sources used in the handwashing database
	merge 1:1 location_name year reference using `sources', keepusing(nid) keep(1 3) nogen
	replace nid = 147619 if nid == . & location_name == "United States" & year == 2010 
	
**Save data**
	save "`data_folder'/hygiene_prev.dta", replace
	

