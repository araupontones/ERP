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
	import excel "$dir_downloads/Copy of 1. Capitation by school 2017-20.xlsx", sheet("GovtERPspend") firstrow clear
	
	
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
	
	

*EXPORT TO DASHBOARD
*------------------------------------------------------------------------------

*1) Export table with unique values by District and Project
	
	//Variables at one level
	
		#delimit ;
			local single_values
			Spend_RHC_3Ys_ERPspec Spend_RHC_3Ys_ERPspec_Nat Spend_RHC_3Ys_ERPspec_Dist
		;
	#delimit cr

	preserve
	
	keep District Project `single_values'
	
	rename Spend_RHC_3Ys_ERPspec  ERP_specific_3Y
	rename Spend_RHC_3Ys_ERPspec_Nat ERP_spec_Nat_3y
	rename Spend_RHC_3Ys_ERPspec_Dist ERP_spec_Dist_3y
	
	*Correct the long digits
	ds ERP*
	foreach var in `r(varlist)' {
	
		replace `var' = substr(`var', 1,  strpos(`var',".")-1)
		
		
	
	}
	
	export excel using "$dir_dashboard\Government.xlsx", firstrow(variables) replace sheet("GOVTProjects")	 
	
	restore
	
*2) Make table longer for effective visualization
	
	drop `single_values'
	
	*make names of spending by district shorter (other wise the dofile breaks)
	ds Spnd_RHC_3Ys_ERPspec_*
	
	foreach var in `r(varlist)' {
	
	local new_name =  subinstr("`var'", "RHC_3Ys_ERPspec_", "", . )
	rename `var' `new_name'	
	
	}
	
	* reshape long
	sort District Project
		
	reshape long Spend_ Spnd, i(Project District) j(prefix) string
	
	
	
	*AREA OF THE SPENDING
	gen area = "ERP specific"
	
	*FINANCIAL YEAR
	gen financial_year = "3 FYs"
	
	*LEVEL AND DIMENSION OF SPENDING (globals are creted in set_up.do)	
	
	
	gen level = ""
	gen dimension = ""
		
	
 foreach y in $programme_dictionary $outcome_dictionary $activity_dictionary{
	di "`y'"
	replace level = word("`y'",3) if strpos(prefix, word("`y'",1))
	replace dimension = word("`y'",2) if strpos(prefix, word("`y'",1))
	
 } 
	
	
	
	*District level
	foreach d in $distritos {
	
		replace level = "District level" if strpos(prefix,"`d'")
		replace dimension = "`d'" if strpos(prefix, "`d'")
	}
	
	
	
	
	
	*get rid of the under score for dimension
	replace dimension = subinstr(dimension, "_"," ", .)
	
	*clean spend variable 
	replace Spend_ = Spnd if Spend_==""	
	drop if Spend_ ==""
	drop Spnd prefix
	rename Spend_ Spend
	
	replace Spend = substr(Spend, 1,  strpos(Spend,".")-1)
	replace Spend = "0" if Spend ==""
		
	export excel using "$dir_dashboard\Government.xlsx", firstrow(variables)  sheetreplace sheet("GovtSpending")
	
	


