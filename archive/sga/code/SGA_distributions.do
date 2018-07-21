** Stephanie Teeple
** SGA descriptives


clear all 
set more off
set maxvar 30000
version 13.0

if c(os) == "Windows" {
	local j "J:"
	// Load the PDF appending application
	quietly do "`j'/Usable/Tools/ADO/pdfmaker_Acrobat11.do"
}
if c(os) == "Unix" {
	local j "/home/j"
	// Load the PDF appending application
	quietly do "`j'/Usable/Tools/ADO/pdfmaker_Acrobat11.do"
} 

***********************************************
** prep data
***********************************************

* use "`j'/temp/steeple/neonatal/microdata_collapse/MEX/MEX_neonatal_master.dta", clear

* tempfile MEX
* save `MEX', emptyok

* foreach year in 2008 2009 2010 2011 2012 2014 {
* 	use `MEX' if year_start == `year'
* 	tempfile MEX_`year'
* 	save `MEX_`year''
* }

* use "`j'/temp/steeple/neonatal/microdata_collapse/URY/URY_neonatal_master.dta", clear

* tempfile URY
* save `URY', emptyok

* foreach year in 1996 1997 1999 2000 2001 2002 2007 2008 2009 2010 2011 2012 2013 2014 {
* 	use `URY' if year_start == `year'
* 	tempfile URY_`year'
* 	save `URY_`year''
* }

* use "`j'/temp/steeple/neonatal/microdata_collapse/USA/extracted/USA_territories_master.dta", clear


* tempfile USA_terr
* save `USA_terr', emptyok

* foreach year in 1995 1996 1997 1998 1999 2000 2001 2002 2003 2005 2006 2007 2008 2009 2010 {
* 	use `USA_terr' if year_start == `year'
* 	tempfile USA_terr_`year'
* 	save `USA_terr_`year''
* }

* use "`j'/temp/steeple/neonatal/microdata_collapse/USA/extracted/USA_states_master.dta", clear


* tempfile USA_states
* save `USA_states', emptyok

* foreach year in 1990 1991 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 {
* 	use `USA_states' if year_start == `year'
* 	tempfile USA_states_`year'
* 	save `USA_states_`year''
* }


* * *************************************************
* * ** MEX
* * *************************************************


* ** <28 weeks
* di "pdf starting"
* pdfstart using "/snfs2/HOME/steeple/Documents/GBD/_common/MEX_28_weeks.pdf" 

* di "start 28 weeks loop"
* foreach year in 2008 2009 2010 2011 2012 2014 {
* 	use `MEX_`year'' if gestage <28, clear
* 	summ birthweight, detail
* 	di "retrieving mean"
* 	local mean = round(`r(mean)')
* 	di "retrieving standard deviation" 
	
