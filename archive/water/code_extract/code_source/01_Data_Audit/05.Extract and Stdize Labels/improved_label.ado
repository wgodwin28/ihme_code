// File Name: improved_label.ado

// File Purpose: Replace nonstandard label name with standard form
// Author: Leslie Mallinger
// Date: 3/22/10
// Edited on: 

// Additional Comments: 


** define program name and syntax
capture program drop improved_label
program define improved_label

syntax, typelist(string) varlist(string) varmatch(string) improved(real)

foreach label of local typelist {
	local label = subinstr("`label'", "_", " ", .)
	foreach var of local varlist {
		if regexm("`var's", "`varmatch'") {
			replace `var'i = `improved' if `var's == "`label'"
		}
	}
}

end
