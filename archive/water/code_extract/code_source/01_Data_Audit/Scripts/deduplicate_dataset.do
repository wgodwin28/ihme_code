/*Purpose: To de-duplicate dataset
Author: Astha KC
Date: 12/11/2013
NOTE: Unfortunately, because of inconsistencies in the nomenclature of various survey families and country-specific surveys this step of dedupping the dataset involves 
manually reviewing the dataset and flagging and dropping duplicate observations.*/

**Housekeeping
clear all
set more off

**Set relevant locals
local compiled_folder	"C:/Users/asthak/Documents/Covariates/Water and Sanitation/data/Compiled"

**Load dataset
use "`compiled_folder'/prev_all_final.dta", clear

iso3=="AFG" endyear=="2005" & source=="NRVS05"
iso3=="AFG" endyear=="2010" & source=="MIS09"
iso3=="ATG" endyear=="1991" & plot=="Report"
iso3=="BRB" endyear=="1990" & plot=="Report"
iso3=="BLZ" endyear=="1991" & source=="CEN91"
iso3=="BLZ" endyear=="2000" & ( source=="CEN00" | plot=="Report" )
iso3=="BDI" endyear=="2000" & source=="ENECEF00"
iso3=="BWA" & endyear=="1993"
iso3=="BWA" & endyear=="2001" & (source=="BAIS01" | source=="CEN01")
iso3=="BWA" & endyear=="2004" & source=="BAIS04"
iso3=="BWA" & endyear=="2006" & source=="BDS06"
iso3=="BWA" & startyear=="2007" & source=="BFHS07"
iso3=="BWA" & endyear=="2008" & source=="BAIS08"
iso3=="CPV" & endyear=="2007" & source=="QUIBB07"
iso3=="CPV" & endyear=="2010" & source=="CEN10"
iso3=="DOM" & endyear=="2006" & source=="ENH06"
iso3=="ETH" & endyear=="2007" & (plot=="Report" | plot=="JMP")
iso3=="GRD" & endyear=="2001" & source=="CEN01"
iso3=="GTM" & endyear=="2000" & source=="ENCOVI00"
iso3=="GTM" & endyear=="2006" & source=="ENCOVI06"
iso3=="GUY" & endyear=="1991" & plot=="Report"
iso3=="GUY" & endyear=="2002" & source=="CEN02"
iso3=="HND" & endyear=="1988" & source=="CEN88"
iso3=="HTI" & endyear=="2001" & plot=="JMP"
iso3=="HTI" & endyear=="2012" & source=="pDHS12"
iso3=="IND" & endyear=="2011" & source=="CEN11"

iso3=="IDN" & endyear=="1995" & svy=="IPUMS"
iso3=="IDN" & endyear=="1997" & source=="SUS97"
iso3=="IDN" & endyear=="1998" 
iso3=="IDN" & endyear=="1999"
iso3=="IDN" & endyear=="2001"
iso3=="IDN" & endyear=="2002"
iso3=="IDN" & endyear=="2003"
iso3=="IDN" & endyear=="2004"
iso3=="IDN" & endyear=="2005"
iso3=="IDN" & endyear=="2006"
iso3=="IDN" & endyear=="2007"
iso3=="IDN" & endyear=="1008"
iso3=="IDN" & endyear=="2009" & 
iso3=="IDN" & endyear=="2010" & source=="SUS10"

iso3=="JAM" & endyear=="1991"

iso3=="KEN" & endyear=="2009" & source=="CEN09"
iso3=="KHM" & endyear=="1996" & plot=="Report"
iso3=="KHM" & endyear=="1997" & plot=="Report"
iso3=="LBR" & endyear=="2007" & source=="CWIQ07"
iso3=="LCA" & endyear=="1980" & plot=="Report"
iso3=="LCA" & endyear=="1991" & plot=="Report"
iso3=="LCA" & endyear=="2010" & source=="CEN10"
iso3=="LSO" & endyear=="2006" & source=="CEN06"
iso3=="MUS" & endyear=="2000" & source=="CEN00"
iso3=="MUS" & endyear=="2011" & source=="CEN11"
iso3=="MWI" & endyear=="1987" & filename==""
iso3=="MWI" & endyear=="2005" & source=="WMS05"
iso3=="MWI" & endyear=="2007" & source=="WMS07"
iso3=="MWI" & endyear=="2008" & source=="WMS08"
iso3=="MWI" & endyear=="2009" & source=="WMS09"
iso3=="NGA" & endyear=="2007" & filename==""
iso3=="NIC" & endyear=="1995" & filename==""
iso3=="NIC" & endyear=="2005" & plot=="Report"
iso3=="PAK" & endyear=="2004" & filename==""
iso3=="PAK" & endyear=="2005" & source=="PSLM05"
iso3=="PAK" & endyear=="2007" & filename==""
iso3=="PRK" & endyear=="2000" & source=="MICS00"
iso3=="PRK" & endyear=="2008" & source=="CEN08"
iso3=="SDN" & endyear=="1989" & module=="WN"
iso3=="SDN" & endyear=="2006" & source=="SHHS06"
iso3=="SLV" & endyear=="1988" & source=="FESAL88"
iso3=="SLV" & endyear=="1993" & source=="FESAL93"
iso3=="SLV" & endyear=="1998" & source=="FESAL98"
iso3=="SLV" & endyear=="2003" & source=="FESAL03"
iso3=="SLV" & endyear=="2007" & source=="Report"
iso3=="SUR" & endyear=="2004" & source=="CEN04"
iso3=="TJK" & endyear=="2007" & plot=="Report"
iso3=="TTO" & endyear=="1990" & source=="CEN90"
iso3=="TTO" & endyear=="2000" & filename==""
iso3=="TTO" & endyear=="2005" & source=="MICS05"
iso3=="TUR" & endyear=="2008" & source=="DHS08"
iso3=="URY" & endyear=="1985" & filename==""
iso3=="URY" & endyear=="2006" & source=="ENH06"
iso3=="VCT" & endyear=="2001" & source=="CEN01"
iso3=="VNM" & endyear=="2004" & source=="LSS04"
iso3=="VNM" & endyear=="2009" & source=="CEN09"
iso3=="WSM" & endyear=="2008" & source=="HIES08"
iso3=="ZMB" & endyear=="2008" & source=="HSCS08"
iso3=="ZWE" & endyear=="2009" & source=="MIMS09"