* 	local standard_dev = round(`r(sd)', .01)
* 	hist birthweight, title("MEX `year' <28 weeks: SD=`standard_dev', mean=`mean'") percent 
* 	pdfappend
* }

* * di "pdffinishing"
* pdffinish, view 

* ** 28-32 weeks
* di "pdfstarting"
* pdfstart using "/snfs2/HOME/steeple/Documents/GBD/_common/MEX_28_32_weeks.pdf" 

* di "start 28-32 weeks loop"
* foreach year in 2008 2009 2010 2011 2012 2014 {
* 	use `MEX_`year'' if gestage >=28 & gestage<32, clear
* 	summ birthweight, detail
* 	di "retrieving mean"
* 	local mean = round(`r(mean)')
* 	di "retrieving standard deviation" 
	
* 	local standard_dev = round(`r(sd)', .01)
* 	hist birthweight, title("MEX `year' 28-32 weeks: SD=`standard_dev', mean=`mean'") percent
* 	pdfappend
* }

* di "pdffinishing"
* pdffinish, view 


* ** 32-37 weeks 
* di "pdfstarting"
* pdfstart using "/snfs2/HOME/steeple/Documents/GBD/_common/MEX_32_37_weeks.pdf" 

* di "start 32-37 weeks loop"
* foreach year in 2008 2009 2010 2011 2012 2014 {
* 	use `MEX_`year'' if gestage >=32 & gestage<37, clear
* 	summ birthweight, detail
* 	di "retrieving mean"
* 	local mean = round(`r(mean)')
* 	di "retrieving standard deviation" 
	
* 	local standard_dev = round(`r(sd)', .01)
* 	hist birthweight, title("MEX `year' 32-37 weeks: SD=`standard_dev', mean=`mean'") percent
* 	pdfappend
* }

* di "pdffinishing"
* pdffinish, view


* ** <37 weeks 
* di "pdfstarting"
* pdfstart using "/snfs2/HOME/steeple/Documents/GBD/_common/MEX_37_weeks.pdf" 

* di "start 32-37 weeks loop"
* foreach year in 2008 2009 2010 2011 2012 2014 {
* 	use `MEX_`year'' if gestage<37, clear
* 	summ birthweight, detail
* 	di "retrieving mean"
* 	local mean = round(`r(mean)')
* 	di "retrieving standard deviation" 
	
* 	local standard_dev = round(`r(sd)', .01)
* 	hist birthweight, title("MEX `year' <37 weeks: SD=`standard_dev', mean=`mean'") percent
* 	pdfappend
* }

* di "pdffinishing"
* pdffinish, view


* ****************************************************
* ** URY
* ****************************************************

* ** <28 weeks
* di "pdf starting"
* pdfstart using "/snfs2/HOME/steeple/Documents/GBD/_common/URY_28_weeks.pdf" 

* di "start 28 weeks loop"
* foreach year in 1996 1997 1999 2000 2001 2002 2007 2008 2009 2010 2011 2012 2013 2014 {
* 	use `URY_`year'' if gestage <28, clear
* 	summ birthweight, detail
* 	di "retrieving mean"
* 	local mean = round(`r(mean)')
* 	di "retrieving standard deviation" 
* 	cap drop *00*
* 	local standard_dev = round(`r(sd)', .01)
* 	hist birthweight, title("URY `year' <28 weeks: SD=`standard_dev', mean=`mean'") percent
* 	pdfappend
* }

* di "pdffinishing"
* pdffinish, view 

* ** 28-32 weeks
* di "pdfstarting"
* pdfstart using "/snfs2/HOME/steeple/Documents/GBD/_common/URY_28_32_weeks.pdf" 

* di "start 28-32 weeks loop"
* foreach year in 1996 1997 1999 2000 2001 2002 2007 2008 2009 2010 2011 2012 2013 2014 {
* 	use `URY_`year'' if gestage >=28 & gestage<32, clear
* 	summ birthweight, detail
* 	di "retrieving mean"
* 	local mean = round(`r(mean)')
* 	di "retrieving standard deviation" 
* 	cap drop *00*
* 	local standard_dev = round(`r(sd)', .01)
* 	hist birthweight, title("URY `year' 28-32 weeks: SD=`standard_dev', mean=`mean'") percent
* 	pdfappend
* }

* di "pdffinishing"
* pdffinish, view 


* ** 32-37 weeks 
* di "pdfstarting"
* pdfstart using "/snfs2/HOME/steeple/Documents/GBD/_common/URY_32_37_weeks.pdf" 

* di "start 32-37 weeks loop"
* foreach year in 1996 1997 1999 2000 2001 2002 2007 2008 2009 2010 2011 2012 2013 2014 {
* 	use `URY_`year'' if gestage >=32 & gestage<37, clear
* 	summ birthweight, detail
* 	di "retrieving mean"
* 	local mean = round(`r(mean)')
* 	di "retrieving standard deviation" 
* 	cap drop *00*
* 	local standard_dev = round(`r(sd)', .01)
* 	hist birthweight, title("URY `year' 32-37 weeks: SD=`standard_dev', mean=`mean'") percent
* 	pdfappend
* }

* di "pdffinishing"
* pdffinish, view


* ** <37 weeks 
* di "pdfstarting"
* pdfstart using "/snfs2/HOME/steeple/Documents/GBD/_common/URY_37_weeks.pdf" 

* di "start 32-37 weeks loop"
* foreach year in 1996 1997 1999 2000 2001 2002 2007 2008 2009 2010 2011 2012 2013 2014 {
* 	use `URY_`year'' if gestage<37, clear
* 	summ birthweight, detail
* 	di "retrieving mean"
* 	local mean = round(`r(mean)')
* 	di "retrieving standard deviation" 
* 	cap drop *00*
* 	local standard_dev = round(`r(sd)', .01)
* 	hist birthweight, title("URY `year' <37 weeks: SD=`standard_dev', mean=`mean'") percent
* 	pdfappend
* }

* di "pdffinishing"
* pdffinish, view



* ***********************************************************
* ** USA - territories
* ***********************************************************

* ** <28 weeks
* di "pdf starting"
* pdfstart using "/snfs2/HOME/steeple/Documents/GBD/_common/USA_terr_28_weeks.pdf" 

* di "start 28 weeks loop"
* foreach year in 1995 1996 1997 1998 1999 2000 2001 2002 2003 2005 2006 2007 2008 2009 2010 {
* 	di "year is `year'"
* 	use `USA_terr_`year'' if gestage <28, clear
* 	summ birthweight, detail
* 	di "retrieving mean"
* 	local mean = round(`r(mean)')
* 	di "retrieving standard deviation" 
	
* 	local standard_dev = round(`r(sd)', .01)
* 	hist birthweight, title("USA_terr `year' <28 weeks: SD=`standard_dev', mean=`mean'") percent
* 	pdfappend
* }

* di "pdffinishing"
* pdffinish, view 

* ** 28-32 weeks
* di "pdfstarting"
* pdfstart using "/snfs2/HOME/steeple/Documents/GBD/_common/USA_terr_28_32_weeks.pdf" 

* di "start 28-32 weeks loop"
* foreach year in 1995 1996 1997 1998 1999 2000 2001 2002 2003 2005 2006 2007 2008 2009 2010 {
* 	di "year is `year'"
* 	use `USA_terr_`year'' if gestage >=28 & gestage<32, clear
* 	summ birthweight, detail
* 	di "retrieving mean"
* 	local mean = round(`r(mean)')
* 	di "retrieving standard deviation" 
	
* 	local standard_dev = round(`r(sd)', .01)
* 	hist birthweight, title("USA_terr `year' 28-32 weeks: SD=`standard_dev', mean=`mean'") percent
* 	pdfappend
* }

* di "pdffinishing"
* pdffinish, view 


* ** 32-37 weeks 
* di "pdfstarting"
* pdfstart using "/snfs2/HOME/steeple/Documents/GBD/_common/USA_terr_32_37_weeks.pdf" 

* di "start 32-37 weeks loop"
* foreach year in 1995 1996 1997 1998 1999 2000 2001 2002 2003 2005 2006 2007 2008 2009 2010 {
* 	di "year is `year'"
* 	use `USA_terr_`year'' if gestage >=32 & gestage<37, clear
* 	summ birthweight, detail
* 	di "retrieving mean"
* 	local mean = round(`r(mean)')
* 	di "retrieving standard deviation" 
	
* 	local standard_dev = round(`r(sd)', .01)
* 	hist birthweight, title("USA_terr `year' 32-37 weeks: SD=`standard_dev', mean=`mean'") percent
* 	pdfappend
* }

* di "pdffinishing"
* pdffinish, view


* ** <37 weeks 
* di "pdfstarting"
* pdfstart using "/snfs2/HOME/steeple/Documents/GBD/_common/USA_terr_37_weeks.pdf" 

* di "start 32-37 weeks loop"
* foreach year in 1995 1996 1997 1998 1999 2000 2001 2002 2003 2005 2006 2007 2008 2009 2010 {
* 	di "year is `year'"
* 	use `USA_terr_`year'' if gestage<37, clear
* 	summ birthweight, detail
* 	di "retrieving mean"
* 	local mean = round(`r(mean)')
* 	di "retrieving standard deviation" 
	
* 	local standard_dev = round(`r(sd)', .01)
* 	hist birthweight, title("USA_terr `year' <37 weeks: SD=`standard_dev', mean=`mean'") percent
* 	pdfappend
* }

* di "pdffinishing"
* pdffinish, view


* ******************************************************************
* ** USA - states 
* *****************************************************************


* use "`j'/temp/steeple/neonatal/microdata_collapse/USA/extracted/USA_states_master.dta", clear


* tempfile USA_states
* save `USA_states', emptyok

* foreach year in 1990 1991 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 {
* 	use `USA_states' if year_start == `year'
* 	tempfile USA_states_`year'
* 	save `USA_states_`year''
* }

* ** <28 weeks
* di "pdf starting"
* pdfstart using "/snfs2/HOME/steeple/Documents/GBD/_common/USA_states_28_weeks.pdf" 

* di "start 28 weeks loop"
* foreach year in 1990 1991 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 {
* 	di "year is `year'"
* 	use `USA_states_`year'' if gestage <28, clear
* 	summ birthweight, detail
* 	di "retrieving mean"
* 	local mean = round(`r(mean)')
* 	di "retrieving standard deviation" 
	
* 	local standard_dev = round(`r(sd)', .01)
* 	hist birthweight, title("USA_states `year' <28 weeks: SD=`standard_dev', mean=`mean'") percent
* 	pdfappend
* }

* di "pdffinishing"
* pdffinish, view 

* ** 28-32 weeks
* di "pdfstarting"
* pdfstart using "/snfs2/HOME/steeple/Documents/GBD/_common/USA_states_28_32_weeks.pdf" 

* di "start 28-32 weeks loop"
* foreach year in 1990 1991 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010  {
* 	di "year is `year'"
* 	use `USA_states_`year'' if gestage >=28 & gestage<32, clear
* 	summ birthweight, detail
* 	di "retrieving mean"
* 	local mean = round(`r(mean)')
* 	di "retrieving standard deviation" 
	
* 	local standard_dev = round(`r(sd)', .01)
* 	hist birthweight, title("USA_states `year' 28-32 weeks: SD=`standard_dev', mean=`mean'") percent
* 	pdfappend
* }

* di "pdffinishing"
* pdffinish, view 


* ** 32-37 weeks 
* di "pdfstarting"
* pdfstart using "/snfs2/HOME/steeple/Documents/GBD/_common/USA_states_32_37_weeks.pdf" 

* di "start 32-37 weeks loop"
* foreach year in 1990 1991 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 {
* 	di "year is `year'"
* 	use `USA_states_`year'' if gestage >=32 & gestage<37, clear
* 	summ birthweight, detail
* 	di "retrieving mean"
* 	local mean = round(`r(mean)')
* 	di "retrieving standard deviation" 
	
* 	local standard_dev = round(`r(sd)', .01)
* 	hist birthweight, title("USA_states `year' 32-37 weeks: SD=`standard_dev', mean=`mean'") percent
* 	pdfappend
* }

* di "pdffinishing"
* pdffinish, view


* ** <37 weeks 
* di "pdfstarting"
* pdfstart using "/snfs2/HOME/steeple/Documents/GBD/_common/USA_states_37_weeks.pdf" 

* di "start 32-37 weeks loop"
* foreach year in 1990 1991 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 {
* 	di "year is `year'"
* 	use `USA_states_`year'' if gestage<37, clear
* 	summ birthweight, detail
* 	di "retrieving mean"
* 	local mean = round(`r(mean)')
* 	di "retrieving standard deviation" 
	
* 	local standard_dev = round(`r(sd)', .01)
* 	hist birthweight, title("USA_states `year' <37 weeks: SD=`standard_dev', mean=`mean'") percent
* 	pdfappend
* }

* di "pdffinishing"
* pdffinish, view



* ******************************************************************
* ******************************************************************
* ** ttests
* ******************************************************************
* ******************************************************************

* /*

* tempfile ttest
* save `ttest', emptyok


* forvalues year = 1995/2014 {
* 	foreach iso3 in MEX URY USA_states USA_terr {
* 		capture use ``iso3'_`year'', clear 
* 	}

* }
* */

* ******************************************************************
* ** Fitting lnormal distribution
* ******************************************************************


* foreach iso3 in MEX URY USA_states USA_terr {

* 	forvalues year = 1995/2014 {
* 		di "Year is `year' and iso3 is `iso3'"
* 		di "<28 weeks"
* 		capture noisily use ``iso3'_`year'' if gestage<28, clear
* 		if _rc == 0 {
* 			di "we have the data!"
* 			cap drop *00*
* 			lognfit birthweight, stats
* 			qlogn birthweight, generate(preds_`year')
* 			twoway hist birthweight, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds_`year', color("cranberry") title(" Lnormal: `iso3' `year' <28 weeks")
* 			graph export "J:/temp/steeple/neonatal/lnormal/lnormal_28weeks_`iso3'_`year'.pdf", replace
* 		}
* 	}
* }


* foreach iso3 in MEX URY USA_states USA_terr {

* 	forvalues year = 1995/2014 {
* 		di "Year is `year' and iso3 is `iso3'"
* 		di "<28 weeks"
* 		capture noisily use ``iso3'_`year'' if gestage>=28 & gestage<32, clear
* 		if _rc == 0 {
* 			cap drop *00*
* 			lognfit birthweight, stats
* 			qlogn birthweight, generate(preds_`year')
* 			twoway hist birthweight, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds_`year', color("cranberry") title(" Lnormal: `iso3' `year' 28-32 weeks")
* 			graph export "J:/temp/steeple/neonatal/lnormal/lnormal_28_32weeks_`iso3'_`year'.pdf", replace
* 		}
* 	}
* }



* foreach iso3 in USA_states USA_terr {

* 	forvalues year = 1995/2014 {
* 		di "Year is `year' and iso3 is `iso3'"
* 		di "<28 weeks"
* 		capture noisily use ``iso3'_`year'' if gestage>=32 & gestage<37, clear
* 		if _rc == 0 {
* 			cap drop *00*
* 			lognfit birthweight, stats
* 			qlogn birthweight, generate(preds_`year')
* 			twoway hist birthweight, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds_`year', color("cranberry") title(" Lnormal: `iso3' `year' 32-37 weeks")
* 			graph export "J:/temp/steeple/neonatal/lnormal/lnormal_32_37weeks_`iso3'_`year'.pdf" , replace
* 		}
* 	}
* }





* foreach iso3 in MEX URY USA_states USA_terr {


* 	forvalues year = 1995/2014 {
* 		di "Year is `year' and iso3 is `iso3'"
* 		di "<28 weeks"
* 		capture noisily use ``iso3'_`year'' if gestage<37, clear
* 		if _rc == 0 {
* 			cap drop *00*
* 			lognfit birthweight, stats
* 			qlogn birthweight, generate(preds_`year')
* 			twoway hist birthweight, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds_`year', color("cranberry") title(" Lnormal: `iso3' `year' <37 weeks")
* 			graph export "J:/temp/steeple/neonatal/lnormal/lnormal_37weeks_`iso3'_`year'.pdf", replace
* 		}
* 	}
* }



* ******************************************************************
* ** Evaluating lnormal distribution
* ******************************************************************

* // create blank tempfile
* /*set obs 6
* gen id = _n
* gen order = .
* replace order = 1 if id <3
* replace order = 2 if id>2&id<5
* replace order = 3 if id>4
* gen birthweight = ""
* replace birthweight = "Less than 1500g" if id <3
* replace birthweight = "1500-2000g" if id>2 & id<5
* replace birthweight = "2000-2500g" if id>4
* egen data_type = repeat(), values("data" "preds")
* gen proportion = .
* tempfile template
* save `template'*/

* set obs 4
* gen id = _n
* gen order = .
* replace order = 1 if id <3
* replace order = 2 if id>2
* gen birthweight = ""
* replace birthweight = "Less than 1500g" if id <3
* replace birthweight = "Less than 2500g" if id>2 
* egen data_type = repeat(), values("data" "preds")
* gen proportion = .
* tempfile template
* save `template'


* // <28 weeks
* foreach iso3 in MEX URY USA_states USA_terr {

* 	forvalues year = 1995/2014 {
* 		di "Year is `year' and iso3 is `iso3'"
* 		di "<28 weeks"
* 		capture noisily use ``iso3'_`year'' if gestage<28, clear
* 		if _rc == 0 {
* 			di "we have the data!"
* 			cap drop *00*
* 			lognfit birthweight, stats
* 			summ birthweight, detail
* 			local obs = `r(N)'
* 			qlogn birthweight, generate(preds)

* 			count if birthweight <2500 
* 			local heaviest_data = `r(N)'/`obs'
* 			count if preds <2500
* 			local heaviest_preds = `r(N)'/`obs'
			
* 			/*count if birthweight >=2000 & birthweight <2500
* 			local light_data = `r(N)'/`obs'
* 			count if preds >=2000 & preds <2500
* 			local light_preds = `r(N)'/`obs'

* 			count if birthweight >=1500 & birthweight <2000
* 			local lighter_data = `r(N)'/`obs'
* 			count if preds >=1500 & preds <2000
* 			local lighter_preds = `r(N)'/`obs'*/

* 			count if birthweight <1500 
* 			local lightest_data = `r(N)'/`obs'
* 			count if preds <1500
* 			local lightest_preds = `r(N)'/`obs'

* 			use `template', clear
* 			/*replace proportion = `light_data' if birthweight == "2000-2500g" & data_type == "data"
* 			replace proportion = `light_preds' if birthweight == "2000-2500g" & data_type == "preds"
* 			replace proportion = `lighter_data' if birthweight == "1500-2000g" & data_type == "data"
* 			replace proportion = `lighter_preds' if birthweight == "1500-2000g" & data_type == "preds"
* 			replace proportion = `lightest_data' if birthweight == "Less than 1500g" & data_type == "data"
* 			replace proportion = `lightest_preds' if birthweight == "Less than 1500g" & data_type == "preds"*/

* 			replace proportion = `lightest_data' if birthweight == "Less than 1500g" & data_type == "data"
* 			replace proportion = `lightest_preds' if birthweight == "Less than 1500g" & data_type == "preds"
* 			replace proportion = `heaviest_data' if birthweight == "Less than 2500g" & data_type == "data"
* 			replace proportion = `heaviest_preds' if birthweight == "Less than 2500g" & data_type == "preds"

* 			graph bar proportion, over(data_type) over(birthweight, sort(order)) asyvars bar(1, color(navy)) bar(2, color(cranberry)) bar(3, color(navy)) bar(4, color(cranberry)) bar(5, color(navy)) bar(6, color(cranberry)) legend(lab(1 "Raw data") lab (2 "Lnormal preds")) title("<28 weeks, `iso3' `year'")
* 			graph export "`j'/temp/steeple/neonatal/lnormal_props/lnormal_standard_props/lnormal_28weeks_`iso3'_`year'.pdf", replace

* 		}
* 	}
* }

* // 28-32 weeks 
* foreach iso3 in MEX URY USA_states USA_terr {

* 	forvalues year = 1995/2014 {
* 		di "Year is `year' and iso3 is `iso3'"
* 		di "<28 weeks"
* 		capture noisily use ``iso3'_`year'' if gestage>=28 & gestage<32, clear
* 		if _rc == 0 {
* 			di "we have the data!"
* 			cap drop *00*
* 			lognfit birthweight, stats
* 			summ birthweight, detail
* 			local obs = `r(N)'
* 			qlogn birthweight, generate(preds)

* 			count if birthweight <2500 
* 			local heaviest_data = `r(N)'/`obs'
* 			count if preds <2500
* 			local heaviest_preds = `r(N)'/`obs'
			
* 			/*count if birthweight >=2000 & birthweight <2500
* 			local light_data = `r(N)'/`obs'
* 			count if preds >=2000 & preds <2500
* 			local light_preds = `r(N)'/`obs'

* 			count if birthweight >=1500 & birthweight <2000
* 			local lighter_data = `r(N)'/`obs'
* 			count if preds >=1500 & preds <2000
* 			local lighter_preds = `r(N)'/`obs'*/

* 			count if birthweight <1500 
* 			local lightest_data = `r(N)'/`obs'
* 			count if preds <1500
* 			local lightest_preds = `r(N)'/`obs'

* 			use `template', clear
* 			/*replace proportion = `light_data' if birthweight == "2000-2500g" & data_type == "data"
* 			replace proportion = `light_preds' if birthweight == "2000-2500g" & data_type == "preds"
* 			replace proportion = `lighter_data' if birthweight == "1500-2000g" & data_type == "data"
* 			replace proportion = `lighter_preds' if birthweight == "1500-2000g" & data_type == "preds"
* 			replace proportion = `lightest_data' if birthweight == "Less than 1500g" & data_type == "data"
* 			replace proportion = `lightest_preds' if birthweight == "Less than 1500g" & data_type == "preds"*/

* 			replace proportion = `lightest_data' if birthweight == "Less than 1500g" & data_type == "data"
* 			replace proportion = `lightest_preds' if birthweight == "Less than 1500g" & data_type == "preds"
* 			replace proportion = `heaviest_data' if birthweight == "Less than 2500g" & data_type == "data"
* 			replace proportion = `heaviest_preds' if birthweight == "Less than 2500g" & data_type == "preds"

* 			graph bar proportion, over(data_type) over(birthweight, sort(order)) asyvars bar(1, color(navy)) bar(2, color(cranberry)) bar(3, color(navy)) bar(4, color(cranberry)) bar(5, color(navy)) bar(6, color(cranberry)) legend(lab(1 "Raw data") lab (2 "Lnormal preds")) title("28-32 weeks, `iso3' `year'")
* 			graph export "`j'/temp/steeple/neonatal/lnormal_props/lnormal_standard_props/lnormal_28_32weeks_`iso3'_`year'.pdf", replace

* 		}
* 	}
* }

* // 32-37 weeks
* foreach iso3 in MEX URY USA_states USA_terr {

* 	forvalues year = 1995/2014 {
* 		di "Year is `year' and iso3 is `iso3'"
* 		di "<28 weeks"
* 		capture noisily use ``iso3'_`year'' if gestage>=32 & gestage<37, clear
* 		if _rc == 0 {
* 			di "we have the data!"
* 			cap drop *00*
* 			lognfit birthweight, stats
* 			summ birthweight, detail
* 			local obs = `r(N)'
* 			qlogn birthweight, generate(preds)

* 			count if birthweight <2500 
* 			local heaviest_data = `r(N)'/`obs'
* 			count if preds <2500
* 			local heaviest_preds = `r(N)'/`obs'
			
* 			/*count if birthweight >=2000 & birthweight <2500
* 			local light_data = `r(N)'/`obs'
* 			count if preds >=2000 & preds <2500
* 			local light_preds = `r(N)'/`obs'

* 			count if birthweight >=1500 & birthweight <2000
* 			local lighter_data = `r(N)'/`obs'
* 			count if preds >=1500 & preds <2000
* 			local lighter_preds = `r(N)'/`obs'*/

* 			count if birthweight <1500 
* 			local lightest_data = `r(N)'/`obs'
* 			count if preds <1500
* 			local lightest_preds = `r(N)'/`obs'

* 			use `template', clear
* 			/*replace proportion = `light_data' if birthweight == "2000-2500g" & data_type == "data"
* 			replace proportion = `light_preds' if birthweight == "2000-2500g" & data_type == "preds"
* 			replace proportion = `lighter_data' if birthweight == "1500-2000g" & data_type == "data"
* 			replace proportion = `lighter_preds' if birthweight == "1500-2000g" & data_type == "preds"
* 			replace proportion = `lightest_data' if birthweight == "Less than 1500g" & data_type == "data"
* 			replace proportion = `lightest_preds' if birthweight == "Less than 1500g" & data_type == "preds"*/

* 			replace proportion = `lightest_data' if birthweight == "Less than 1500g" & data_type == "data"
* 			replace proportion = `lightest_preds' if birthweight == "Less than 1500g" & data_type == "preds"
* 			replace proportion = `heaviest_data' if birthweight == "Less than 2500g" & data_type == "data"
* 			replace proportion = `heaviest_preds' if birthweight == "Less than 2500g" & data_type == "preds"

* 			graph bar proportion, over(data_type) over(birthweight, sort(order)) asyvars bar(1, color(navy)) bar(2, color(cranberry)) bar(3, color(navy)) bar(4, color(cranberry)) bar(5, color(navy)) bar(6, color(cranberry)) legend(lab(1 "Raw data") lab (2 "Lnormal preds")) title("32-37 weeks, `iso3' `year'")
* 			graph export "`j'/temp/steeple/neonatal/lnormal_props/lnormal_standard_props/lnormal_32_37weeks_`iso3'_`year'.pdf", replace

* 		}
* 	}
* }


* // < 37 weeks
* foreach iso3 in MEX URY USA_states USA_terr {

* 	forvalues year = 1995/2014 {
* 		di "Year is `year' and iso3 is `iso3'"
* 		di "<28 weeks"
* 		capture noisily use ``iso3'_`year'' if gestage<37, clear
* 		if _rc == 0 {
* 			di "we have the data!"
* 			cap drop *00*
* 			lognfit birthweight, stats
* 			summ birthweight, detail
* 			local obs = `r(N)'
* 			qlogn birthweight, generate(preds)

* 			count if birthweight <2500 
* 			local heaviest_data = `r(N)'/`obs'
* 			count if preds <2500
* 			local heaviest_preds = `r(N)'/`obs'
			
* 			/*count if birthweight >=2000 & birthweight <2500
* 			local light_data = `r(N)'/`obs'
* 			count if preds >=2000 & preds <2500
* 			local light_preds = `r(N)'/`obs'

* 			count if birthweight >=1500 & birthweight <2000
* 			local lighter_data = `r(N)'/`obs'
* 			count if preds >=1500 & preds <2000
* 			local lighter_preds = `r(N)'/`obs'*/

* 			count if birthweight <1500 
* 			local lightest_data = `r(N)'/`obs'
* 			count if preds <1500
* 			local lightest_preds = `r(N)'/`obs'

* 			use `template', clear
* 			/*replace proportion = `light_data' if birthweight == "2000-2500g" & data_type == "data"
* 			replace proportion = `light_preds' if birthweight == "2000-2500g" & data_type == "preds"
* 			replace proportion = `lighter_data' if birthweight == "1500-2000g" & data_type == "data"
* 			replace proportion = `lighter_preds' if birthweight == "1500-2000g" & data_type == "preds"
* 			replace proportion = `lightest_data' if birthweight == "Less than 1500g" & data_type == "data"
* 			replace proportion = `lightest_preds' if birthweight == "Less than 1500g" & data_type == "preds"*/

* 			replace proportion = `lightest_data' if birthweight == "Less than 1500g" & data_type == "data"
* 			replace proportion = `lightest_preds' if birthweight == "Less than 1500g" & data_type == "preds"
* 			replace proportion = `heaviest_data' if birthweight == "Less than 2500g" & data_type == "data"
* 			replace proportion = `heaviest_preds' if birthweight == "Less than 2500g" & data_type == "preds"

* 			graph bar proportion, over(data_type) over(birthweight, sort(order)) asyvars bar(1, color(navy)) bar(2, color(cranberry)) bar(3, color(navy)) bar(4, color(cranberry)) bar(5, color(navy)) bar(6, color(cranberry)) legend(lab(1 "Raw data") lab (2 "Lnormal preds")) title("<37 weeks, `iso3' `year'")
* 			graph export "`j'/temp/steeple/neonatal/lnormal_props/lnormal_standard_props/lnormal_37weeks_`iso3'_`year'.pdf", replace

* 		}
* 	}
* }


********************************************************************************
** fitting Weibull distribution
********************************************************************************

* pdfstart using "H:/Documents/GBD/SGA/Weibull_distributions.pdf"

* foreach iso3 in MEX URY USA_states USA_terr {

* 	forvalues year = 1995/2014 {
* 		di "Year is `year' and iso3 is `iso3'"
* 		di "<28 weeks"
* 		capture noisily use ``iso3'_`year'' if gestage<28, clear
* 		if _rc == 0 {
* 			di "we have the data!"
* 			cap drop *00*
* 			weibullfit birthweight, stats
* 			qweibull birthweight, generate(preds_`year')
* 			twoway hist birthweight, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds_`year', color("cranberry") title("Weibull: `iso3' `year' <28 weeks")
* 			pdfappend
* 		}
* 	}
* }


* foreach iso3 in MEX URY USA_states USA_terr {

* 	forvalues year = 1995/2014 {
* 		di "Year is `year' and iso3 is `iso3'"
* 		di "<28 weeks"
* 		capture noisily use ``iso3'_`year'' if gestage>=28 & gestage<32, clear
* 		if _rc == 0 {
* 			cap drop *00*
* 			weibullfit birthweight, stats
* 			qweibull birthweight, generate(preds_`year')
* 			twoway hist birthweight, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds_`year', color("cranberry") title("Weibull: `iso3' `year' 28-32 weeks")
* 			pdfappend
* 		}
* 	}
* }



* foreach iso3 in USA_states USA_terr {

* 	forvalues year = 1995/2014 {
* 		di "Year is `year' and iso3 is `iso3'"
* 		di "<28 weeks"
* 		capture noisily use ``iso3'_`year'' if gestage>=32 & gestage<37, clear
* 		if _rc == 0 {
* 			cap drop *00*
* 			weibullfit birthweight, stats
* 			qweibull birthweight, generate(preds_`year')
* 			twoway hist birthweight, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds_`year', color("cranberry") title("Weibull: `iso3' `year' 32-37 weeks")
* 			pdfappend
* 		}
* 	}
* }





* foreach iso3 in MEX URY USA_states USA_terr {


* 	forvalues year = 1995/2014 {
* 		di "Year is `year' and iso3 is `iso3'"
* 		di "<28 weeks"
* 		capture noisily use ``iso3'_`year'' if gestage<37, clear
* 		if _rc == 0 {
* 			cap drop *00*
* 			weibullfit birthweight, stats
* 			qweibull birthweight, generate(preds_`year')
* 			twoway hist birthweight, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds_`year', color("cranberry") title("Weibull: `iso3' `year' <37 weeks")
* 			pdfappend
* 		}
* 	}
* }

* pdffinish, view


******************************************************************
** Evaluating Weibull distribution 
******************************************************************

* use "J:/temp/steeple/neonatal/microdata_collapse/all_data.dta", clear
* tempfile all
* save `all'

* clear
* set obs 20
* gen id = _n
* egen order = fill (1 1 2 2 3 3 4 4 5 5 6 6 7 7 8 8 9 9 10 10)
* gen birthweight = ""
* replace birthweight = "0-250g" if order == 1
* replace birthweight = "250-500g" if order == 2
* replace birthweight = "500-750g" if order == 3
* replace birthweight = "750-1000g" if order == 4
* replace birthweight = "1000-1250g" if order == 5
* replace birthweight = "1250-1500g" if order == 6
* replace birthweight = "1500-1750g" if order == 7
* replace birthweight = "1750-2000g" if order == 8
* replace birthweight = "2000-2250g" if order == 9
* replace birthweight = "2250-2500g" if order == 10
* gen data_type = "data" if id == 1 | id == 3 | id == 5 | id == 7 | id == 9 | id ==11 | id == 13 | id == 15 | id == 17 | id == 19
* replace data_type = "preds" if data_type == "" 
* gen proportion = .
* tempfile template
* save `template'

* pdfstart using "H:/Documents/GBD/SGA/all_Weibull_distributions_fit.pdf"

* // <28 weeks
* foreach sex in 1 2 {
 
* 	di "Sex is `sex'"
* 	di "<28 weeks"
* 	use `all' if gestage<28 & sex == `sex', clear
* 	tab sex

* 	di "we have the data!"
* 	cap drop *00*
* 	weibullfit birthweight
* 	summ birthweight, detail
* 	local obs = `r(N)'
* 	qweibull birthweight, generate(preds)
* 	twoway hist birthweight, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds, color("cranberry") title("All data <28 weeks (sex=`sex'), Weibull")
* 	pdfappend

* 	forvalues x = 250(250)2500 {
* 		di "X = `x'"
* 		di "counting"
* 		count if birthweight>=(`x'-250) & birthweight <`x'
* 		local `x'_data = `r(N)'/`obs'
* 		di "counting"
* 		count if preds >=(`x'-250) & preds <`x'
* 		local `x'_preds = `r(N)'/`obs'
* 	}

* 	use `template', clear

* 	di "begin proportion loop"
* 	local order = 0
* 	forvalues x = 250(250)2500 {
* 		local order = `order'+1
* 		di "replacing data"
* 		replace proportion = ``x'_data' if order==`order' & data_type == "data"
* 		di "replacing preds"
* 		replace proportion = ``x'_preds' if order==`order' & data_type == "preds"
* 	}

* 	di "graphing"
* 	graph bar proportion, over(data_type) over(birthweight, sort(order) label(labsize(vsmall) alternate)) asyvars bar(1, color(navy)) bar(2, color(cranberry)) bar(3, color(navy)) bar(4, color(cranberry)) bar(5, color(navy)) bar(6, color(cranberry)) legend(lab(1 "Raw data") lab (2 "Weibull preds")) title("All data <28weeks (sex=`sex'), Weibull")
* 	pdfappend

* }

* // 28-32 weeks 
* foreach sex in 1 2 {
 
* 	di "Sex is `sex'"
* 	di "28-32 weeks"
* 	use `all' if gestage>=28 & gestage<32 & sex == `sex', clear
* 	tab sex

* 	di "we have the data!"
* 	cap drop *00*
* 	weibullfit birthweight
* 	summ birthweight, detail
* 	local obs = `r(N)'
* 	qweibull birthweight, generate(preds)
* 	twoway hist birthweight, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds, color("cranberry") title("All data 28-32 weeks (sex=`sex'), Weibull")
* 	pdfappend

* 	forvalues x = 250(250)2500 {
* 		di "X = `x'"
* 		di "counting"
* 		count if birthweight>=(`x'-250) & birthweight <`x'
* 		local `x'_data = `r(N)'/`obs'
* 		di "counting"
* 		count if preds >=(`x'-250) & preds <`x'
* 		local `x'_preds = `r(N)'/`obs'
* 	}

* 	use `template', clear

* 	di "begin proportion loop"
* 	local order = 0
* 	forvalues x = 250(250)2500 {
* 		local order = `order'+1
* 		di "replacing data"
* 		replace proportion = ``x'_data' if order==`order' & data_type == "data"
* 		di "replacing preds"
* 		replace proportion = ``x'_preds' if order==`order' & data_type == "preds"
* 	}

* 	di "graphing"
* 	graph bar proportion, over(data_type) over(birthweight, sort(order) label(labsize(vsmall) alternate)) asyvars bar(1, color(navy)) bar(2, color(cranberry)) bar(3, color(navy)) bar(4, color(cranberry)) bar(5, color(navy)) bar(6, color(cranberry)) legend(lab(1 "Raw data") lab (2 "Weibull preds")) title("All data 28-32 weeks (sex=`sex'), Weibull")
* 	pdfappend

* }


* // 32-37 weeks
* foreach sex in 1 2 {
 
* 	di "Sex is `sex'"
* 	di "32-37 weeks"
* 	use `all' if gestage>=32 & gestage<37 & sex == `sex', clear
* 	tab sex

* 	di "we have the data!"
* 	cap drop *00*
* 	weibullfit birthweight
* 	summ birthweight, detail
* 	local obs = `r(N)'
* 	qweibull birthweight, generate(preds)
* 	twoway hist birthweight, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds, color("cranberry") title("All data 32-37 weeks (sex=`sex'), Weibull")
* 	pdfappend

* 	forvalues x = 250(250)2500 {
* 		di "X = `x'"
* 		di "counting"
* 		count if birthweight>=(`x'-250) & birthweight <`x'
* 		local `x'_data = `r(N)'/`obs'
* 		di "counting"
* 		count if preds >=(`x'-250) & preds <`x'
* 		local `x'_preds = `r(N)'/`obs'
* 	}

* 	use `template', clear

* 	di "begin proportion loop"
* 	local order = 0
* 	forvalues x = 250(250)2500 {
* 		local order = `order'+1
* 		di "replacing data"
* 		replace proportion = ``x'_data' if order==`order' & data_type == "data"
* 		di "replacing preds"
* 		replace proportion = ``x'_preds' if order==`order' & data_type == "preds"
* 	}

* 	di "graphing"
* 	graph bar proportion, over(data_type) over(birthweight, sort(order) label(labsize(vsmall) alternate)) asyvars bar(1, color(navy)) bar(2, color(cranberry)) bar(3, color(navy)) bar(4, color(cranberry)) bar(5, color(navy)) bar(6, color(cranberry)) legend(lab(1 "Raw data") lab (2 "Weibull preds")) title("All data 32-37 weeks (sex=`sex'), Weibull")
* 	pdfappend

* }


* // < 37 weeks
* foreach sex in 1 2 {
 
* 	di "Sex is `sex'"
* 	di "<37 weeks"
* 	use `all' if gestage<37 & sex == `sex', clear
* 	tab sex

* 	di "we have the data!"
* 	cap drop *00*
* 	weibullfit birthweight
* 	summ birthweight, detail
* 	local obs = `r(N)'
* 	qweibull birthweight, generate(preds)
* 	twoway hist birthweight, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) percent || hist preds, color("cranberry") title("All data <37 weeks (sex=`sex'), Weibull") percent
* 	pdfappend

* 	forvalues x = 250(250)2500 {
* 		di "X = `x'"
* 		di "counting"
* 		count if birthweight>=(`x'-250) & birthweight <`x'
* 		local `x'_data = `r(N)'/`obs'
* 		di "counting"
* 		count if preds >=(`x'-250) & preds <`x'
* 		local `x'_preds = `r(N)'/`obs'
* 	}

* 	use `template', clear

* 	di "begin proportion loop"
* 	local order = 0
* 	forvalues x = 250(250)2500 {
* 		local order = `order'+1
* 		di "replacing data"
* 		replace proportion = ``x'_data' if order==`order' & data_type == "data"
* 		di "replacing preds"
* 		replace proportion = ``x'_preds' if order==`order' & data_type == "preds"
* 	}

* 	di "graphing"
* 	graph bar proportion, over(data_type) over(birthweight, sort(order) label(labsize(vsmall) alternate)) asyvars bar(1, color(navy)) bar(2, color(cranberry)) bar(3, color(navy)) bar(4, color(cranberry)) bar(5, color(navy)) bar(6, color(cranberry)) legend(lab(1 "Raw data") lab (2 "Weibull preds")) title("All data <37 weeks (sex=`sex'), Weibull")
* 	pdfappend

* }


* pdffinish, view


*****************************************************
** fitting and evaluating log normal for inverse-transformed data
*****************************************************

* use "`j'/temp/steeple/neonatal/microdata_collapse/all_data_inverse.dta", clear
* tempfile all
* save `all'

* clear
* set obs 20
* gen id = _n
* egen order = fill (1 1 2 2 3 3 4 4 5 5 6 6 7 7 8 8 9 9 10 10)
* gen birthweight = ""
* replace birthweight = "0-250g" if order == 1
* replace birthweight = "250-500g" if order == 2
* replace birthweight = "500-750g" if order == 3
* replace birthweight = "750-1000g" if order == 4
* replace birthweight = "1000-1250g" if order == 5
* replace birthweight = "1250-1500g" if order == 6
* replace birthweight = "1500-1750g" if order == 7
* replace birthweight = "1750-2000g" if order == 8
* replace birthweight = "2000-2250g" if order == 9
* replace birthweight = "2250-2500g" if order == 10
* gen data_type = "data" if id == 1 | id == 3 | id == 5 | id == 7 | id == 9 | id ==11 | id == 13 | id == 15 | id == 17 | id == 19
* replace data_type = "preds" if data_type == "" 
* gen proportion = .
* tempfile template
* save `template'

* pdfstart using "/snfs2/HOME/steeple/Documents/GBD/SGA/all_logn_inverse_distributions_fit.pdf"

* // <28 weeks
* foreach sex in 1 2 {
 
* 	di "Sex is `sex'"
* 	di "<28 weeks"
* 	use `all' if gestage<28 & sex == `sex', clear
* 	tab sex

* 	di "we have the data!"
* 	cap drop *00*
* 	rename birthweight birthweight_transformed
* 	lognfit birthweight_transformed, stats
* 	summ birthweight_transformed, detail
* 	local obs = `r(N)'
* 	qlogn birthweight_transformed, generate(preds_transformed)

* 	di "reversing transforms"
* 	gen preds = (preds_transformed)^-1
* 	gen birthweight = (birthweight_transformed)^-1

* 	twoway hist birthweight_transformed, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds_transformed, color("cranberry") title("All data <28 weeks (sex=`sex'), inverse-transformed lnormal")
* 	pdfappend

* 	twoway hist birthweight, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds, color("cranberry") title("All data <28 weeks (sex=`sex'), lnormal")
* 	pdfappend

* 	forvalues x = 250(250)2500 {
* 		di "X = `x'"
* 		di "counting"
* 		count if birthweight>=(`x'-250) & birthweight <`x'
* 		local `x'_data = `r(N)'/`obs'
* 		di "counting"
* 		count if preds >=(`x'-250) & preds <`x'
* 		local `x'_preds = `r(N)'/`obs'
* 	}

* 	use `template', clear

* 	di "begin proportion loop"
* 	local order = 0
* 	forvalues x = 250(250)2500 {
* 		local order = `order'+1
* 		di "replacing data"
* 		replace proportion = ``x'_data' if order==`order' & data_type == "data"
* 		di "replacing preds"
* 		replace proportion = ``x'_preds' if order==`order' & data_type == "preds"
* 	}

* 	di "graphing"
* 	graph bar proportion, over(data_type) over(birthweight, sort(order) label(labsize(vsmall) alternate)) asyvars bar(1, color(navy)) bar(2, color(cranberry)) bar(3, color(navy)) bar(4, color(cranberry)) bar(5, color(navy)) bar(6, color(cranberry)) legend(lab(1 "Raw data") lab (2 "lnormal preds")) title("All data <28weeks (sex=`sex'), inverse-transformed lnormal")
* 	pdfappend

* }


* // 28-32 weeks 
* foreach sex in 1 2 {
 
* 	di "Sex is `sex'"
* 	di "28-32 weeks"
* 	use `all' if gestage>=28 & gestage<32 & sex == `sex', clear
* 	tab sex

* 	di "we have the data!"
* 	cap drop *00*
* 	rename birthweight birthweight_transformed
* 	lognfit birthweight_transformed, stats
* 	summ birthweight_transformed, detail
* 	local obs = `r(N)'
* 	qlogn birthweight_transformed, generate(preds_transformed)

* 	di "reversing transforms"
* 	gen preds = (preds_transformed)^-1
* 	gen birthweight = (birthweight_transformed)^-1

* 	twoway hist birthweight_transformed, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds_transformed, color("cranberry") title("All data 28-32 weeks (sex=`sex'), inverse-transformed lnormal")
* 	pdfappend

* 	twoway hist birthweight, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds, color("cranberry") title("All data 28-32 weeks (sex=`sex'), lnormal")
* 	pdfappend

* 	forvalues x = 250(250)2500 {
* 		di "X = `x'"
* 		di "counting"
* 		count if birthweight>=(`x'-250) & birthweight <`x'
* 		local `x'_data = `r(N)'/`obs'
* 		di "counting"
* 		count if preds >=(`x'-250) & preds <`x'
* 		local `x'_preds = `r(N)'/`obs'
* 	}

* 	use `template', clear

* 	di "begin proportion loop"
* 	local order = 0
* 	forvalues x = 250(250)2500 {
* 		local order = `order'+1
* 		di "replacing data"
* 		replace proportion = ``x'_data' if order==`order' & data_type == "data"
* 		di "replacing preds"
* 		replace proportion = ``x'_preds' if order==`order' & data_type == "preds"
* 	}

* 	di "graphing"
* 	graph bar proportion, over(data_type) over(birthweight, sort(order) label(labsize(vsmall) alternate)) asyvars bar(1, color(navy)) bar(2, color(cranberry)) bar(3, color(navy)) bar(4, color(cranberry)) bar(5, color(navy)) bar(6, color(cranberry)) legend(lab(1 "Raw data") lab (2 "lnormal preds")) title("All data 28-32 weeks (sex=`sex'), inverse-transformed lnormal")
* 	pdfappend

* }


* // 32-37 weeks
* foreach sex in 1 2 {
 
* 	di "Sex is `sex'"
* 	di "32-37 weeks"
* 	use `all' if gestage>=32 & gestage<37 & sex == `sex', clear
* 	tab sex

* 	di "we have the data!"
* 	cap drop *00*
* 	rename birthweight birthweight_transformed
* 	lognfit birthweight_transformed, stats
* 	summ birthweight_transformed, detail
* 	local obs = `r(N)'
* 	qlogn birthweight_transformed, generate(preds_transformed)

* 	di "reversing transforms"
* 	gen preds = (preds_transformed)^-1
* 	gen birthweight = (birthweight_transformed)^-1

* 	twoway hist birthweight_transformed, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds_transformed, color("cranberry") title("All data 32-37 weeks (sex=`sex'), inverse-transformed lnormal")
* 	pdfappend

* 	twoway hist birthweight, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds, color("cranberry") title("All data 32-37 weeks (sex=`sex'), lnormal")
* 	pdfappend

* 	forvalues x = 250(250)2500 {
* 		di "X = `x'"
* 		di "counting"
* 		count if birthweight>=(`x'-250) & birthweight <`x'
* 		local `x'_data = `r(N)'/`obs'
* 		di "counting"
* 		count if preds >=(`x'-250) & preds <`x'
* 		local `x'_preds = `r(N)'/`obs'
* 	}

* 	use `template', clear

* 	di "begin proportion loop"
* 	local order = 0
* 	forvalues x = 250(250)2500 {
* 		local order = `order'+1
* 		di "replacing data"
* 		replace proportion = ``x'_data' if order==`order' & data_type == "data"
* 		di "replacing preds"
* 		replace proportion = ``x'_preds' if order==`order' & data_type == "preds"
* 	}

* 	di "graphing"
* 	graph bar proportion, over(data_type) over(birthweight, sort(order) label(labsize(vsmall) alternate)) asyvars bar(1, color(navy)) bar(2, color(cranberry)) bar(3, color(navy)) bar(4, color(cranberry)) bar(5, color(navy)) bar(6, color(cranberry)) legend(lab(1 "Raw data") lab (2 "lnormal preds")) title("All data 32-37 weeks (sex=`sex'), inverse-transformed lnormal")
* 	pdfappend

* }


* // < 37 weeks
* foreach sex in 1 2 {
 
* 	di "Sex is `sex'"
* 	di "<37 weeks"
* 	use `all' if gestage<37 & sex == `sex', clear
* 	tab sex

* 	di "we have the data!"
* 	cap drop *00*
* 	rename birthweight birthweight_transformed
* 	lognfit birthweight_transformed, stats
* 	summ birthweight_transformed, detail
* 	local obs = `r(N)'
* 	qlogn birthweight_transformed, generate(preds_transformed)

* 	di "reversing transforms"
* 	gen preds = (preds_transformed)^-1
* 	gen birthweight = (birthweight_transformed)^-1

* 	twoway hist birthweight_transformed, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds_transformed, color("cranberry") title("All data <37 weeks (sex=`sex'), inverse-transformed lnormal")
* 	pdfappend

* 	twoway hist birthweight, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds, color("cranberry") title("All data <37 weeks (sex=`sex'), lnormal")
* 	pdfappend

* 	forvalues x = 250(250)2500 {
* 		di "X = `x'"
* 		di "counting"
* 		count if birthweight>=(`x'-250) & birthweight <`x'
* 		local `x'_data = `r(N)'/`obs'
* 		di "counting"
* 		count if preds >=(`x'-250) & preds <`x'
* 		local `x'_preds = `r(N)'/`obs'
* 	}

* 	use `template', clear

* 	di "begin proportion loop"
* 	local order = 0
* 	forvalues x = 250(250)2500 {
* 		local order = `order'+1
* 		di "replacing data"
* 		replace proportion = ``x'_data' if order==`order' & data_type == "data"
* 		di "replacing preds"
* 		replace proportion = ``x'_preds' if order==`order' & data_type == "preds"
* 	}

* 	di "graphing"
* 	graph bar proportion, over(data_type) over(birthweight, sort(order) label(labsize(vsmall) alternate)) asyvars bar(1, color(navy)) bar(2, color(cranberry)) bar(3, color(navy)) bar(4, color(cranberry)) bar(5, color(navy)) bar(6, color(cranberry)) legend(lab(1 "Raw data") lab (2 "lnormal preds")) title("All data <37 weeks (sex=`sex'), inverse-transformedlnormal")
* 	pdfappend

* }


* pdffinish, view


*****************************************************
** fitting and evaluating Weibull fits for inverse-transformed data
****************************************************

use "`j'/temp/steeple/neonatal/microdata_collapse/all_data_inverse.dta", clear
tempfile all
save `all'

clear
set obs 20
gen id = _n
egen order = fill (1 1 2 2 3 3 4 4 5 5 6 6 7 7 8 8 9 9 10 10)
gen birthweight = ""
replace birthweight = "0-250g" if order == 1
replace birthweight = "250-500g" if order == 2
replace birthweight = "500-750g" if order == 3
replace birthweight = "750-1000g" if order == 4
replace birthweight = "1000-1250g" if order == 5
replace birthweight = "1250-1500g" if order == 6
replace birthweight = "1500-1750g" if order == 7
replace birthweight = "1750-2000g" if order == 8
replace birthweight = "2000-2250g" if order == 9
replace birthweight = "2250-2500g" if order == 10
gen data_type = "data" if id == 1 | id == 3 | id == 5 | id == 7 | id == 9 | id ==11 | id == 13 | id == 15 | id == 17 | id == 19
replace data_type = "preds" if data_type == "" 
gen proportion = .
tempfile template
save `template'

pdfstart using "/snfs2/HOME/steeple/Documents/GBD/SGA/all_weibull_inverse_distributions_fit.pdf"

// <28 weeks
foreach sex in 1 2 {
 
	di "Sex is `sex'"
	di "<28 weeks"
	use `all' if gestage<28 & sex == `sex', clear
	tab sex

	di "we have the data!"
	cap drop *00*
	rename birthweight birthweight_transformed
	weibullfit birthweight_transformed
	summ birthweight_transformed, detail
	local obs = `r(N)'
	qweibull birthweight_transformed, generate(preds_transformed)

	di "reversing transforms"
	gen preds = (preds_transformed)^-1
	gen birthweight = (birthweight_transformed)^-1

	twoway hist birthweight_transformed if birthweight_transformed >=0.0004 & birthweight_transformed <0.04, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds_transformed if preds_transformed>=0.0004, color("cranberry") title("All data <28 weeks (sex=`sex'), inverse-transformed weibull")
	pdfappend

	twoway hist birthweight if birthweight <=2500, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds if preds <=2500, color("cranberry") title("All data <28 weeks (sex=`sex'), weibull")
	pdfappend

	forvalues x = 250(250)2500 {
		di "X = `x'"
		di "counting"
		count if birthweight_transformed<=1/(`x'-250) & birthweight_transformed >1/`x'
		local `x'_data = `r(N)'/`obs'
		di "counting"
		count if preds_transformed <=1/(`x'-250) & preds_transformed >1/`x'
		local `x'_preds = `r(N)'/`obs'
	}

	use `template', clear

	di "begin proportion loop"
	local order = 0
	forvalues x = 250(250)2500 {
		local order = `order'+1
		di "replacing data"
		replace proportion = ``x'_data' if order==`order' & data_type == "data"
		di "replacing preds"
		replace proportion = ``x'_preds' if order==`order' & data_type == "preds"
	}

	di "graphing"
	graph bar proportion, over(data_type) over(birthweight, sort(order) label(labsize(vsmall) alternate)) asyvars bar(1, color(navy)) bar(2, color(cranberry)) bar(3, color(navy)) bar(4, color(cranberry)) bar(5, color(navy)) bar(6, color(cranberry)) legend(lab(1 "Raw data") lab (2 "beta preds")) title("All data <28weeks (sex=`sex'), inverse-transformed weibull")
	pdfappend

}


// 28-32 weeks 
foreach sex in 1 2 {
 
	di "Sex is `sex'"
	di "28-32 weeks"
	use `all' if gestage>=28 & gestage<32 & sex == `sex', clear
	tab sex

	di "we have the data!"
	cap drop *00*
	rename birthweight birthweight_transformed
	weibullfit birthweight_transformed
	summ birthweight_transformed, detail
	local obs = `r(N)'
	qweibull birthweight_transformed, generate(preds_transformed)

	di "reversing transforms"
	gen preds = (preds_transformed)^-1
	gen birthweight = (birthweight_transformed)^-1

	twoway hist birthweight_transformed if birthweight_transformed >=0.0004 & birthweight_transformed <0.04, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds_transformed if preds_transformed>=0.0004, color("cranberry") title("All data 28-32 weeks (sex=`sex'), inverse-transformed weibull")
	pdfappend

	twoway hist birthweight if birthweight <=2500, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds if preds <=2500, color("cranberry") title("All data 28-32 weeks (sex=`sex'), weibull")
	pdfappend

	forvalues x = 250(250)2500 {
		di "X = `x'"
		di "counting"
		count if birthweight_transformed<=1/(`x'-250) & birthweight_transformed >1/`x'
		local `x'_data = `r(N)'/`obs'
		di "counting"
		count if preds_transformed <=1/(`x'-250) & preds_transformed >1/`x'
		local `x'_preds = `r(N)'/`obs'
	}

	use `template', clear

	di "begin proportion loop"
	local order = 0
	forvalues x = 250(250)2500 {
		local order = `order'+1
		di "replacing data"
		replace proportion = ``x'_data' if order==`order' & data_type == "data"
		di "replacing preds"
		replace proportion = ``x'_preds' if order==`order' & data_type == "preds"
	}

	di "graphing"
	graph bar proportion, over(data_type) over(birthweight, sort(order) label(labsize(vsmall) alternate)) asyvars bar(1, color(navy)) bar(2, color(cranberry)) bar(3, color(navy)) bar(4, color(cranberry)) bar(5, color(navy)) bar(6, color(cranberry)) legend(lab(1 "Raw data") lab (2 "beta preds")) title("All data 28-32 weeks (sex=`sex'), inverse-transformed weibull")
	pdfappend

}


// 32-37 weeks
foreach sex in 1 2 {
 
	di "Sex is `sex'"
	di "32-37 weeks"
	use `all' if gestage>=32 & gestage<37 & sex == `sex', clear
	tab sex

	di "we have the data!"
	cap drop *00*
	rename birthweight birthweight_transformed
	weibullfit birthweight_transformed
	summ birthweight_transformed, detail
	local obs = `r(N)'
	qweibull birthweight_transformed, generate(preds_transformed)

	di "reversing transforms"
	gen preds = (preds_transformed)^-1
	gen birthweight = (birthweight_transformed)^-1

	twoway hist birthweight_transformed if birthweight_transformed >=0.0004 & birthweight_transformed <0.04, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds_transformed if preds_transformed>=0.0004, color("cranberry") title("All data 32-37 weeks (sex=`sex'), inverse-transformed weibull")
	pdfappend

	twoway hist birthweight if birthweight <=2500, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds if preds <=2500, color("cranberry") title("All data 32-37 weeks (sex=`sex'), weibull")
	pdfappend

	forvalues x = 250(250)2500 {
		di "X = `x'"
		di "counting"
		count if birthweight_transformed<=1/(`x'-250) & birthweight_transformed >1/`x'
		local `x'_data = `r(N)'/`obs'
		di "counting"
		count if preds_transformed <=1/(`x'-250) & preds_transformed >1/`x'
		local `x'_preds = `r(N)'/`obs'
	}

	use `template', clear

	di "begin proportion loop"
	local order = 0
	forvalues x = 250(250)2500 {
		local order = `order'+1
		di "replacing data"
		replace proportion = ``x'_data' if order==`order' & data_type == "data"
		di "replacing preds"
		replace proportion = ``x'_preds' if order==`order' & data_type == "preds"
	}

	di "graphing"
	graph bar proportion, over(data_type) over(birthweight, sort(order) label(labsize(vsmall) alternate)) asyvars bar(1, color(navy)) bar(2, color(cranberry)) bar(3, color(navy)) bar(4, color(cranberry)) bar(5, color(navy)) bar(6, color(cranberry)) legend(lab(1 "Raw data") lab (2 "beta preds")) title("All data 32-37 weeks (sex=`sex'), inverse-transformed Weibull")
	pdfappend

}


// < 37 weeks
foreach sex in 1 2 {
 
	di "Sex is `sex'"
	di "<37 weeks"
	use `all' if gestage<37 & sex == `sex', clear
	tab sex

	di "we have the data!"
	cap drop *00*
	rename birthweight birthweight_transformed
	weibullfit birthweight_transformed
	summ birthweight_transformed, detail
	local obs = `r(N)'
	qweibull birthweight_transformed, generate(preds_transformed)

	di "reversing transforms"
	gen preds = (preds_transformed)^-1
	gen birthweight = (birthweight_transformed)^-1

	twoway hist birthweight_transformed if birthweight_transformed >=0.0004 & birthweight_transformed <0.04, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds_transformed if preds_transformed>=0.0004, color("cranberry") title("All data <37 weeks (sex=`sex'), inverse-transformed weibull")
	pdfappend

	twoway hist birthweight if birthweight <=2500, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds if preds <=2500, color("cranberry") title("All data <37 weeks (sex=`sex'), weibull")
	pdfappend

	forvalues x = 250(250)2500 {
		di "X = `x'"
		di "counting"
		count if birthweight_transformed <=1/(`x'-250) & birthweight_transformed >1/`x'
		local `x'_data = `r(N)'/`obs'
		di "counting"
		count if preds_transformed <=1/(`x'-250) & preds_transformed >1/`x'
		local `x'_preds = `r(N)'/`obs'
	}

	use `template', clear

	di "begin proportion loop"
	local order = 0
	forvalues x = 250(250)2500 {
		local order = `order'+1
		di "replacing data"
		replace proportion = ``x'_data' if order==`order' & data_type == "data"
		di "replacing preds"
		replace proportion = ``x'_preds' if order==`order' & data_type == "preds"
	}

	di "graphing"
	graph bar proportion, over(data_type) over(birthweight, sort(order) label(labsize(vsmall) alternate)) asyvars bar(1, color(navy)) bar(2, color(cranberry)) bar(3, color(navy)) bar(4, color(cranberry)) bar(5, color(navy)) bar(6, color(cranberry)) legend(lab(1 "Raw data") lab (2 "beta preds")) title("All data <37 weeks (sex=`sex'), inverse-transformed weibull")
	pdfappend

}


pdffinish, view



* ******************************************************************************************
* ** fitting and evaluating beta fits for inverse-transformed data 
* ******************************************************************************************

* use "`j'/temp/steeple/neonatal/microdata_collapse/all_data_inverse.dta", clear
* tempfile all
* save `all'

* clear
* set obs 20
* gen id = _n
* egen order = fill (1 1 2 2 3 3 4 4 5 5 6 6 7 7 8 8 9 9 10 10)
* gen birthweight = ""
* replace birthweight = "0-250g" if order == 1
* replace birthweight = "250-500g" if order == 2
* replace birthweight = "500-750g" if order == 3
* replace birthweight = "750-1000g" if order == 4
* replace birthweight = "1000-1250g" if order == 5
* replace birthweight = "1250-1500g" if order == 6
* replace birthweight = "1500-1750g" if order == 7
* replace birthweight = "1750-2000g" if order == 8
* replace birthweight = "2000-2250g" if order == 9
* replace birthweight = "2250-2500g" if order == 10
* gen data_type = "data" if id == 1 | id == 3 | id == 5 | id == 7 | id == 9 | id ==11 | id == 13 | id == 15 | id == 17 | id == 19
* replace data_type = "preds" if data_type == "" 
* gen proportion = .
* tempfile template
* save `template'

* pdfstart using "H:/Documents/GBD/SGA/beta_inverse_distributions_fit_still_in_inverse.pdf"

* // <28 weeks
* foreach sex in 1 2 {
 
* 	di "Sex is `sex'"
* 	di "<28 weeks"
* 	use `all' if gestage<28 & sex == `sex', clear
* 	tab sex

* 	di "we have the data!"
* 	cap drop *00*
* 	rename birthweight birthweight_transformed
* 	betafit birthweight_transformed
* 	summ birthweight_transformed, detail
* 	local obs = `r(N)'
* 	qbeta birthweight_transformed, generate(preds_transformed)

* 	di "reversing transforms"
* 	gen preds = (preds_transformed)^-1
* 	gen birthweight = (birthweight_transformed)^-1

* 	di "Summaries"
* 	noisily summ birthweight_transformed, detail
* 	noisily summ preds_transformed, detail
* 	noisily summ birthweight, detail
* 	noisily summ preds, detail 


* 	twoway hist birthweight_transformed if birthweight_transformed >=0.0004 & birthweight_transformed <0.01, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds_transformed if preds_transformed>=0.0004, color("cranberry") title("All data <28 weeks (sex=`sex'), inverse-transformed beta")
* 	pdfappend

* 	twoway hist birthweight if birthweight <=2500, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds if birthweight <=2500, color("cranberry") title("All data <28 weeks (sex=`sex'), beta")
* 	pdfappend


* 	forvalues x = 250(250)2500 {
* 		di "X = `x'"
* 		di "counting"
* 		count if birthweight_transformed<=1/(`x'-250) & birthweight_transformed >1/`x'
* 		local `x'_data = `r(N)'/`obs'
* 		di "counting"
* 		count if preds_transformed <=1/(`x'-250) & preds_transformed >1/`x'
* 		local `x'_preds = `r(N)'/`obs'
* 	}

* 	use `template', clear

* 	di "begin proportion loop"
* 	local order = 0
* 	forvalues x = 250(250)2500 {
* 		local order = `order'+1
* 		di "replacing data"
* 		replace proportion = ``x'_data' if order==`order' & data_type == "data"
* 		di "replacing preds"
* 		replace proportion = ``x'_preds' if order==`order' & data_type == "preds"
* 	}

* 	di "graphing"
* 	graph bar proportion, over(data_type) over(birthweight, sort(order) label(labsize(vsmall) alternate)) asyvars bar(1, color(navy)) bar(2, color(cranberry)) bar(3, color(navy)) bar(4, color(cranberry)) bar(5, color(navy)) bar(6, color(cranberry)) legend(lab(1 "Raw data") lab (2 "beta preds")) title("All data <28weeks (sex=`sex'), in inverse space")
* 	pdfappend

* }


* // 28-32 weeks 
* foreach sex in 1 2 {
 
* 	di "Sex is `sex'"
* 	di "28-32 weeks"
* 	use `all' if gestage>=28 & gestage<32 & sex == `sex', clear
* 	tab sex

* 	di "we have the data!"
* 	cap drop *00*
* 	rename birthweight birthweight_transformed
* 	betafit birthweight_transformed
* 	summ birthweight_transformed, detail
* 	local obs = `r(N)'
* 	qbeta birthweight_transformed, generate(preds_transformed)
* 	summ birthweight_transformed, detail
* 	summ preds_transformed, detail
* 	summ birthweight, detail
* 	summ preds, detail 

* 	di "reversing transforms"
* 	gen preds = (preds_transformed)^-1
* 	gen birthweight = (birthweight_transformed)^-1

* 	twoway hist birthweight_transformed if birthweight_transformed >=0.0004 & birthweight_transformed<0.01, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds_transformed if preds_transformed>=0.0004, color("cranberry") title("All data 28-32 weeks (sex=`sex'), inverse-transformed beta")
* 	pdfappend

* 	twoway hist birthweight if birthweight <=2500, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds if preds <=2500, color("cranberry") title("All data 28-32 weeks (sex=`sex'), beta")
* 	pdfappend

* 	forvalues x = 250(250)2500 {
* 		di "X = `x'"
* 		di "counting"
* 		count if birthweight_transformed<=1/(`x'-250) & birthweight_transformed >1/`x'
* 		local `x'_data = `r(N)'/`obs'
* 		di "counting"
* 		count if preds_transformed <=1/(`x'-250) & preds_transformed >1/`x'
* 		local `x'_preds = `r(N)'/`obs'
* 	}

* 	use `template', clear

* 	di "begin proportion loop"
* 	local order = 0
* 	forvalues x = 250(250)2500 {
* 		local order = `order'+1
* 		di "replacing data"
* 		replace proportion = ``x'_data' if order==`order' & data_type == "data"
* 		di "replacing preds"
* 		replace proportion = ``x'_preds' if order==`order' & data_type == "preds"
* 	}

* 	di "graphing"
* 	graph bar proportion, over(data_type) over(birthweight, sort(order) label(labsize(vsmall) alternate)) asyvars bar(1, color(navy)) bar(2, color(cranberry)) bar(3, color(navy)) bar(4, color(cranberry)) bar(5, color(navy)) bar(6, color(cranberry)) legend(lab(1 "Raw data") lab (2 "beta preds")) title("All data 28-32 weeks (sex=`sex'), inverse-transformed beta")
* 	pdfappend

* }


* * // 32-37 weeks
* * foreach sex in 1 2 {
 
* * 	di "Sex is `sex'"
* * 	di "32-37 weeks"
* * 	use `all' if gestage>=32 & gestage<37 & sex == `sex', clear
* * 	tab sex

* * 	di "we have the data!"
* * 	cap drop *00*
* * 	rename birthweight birthweight_transformed
* * 	betafit birthweight_transformed
* * 	summ birthweight_transformed, detail
* * 	local obs = `r(N)'
* * 	qbeta birthweight_transformed, generate(preds_transformed)

* * 	di "reversing transforms"
* * 	gen preds = 1/(preds_transformed)^-1
* * 	gen birthweight = 1/(birthweight_transformed)^-1

* * 	twoway hist birthweight_transformed, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds_transformed, color("cranberry") title("All data 32-37 weeks (sex=`sex'), inverse-transformed beta")
* * 	pdfappend

* * 	twoway hist birthweight, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds, color("cranberry") title("All data 32-37 weeks (sex=`sex'), beta")
* * 	pdfappend

* * 	forvalues x = 250(250)2500 {
* * 		di "X = `x'"
* * 		di "counting"
* * 		count if birthweight_transformed<=1/(`x'-250) & birthweight_transformed >1/`x'
* * 		local `x'_data = `r(N)'/`obs'
* * 		di "counting"
* * 		count if preds_transformed <=1/(`x'-250) & preds_transformed >1/`x'
* * 		local `x'_preds = `r(N)'/`obs'
* * 	}

* * 	use `template', clear

* * 	di "begin proportion loop"
* * 	local order = 0
* * 	forvalues x = 250(250)2500 {
* * 		local order = `order'+1
* * 		di "replacing data"
* * 		replace proportion = ``x'_data' if order==`order' & data_type == "data"
* * 		di "replacing preds"
* * 		replace proportion = ``x'_preds' if order==`order' & data_type == "preds"
* * 	}

* * 	di "graphing"
* * 	graph bar proportion, over(data_type) over(birthweight, sort(order) label(labsize(vsmall) alternate)) asyvars bar(1, color(navy)) bar(2, color(cranberry)) bar(3, color(navy)) bar(4, color(cranberry)) bar(5, color(navy)) bar(6, color(cranberry)) legend(lab(1 "Raw data") lab (2 "beta preds")) title("All data 32-37 weeks (sex=`sex'), inverse-transformed beta")
* * 	pdfappend

* * }


* // < 37 weeks
* foreach sex in 1 2 {
 
* 	di "Sex is `sex'"
* 	di "<37 weeks"
* 	use `all' if gestage<37 & sex == `sex', clear
* 	tab sex

* 	di "we have the data!"
* 	cap drop *00*
* 	rename birthweight birthweight_transformed
* 	betafit birthweight_transformed
* 	summ birthweight_transformed, detail
* 	local obs = `r(N)'
* 	qbeta birthweight_transformed, generate(preds_transformed)

* 	di "reversing transforms"
* 	gen preds = (preds_transformed)^-1
* 	gen birthweight = (birthweight_transformed)^-1

* 	twoway hist birthweight_transformed if birthweight_transformed >=0.0004 & birthweight_transformed <0.01, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit")) || hist preds_transformed if preds_transformed>=0.0004, color("cranberry") title("All data <37 weeks (sex=`sex'), inverse-transformed beta")
* 	pdfappend

* 	twoway hist preds if preds <=2500, color("cranberry") title("All data <37 weeks (sex=`sex'), beta") || hist birthweight if birthweight <=2500, color("navy") legend(lab(1 "Original data") lab(2 "Distribution fit"))
* 	pdfappend


* 	forvalues x = 250(250)2500 {
* 		di "X = `x'"
* 		di "counting"
* 		count if birthweight_transformed<=1/(`x'-250) & birthweight_transformed >1/`x'
* 		local `x'_data = `r(N)'/`obs'
* 		di "counting"
* 		count if preds_transformed <=1/(`x'-250) & preds_transformed >1/`x'
* 		local `x'_preds = `r(N)'/`obs'
* 	}

* 	use `template', clear

* 	di "begin proportion loop"
* 	local order = 0
* 	forvalues x = 250(250)2500 {
* 		local order = `order'+1
* 		di "replacing data"
* 		replace proportion = ``x'_data' if order==`order' & data_type == "data"
* 		di "replacing preds"
* 		replace proportion = ``x'_preds' if order==`order' & data_type == "preds"
* 	}

* 	di "graphing"
* 	graph bar proportion, over(data_type) over(birthweight, sort(order) label(labsize(vsmall) alternate)) asyvars bar(1, color(navy)) bar(2, color(cranberry)) bar(3, color(navy)) bar(4, color(cranberry)) bar(5, color(navy)) bar(6, color(cranberry)) legend(lab(1 "Raw data") lab (2 "beta preds")) title("All data <37 weeks (sex=`sex'), inverse-transformed beta")
* 	pdfappend

* }


* pdffinish, view
