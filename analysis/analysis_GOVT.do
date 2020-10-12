**Define paths 
*-------------------------------------------------------------------------------
	
	*Main directory of the project (this may change by analyst)
	
	if c(username) == "andre" {
		global dir_project = "C:/repositaries/1.work/ERP"
	}

	
	*Run the paths and globals of the project
	do "$dir_project/analysis/set_up.do"
	
	
	
** Read Government data
*---------------------------------------------------------------------------------------------
	import excel "$dir_downloads/1. ERP government budgets 2017-20.xlsx", sheet("GovtERPspend") firstrow clear
	
	
* RENAME VARIABLES 
*------------------------------------------------------------------------------
	
	*ssc install nrow
	replace B = "Project" if B == "Project name"	
	nrow
	ds
	
	foreach var in `r(varlist)' {
		di `var'
		*use the first value row
		rename `var' `=`var'[1]'
		

	
	}
	
	*drop first row and not needed rows
	drop in 1 
	drop if inlist(District, "", "Total")
	
	
	rename implementer_summary implementor_summary
	
	*transform all variables in numeric (so merging with projects data is possible)
	ds Spend* Spnd*
	
	foreach var in `r(varlist)' {
	
		destring `var', replace
		
	}
	
	
	*export to clean data
	export excel using "$dir_clean\ERP_government.xlsx", firstrow(variables) replace sheet("GOVTProjects")	 

	