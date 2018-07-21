// File Name: open_file.ado

// File Purpose: FIXME
// Author: Leslie Mallinger
// Date: 3/5/10
// Edited on: 

// Additional Comments: 


** define program name and syntax
capture program drop open_file
program define open_file

syntax, filenum(integer)

// save countryname and filename as locals, then print
mata: st_local("countryname", files[`filenum', 1])
mata: st_local("filedir", files[`filenum', 2])
mata: st_local("filename", files[`filenum', 3])
display in red "countryname: `countryname'" _newline "filename: `filename'" _newline "filenum: `filenum'"

// open file, then lookfor variables of interest and save in appropriate vector
use "`filedir'/`filename'", clear

end
