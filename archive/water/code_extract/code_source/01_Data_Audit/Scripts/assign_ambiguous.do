// File Name: validate_categorizations.do

// File Purpose: Check that water and sanitation categories are assigned correctly
// Author: Leslie Mallinger
// Date: 2/4/2011
// Edited on: 

// Additional Comments: 


clear all
// macro drop _all
set mem 500m
set maxvar 10000
set more off
capture log close
capture restore, not


** create locals for relevant files and folders
local data_loc "${data_folder}/Label Keys"
local codes_loc "J:/Usable/Common Indicators/Country Codes/countrycodes_official"
local version "08082011"


** water categories
	** // open regression results
	** use "`data_loc'/DHS/ambiguous_water_results.dta", clear
	** sort labstring
		
	** // browse results
	** gen validated = .
		** ** bottled water
		** edit if regexm(labstring, "bott")
		** tab w_srcedrnk_i if regexm(labstring, "bott"), miss
		** replace validated = 1 if regexm(labstring, "bott")
			** // IMPROVED (4-55)
			
		** ** spring
		** edit if regexm(labstring, "spring")
		** tab w_srcedrnk_i if regexm(labstring, "spring"), miss
		** replace validated = 1 if regexm(labstring, "spring")
			** // UNIMPROVED (47-1)
			
		** ** well inside/into house/yard/neighbor/patio
		** edit if regexm(labstring, "in") & validated != 1
		** tab w_srcedrnk_i if regexm(labstring, "in") & validated != 1, miss
		** replace validated = 1 if regexm(labstring, "in")
			** // IMPROVED (3-25)
			
		** ** public
		** edit if regexm(labstring, "public") & validated != 1
		** tab w_srcedrnk_i if regexm(labstring, "public") & validated != 1, miss
		** replace validated = 1 if regexm(labstring, "public")
			** // SPLIT (18-17)
			
		** ** private
		** edit if regexm(labstring, "private") & validated != 1
		** tab w_srcedrnk_i if regexm(labstring, "private") & validated != 1, miss
		** replace validated = 1 if regexm(labstring, "private")
			** // IMPROVED (0-3)
			
		** ** all wells
		** edit if regexm(labstring, "well")
		** tab w_srcedrnk_i if regexm(labstring, "well"), miss
			** // IMPROVED (31-44)
			
		** ** just well, not public or private or inside
		** edit if regexm(labstring, "well") & validated != 1
		** tab w_srcedrnk_i if regexm(labstring, "well") & validated != 1, miss
		** replace validated = 1 if regexm(labstring, "well")
			** // UNIMPROVED (9-2)
			
		** ** public well
		** edit if regexm(labstring, "well") & regexm(labstring, "public")
		** tab w_srcedrnk_i if regexm(labstring, "well") & regexm(labstring, "public"), miss
			** // SPLIT (17-17)
			
		** ** private well
		** edit if regexm(labstring, "well") & regexm(labstring, "private")
			** // same as just "private"
			** // IMPROVED (0-3)
			
		** ** public/private
		** edit if regexm(labstring, "public") & regexm(labstring, "private")
			** // IMPROVED (0-1)
			
		** ** neighbor
		** edit if regexm(labstring, "neighb")
		** tab w_srcedrnk_i if regexm(labstring, "neighb"), miss
			** // SPLIT (1-2)
			
	// open water list
	insheet using "`data_loc'/label_key_water_validated_`version'.csv", comma clear names
	foreach var of varlist hhconnection-unknownwater {
		rename `var' w`var'
	}
	gen n = _n
	reshape long w, i(n) j(w_std) string
	drop n
	drop if w == ""
	gen w_new = ""
	sort w_std w
	gen w_lc = lower(w)
	
	// change categorizations for halfimproved categories	
		** FIXME need to make bottled water improved
		
		** public service
		replace w_new = "improvedotherwater" if regexm(w_lc, "public service") | regexm(w_lc, "manguera")
		
		** springs
		edit if w_std == "halfimprovedwater" & (regexm(w_lc, "spring") | regexm(w_lc, "manantial") | ///
			regexm(w_lc, "sprong"))
		replace w_new = "unprospring" if w_std == "halfimprovedwater" & (regexm(w_lc, "spring") | regexm(w_lc, "manantial") | ///
			regexm(w_lc, "sprong"))
		
		** public wells
		edit if w_std == "halfimprovedwater" & (regexm(w_lc, "well") | regexm(w_lc, "pozo") | regexm(w_lc, "puit") | ///
			regexm(w_lc, "po�o") | regexm(w_lc, "poco")) & (regexm(w_lc, "public") | regexm(w_lc, "comm") | ///
			regexm(w_lc, "blico")) &! regexm(w_lc, "dwell") & w_new == ""
		replace w_new = "unprowell" if w_std == "halfimprovedwater" & (regexm(w_lc, "well") | regexm(w_lc, "pozo") | regexm(w_lc, "puit") | ///
			regexm(w_lc, "po�o") | regexm(w_lc, "poco")) & (regexm(w_lc, "public") | regexm(w_lc, "comm") | ///
			regexm(w_lc, "blico")) &! regexm(w_lc, "dwell") & w_new == ""
			
		** private wells
		edit if w_std == "halfimprovedwater" & (regexm(w_lc, "well") | regexm(w_lc, "pozo") | regexm(w_lc, "puit") | ///
			regexm(w_lc, "po�o") | regexm(w_lc, "poco")) & (regexm(w_lc, "private") | regexm(w_lc, "neigh") | ///
			regexm(w_lc, "well in") | regexm(w_lc, "privado"))
		replace w_new = "prowell" if w_std == "halfimprovedwater" & (regexm(w_lc, "well") | regexm(w_lc, "pozo") | regexm(w_lc, "puit") | ///
			regexm(w_lc, "po�o") | regexm(w_lc, "poco")) & (regexm(w_lc, "private") | regexm(w_lc, "neigh") | ///
			regexm(w_lc, "well in") | regexm(w_lc, "privado"))
		replace w_new = "prowell" if w == "well water (residence or yard)"
		
		** other private
		edit if w_std == "halfimprovedwater" & regexm(w_lc, "private") & w_new == ""
		replace w_new = "improvedotherwater" if w_std == "halfimprovedwater" & regexm(w_lc, "private") & w_new == ""
		replace w_new = "improvedotherwater" if w == "Priv. outside"

		** wells (public/private unspecified)
		edit if w_std == "halfimprovedwater" & (regexm(w_lc, "well") | regexm(w_lc, "pozo") | ///
			regexm(w_lc, "puit") | regexm(w_lc, "wall") | regexm(w_lc, "po�o") | regexm(w_lc, "poco")) & w_new == ""
		replace w_new = "unprowell" if w_std == "halfimprovedwater" & (regexm(w_lc, "well") | regexm(w_lc, "pozo") | ///
			regexm(w_lc, "puit") | regexm(w_lc, "wall") | regexm(w_lc, "po�o") | regexm(w_lc, "poco")) & w_new == ""
		replace w_new = "unprowell" if w == "Sem bomba manual"
		replace w_new = "unprospring" if w == "Bunar ili vrelo"
		
		edit if w_std == "halfimprovedwater" & (regexm(w_lc, "ground") | regexm(w_lc, "embasada") | regexm(w_lc, "furo"))
		replace w_new = "unprowell" if w_std == "halfimprovedwater" & (regexm(w_lc, "ground") | regexm(w_lc, "embasada") | regexm(w_lc, "furo"))
		
		** cisterns
		edit if w_std == "halfimprovedwater" & (regexm(w_lc, "citerne") | regexm(w_lc, "cistern") | ///
			regexm(w_lc, "Cistern") | regexm(w_lc, "CISTERN") | regexm(w_lc, "Aljibe") | ///
			regexm(w_lc, "aljibe") | regexm(w_lc, "ALJIBE") | regexm(w_lc, "drum") | ///
			regexm(w_lc, "Drum") | regexm(w_lc, "DRUM"))
		replace w_new = "rainwater" if w_std == "halfimprovedwater" & (regexm(w_lc, "citerne") | regexm(w_lc, "cistern") | ///
			regexm(w_lc, "Cistern") | regexm(w_lc, "CISTERN") | regexm(w_lc, "Aljibe") | ///
			regexm(w_lc, "aljibe") | regexm(w_lc, "ALJIBE") | regexm(w_lc, "drum") | ///
			regexm(w_lc, "Drum") | regexm(w_lc, "DRUM"))
		
		** remaining public
		edit if w_std == "halfimprovedwater" & regexm(w_lc, "public") & w_new == ""
		replace w_new = "hhconnection" if w == "public network"
		replace w_new = "unimprovedotherwater" if w_std == "halfimprovedwater" & regexm(w_lc, "public") & w_new == ""
		
		** cart, truck, or pipe
		edit if w_std == "halfimprovedwater" & regexm(w_lc, "carreta") & regexm(w_lc, "pipa")
		replace w_new = "carttruck" if w_std == "halfimprovedwater" & regexm(w_lc, "carreta") & regexm(w_lc, "pipa")
		
		** in house, on property, in neighbor's house, etc.
		edit if w_std == "halfimprovedwater" & (regexm(w_lc, "dentro") | regexm(w_lc, "dans la") | ///
			regexm(w_lc, "in") | regexm(w_lc, "paja") | regexm(w_lc, "neigh") | regexm(w_lc, "house") | ///
			regexm(w_lc, "viv")) & w_new == ""
		replace w_new = "improvedotherwater" if w_std == "halfimprovedwater" & (regexm(w_lc, "dentro") | regexm(w_lc, "dans la") | ///
			regexm(w_lc, "in") | regexm(w_lc, "paja") | regexm(w_lc, "neigh") | regexm(w_lc, "house") | ///
			regexm(w_lc, "viv")) & w_new == ""
			
		** own system
		replace w_new = "improvedotherwater" if w_std == "halfimprovedwater" & w == "own system of water supply"
		
		** everything else
		replace w_new = "unimprovedotherwater" if w_std == "halfimprovedwater" & w_new == ""
		
		** non-halfimproved
		replace w_new = w_std if w_new == ""
		
	// get the data back into its original format
	sort w_new w_lc
	keep w w_new
	bysort w_new: egen n = seq()
	reshape wide w, i(n) j(w_new) string
	local vars bottled carttruck hhconnection improvedotherwater missingwater otherwater ///
		prospring prowell pubtapstandpipe rainwater surface tubewellborehole unimprovedotherwater ///
		unknownwater unprospring unprowell
	foreach var of local vars {
		rename w`var' `var'
	}
	drop n
	gen halfimprovedwater = "PLACEHOLDER" if _n == 1
	order hhconnection pubtapstandpipe tubewellborehole prowell prospring rainwater unprowell unprospring ///
		carttruck bottled surface otherwater missingwater improvedotherwater unimprovedotherwater halfimprovedwater ///
		unknownwater, first
	outsheet using "`data_loc'/label_key_water_assigned_`version'.csv", comma replace names
	
	
