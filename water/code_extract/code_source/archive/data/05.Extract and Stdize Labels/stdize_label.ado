// File Name: stdize_label.ado

// File Purpose: Replace nonstandard label name with standard form
// Author: Leslie Mallinger
// Date: 3/19/10
// Edited on: 

// Additional Comments: 


** define program name and syntax
capture program drop stdize_label
program define stdize_label

syntax, typelist(string) varlist(string) varmatch(string) newlabel(string)

foreach label of local typelist {
	local label = subinstr("`label'", "_", " ", .)
	foreach var of local varlist {
		if regexm("`var'", "`varmatch'") {
			replace `var's = "`newlabel'" if `var' == "`label'"
		}
	}
}

end