** sanitation categories
	** // open regression results
	** use "`data_loc'/DHS/ambiguous_sanitation_results.dta", clear
	** sort labstring
		
	** // browse results
	** gen validated = .
		** ** traditional
		** edit if regexm(labstring, "trad")
		** tab t_type_i if regexm(labstring, "trad"), miss
		** replace validated = 1 if regexm(labstring, "trad")
			** // UNIMPROVED (29-2-24)
			
		** ** traditional latrine
		** edit if regexm(labstring, "trad") & regexm(labstring, "latr")
		** tab t_type_i if regexm(labstring, "trad") & regexm(labstring, "latr")
			** // SPLIT (4-4)
			
		** ** traditional toilet
		** edit if regexm(labstring, "trad") & regexm(labstring, "toil")
		** tab t_type_i if regexm(labstring, "trad") & regexm(labstring, "toil")
			** // UNIMPROVED (25-2-20)
			
		** ** traditional pit
		** edit if regexm(labstring, "trad") & regexm(labstring, "pit")
		** tab t_type_i if regexm(labstring, "trad") & regexm(labstring, "pit")
			** // UNIMPROVED (27-2-22)
			
		** ** pit (non-traditional)
		** edit if regexm(labstring, "pit") & validated != 1
		** tab t_type_i if regexm(labstring, "pit") & validated != 1
		** replace validated = 1 if regexm(labstring, "pit") & validated != 1
			** // UNIMPROVED (14-1-8)
			
		** ** pit (including traditional)
		** edit if regexm(labstring, "pit")
		** tab t_type_i if regexm(labstring, "pit")
			** // UNIMPROVED (41-3-30)
			
		** ** latrine (all)
		** edit if regexm(labstring, "latrine")
		** tab t_type_i if regexm(labstring, "latrine")
			** // UNIMPROVED (19-1-16)
			
		** ** latrine (non-traditional, non-pit)
		** edit if regexm(labstring, "latrine") & validated != 1
		** tab t_type_i if regexm(labstring, "latrine") & validated != 1
		** replace validated = 1 if regexm(labstring, "latrine") & validated != 1
			** // SPLIT (6-5)
			
		** ** private (all)
		** edit if regexm(labstring, "priv") | regexm(labstring, "personal")
		** tab t_type_i if regexm(labstring, "priv") | regexm(labstring, "personal")
			** // UNIMPROVED (4-3)
			
		** ** private (non-validated)
		** edit if (regexm(labstring, "priv") | regexm(labstring, "personal")) & validated != 1
		** tab t_type_i if (regexm(labstring, "priv") | regexm(labstring, "personal")) & validated != 1
		** replace validated = 1 if regexm(labstring, "priv")
			** // IMPROVED (2-3)
			
		** ** public (all)
		** edit if regexm(labstring, "publ") | regexm(labstring, "comm")
		** tab t_type_i if regexm(labstring, "publ") | regexm(labstring, "comm")
			** // UNIMPROVED (4-1)
			
		** ** public (non-validated)
		** edit if (regexm(labstring, "publ") | regexm(labstring, "comm")) & validated != 1
		** replace validated = 1 if (regexm(labstring, "publ") | regexm(labstring, "comm"))
			** // same as all public
			** // UNIMPROVED (4-0)
			
		** ** toilet (all)
		** edit if (regexm(labstring, "toil") | regexm(labstring, "w.c"))
		** tab t_type_i if (regexm(labstring, "toil") | regexm(labstring, "w.c"))
			** // UNIMPROVED (33-3-28)
			
		** ** toilet (non-validated)
		** edit if (regexm(labstring, "toil") | regexm(labstring, "w.c")) & validated != 1
		** tab t_type_i if (regexm(labstring, "toil") | regexm(labstring, "w.c")) & validated != 1
		** replace validated = 1 if (regexm(labstring, "toil") | regexm(labstring, "w.c"))
			** // IMPROVED (2-3)
			
		** ** everything else
		** edit if validated != 1
		
	// open sanitation list
	insheet using "`data_loc'/label_key_sanitation_validated_`version'.csv", comma clear names
	foreach var of varlist  pubsewer-unknownsan {
		rename `var' s`var'
	}
	gen n = _n
	reshape long s, i(n) j(s_std) string
	drop n
	drop if s == ""
	gen s_new = ""
	sort s_std s
	gen s_lc = lower(s)
		
		** traditional
		edit if s_std == "halfimprovedsan" & regexm(s_lc, "trad")
		replace s_new = "openlatrine" if s_std == "halfimprovedsan" & regexm(s_lc, "trad")
		
		** pit
		edit if s_std == "halfimprovedsan" & (regexm(s_lc, "pit") | regexm(s_lc, "foss")) & s_new == ""
		replace s_new = "simplepit" if s == "pit latrine with drainage"
		replace s_new = "openlatrine" if s_std == "halfimprovedsan" & (regexm(s_lc, "pit") | regexm(s_lc, "foss")) & s_new == ""
		
		** latrine
		edit if s_std == "halfimprovedsan" & (regexm(s_lc, "latrin") | regexm(s_lc, "letrin")) & s_new == ""
		edit if s_std == "halfimprovedsan" & (regexm(s_lc, "acuation") | regexm(s_lc, "acuaci�n")) & s_new == ""
		replace s_new = "vip" if s_std == "halfimprovedsan" & (regexm(s_lc, "acuation") | regexm(s_lc, "acuaci�n")) & s_new == ""
		edit if s_std == "halfimprovedsan" & (regexm(s_lc, "latrin") | regexm(s_lc, "letrin")) & s_new == ""
		replace s_new = "openlatrine" if s_std == "halfimprovedsan" & (regexm(s_lc, "latrin") | regexm(s_lc, "letrin")) & s_new == ""
		replace s_new = "openlatrine" if s_std == "halfimprovedsan" & regexm(s_lc, "sans ch d eau") & s_new == ""
		
		** private toilet
		edit if s_std == "halfimprovedsan" & (regexm(s_lc, "priv") | regexm(s_lc, "personal") | ///
			regexm(s_lc, "insid") | regexm(s_lc, "int") | regexm(s_lc, "indiv") | regexm(s_lc, "exlus")) & (regexm(s_lc, "toil") | ///
			regexm(s_lc, "w.c") | regexm(s_lc, "wc") | regexm(s_lc, "inodoro") | regexm(s_lc, "excusad") | ///
			regexm(s_lc, "water closet")) & s_new == ""
		replace s_new = "improvedothersan" if s_std == "halfimprovedsan" & (regexm(s_lc, "priv") | regexm(s_lc, "personal") | ///
			regexm(s_lc, "insid") | regexm(s_lc, "int") | regexm(s_lc, "indiv") | regexm(s_lc, "exclus")) & (regexm(s_lc, "toil") | ///
			regexm(s_lc, "w.c") | regexm(s_lc, "wc") | regexm(s_lc, "inodoro") | regexm(s_lc, "excusad") | ///
			regexm(s_lc, "water closet")) & s_new == "" & s != "no private toilet"
		
		** public toilet
		edit if s_std == "halfimprovedsan" & (regexm(s_lc, "comm") | regexm(s_lc, "publ") | ///
			regexm(s_lc, "lectiv") | regexm(s_lc, "shar") | regexm(s_lc, "collect") | regexm(s_lc, "compartido") | ///
			regexm(s_lc, "no private")) & (regexm(s_lc, "toil") | regexm(s_lc, "w.c") | regexm(s_lc, "wc") | ///
			regexm(s_lc, "inodoro") | regexm(s_lc, "excusad") | regexm(s_lc, "water closet")) & s_new == ""
		replace s_new = "unimprovedothersan" if s_std == "halfimprovedsan" & (regexm(s_lc, "comm") | regexm(s_lc, "publ") | ///
			regexm(s_lc, "lectiv") | regexm(s_lc, "shar") | regexm(s_lc, "collect") | regexm(s_lc, "compartido") | ///
			regexm(s_lc, "no private")) & (regexm(s_lc, "toil") | regexm(s_lc, "w.c") | regexm(s_lc, "wc") | ///
			regexm(s_lc, "inodoro") | regexm(s_lc, "excusad") | regexm(s_lc, "water closet")) & s_new == ""
		
		** other (non-public, non-pit, non-traditional) toilet
		edit if s_std == "halfimprovedsan" & (regexm(s_lc, "toil") | regexm(s_lc, "w.c") | ///
			regexm(s_lc, "wc") | regexm(s_lc, "inodoro") | regexm(s_lc, "excusad") | regexm(s_lc, "water closet") | ///
			regexm(s_lc, "servicio sanitario")) & s_new == ""
		replace s_new = "improvedothersan" if s_std == "halfimprovedsan" & (regexm(s_lc, "toil") | regexm(s_lc, "w.c") | ///
			regexm(s_lc, "wc") | regexm(s_lc, "inodoro") | regexm(s_lc, "excusad") | regexm(s_lc, "water closet") | ///
			regexm(s_lc, "servicio sanitario")) & s_new == ""
			
		** public
		edit if s_std == "halfimprovedsan" & (regexm(s_lc, "pub") | regexm(s_lc, "com") | regexm(s_lc, "shar")) & ///
			s_new == ""
		replace s_new = "unimprovedothersan" if s_std == "halfimprovedsan" & (regexm(s_lc, "pub") | regexm(s_lc, "com") | regexm(s_lc, "shar")) & ///
			s_new == ""
			
		** other private
		edit if s_std == "halfimprovedsan" & (regexm(s_lc, "priv") | regexm(s_lc, "personal") | ///
			regexm(s_lc, "in") | regexm(s_lc, "int") | regexm(s_lc, "indiv") | regexm(s_lc, "exclus") | ///
			regexm(s_lc, "household")) & s_new == "" & s != "gutter/drain" & s != "has no drainage"
		replace s_new = "improvedothersan" if s_std == "halfimprovedsan" & (regexm(s_lc, "priv") | regexm(s_lc, "personal") | ///
			regexm(s_lc, "in") | regexm(s_lc, "int") | regexm(s_lc, "indiv") | regexm(s_lc, "exclus") | ///
			regexm(s_lc, "household")) & s_new == "" & s != "gutter/drain" & s != "has no drainage"
		
		** simple pit
		replace s_new = "simplepit" if s == "FOSA SIMPLE"
		
		** everything else
		replace s_new = "unimprovedothersan" if s_std == "halfimprovedsan" & s_new == ""
		
		** non-halfimproved
		replace s_new = s_std if s_std != "halfimprovedsan"
		
	// get the data back into its original format
	sort s_new s_lc
	keep s s_new
	bysort s_new: egen n = seq()
	reshape wide s, i(n) j(s_new) string
	local vars bucket composting hanging improvedothersan missingsan opendef openlatrine othersan ///
		pourflush pubsewer septic simplepit unimprovedothersan unknownsan vip
	foreach var of local vars {
		rename s`var' `var'
	}
	drop n
	gen halfimprovedsan = "PLACEHOLDER" if _n == 1
	order pubsewer septic pourflush simplepit vip composting bucket openlatrine hanging opendef ///
		othersan missingsan improvedothersan unimprovedothersan halfimprovedsan unknownsan, first
	outsheet using "`data_loc'/label_key_sanitation_assigned_`version'.csv", comma replace names
	