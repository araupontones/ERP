**Define paths 
*-------------------------------------------------------------------------------
	
	*Main directory of the project (this may change by analyst)
	
	if c(username) == "andre" {
		global dir_project = "C:/repositaries/1.work/ERP"
	}

	
	*Run the paths and globals of the project
	do "$dir_project/analysis/set_up.do"
	
	
	
**1) READ CLEAN GOVERNMENT AND CLEAN PROJECTS DATA
	import excel using "$dir_clean\ERP_government.xlsx", sheet("GOVTProjects") first clear	
	
	*Generate ID for projects in the government data
	gen seq = _n
	tostring seq, gen(ID)
	replace ID = "GOVT" + ID
	drop seq
	drop District

	
	
	
	tempfile government
	save `government', replace
	
	
	
	
	import excel using "$dir_clean\ERP_projects.xlsx", first clear	
	
	drop donor_category* implementor_category*
	
	merge 1:1 ID using `government', nogen 
	
	
	**EXPORT COMBINED DATA TO Clean directory
	rename implementor_summary summary_implementor
	export excel using "$dir_clean\ERP.xlsx", firstrow(variables) replace 	 

	

********************************************************************************

* RESHAPE AND EXPORT IN DASHBOARD READABLE FORMAT

********************************************************************************
	
	*drop variables with sensitive info
	
	drop Project budget_USD spent_USD execution_rate date_start ///
	date_up_todate date_end Months monthly_spend_all Districts_RHC districts_number ///
	perc_subcounties Prop_district_school_level Spendprop_Distlevel_all ///
	Outcome_* sum_* Programme_* Activity_*  pr_budget pr_budget_currency ///
	pr_total_spent pr_spending_currency active_* Spendprop* A_erp 
	
	
	* identify variables thar are unique at the project level
	local single_values  Spend_RHC_3Ys_all ///
	Spend_RHC_3Ys_ERPspec erp_relevant_prop Spend_RHC_3Ys_ERPrel ///
	Spend_RHC_3Ys_ERPspec_Nat Spend_RHC_3Ys_ERPspec_Dist donor_summary spent_3ys_all ///
	summary_implementor link Organisation
	
	
	*1) table for projects with variables that are unique at the project level
	
	
	preserve
	
	keep `single_values' ID
		
	
	rename Spend_RHC_3Ys_ERPspec_Dist District_spend
	rename Spend_RHC_3Ys_ERPspec_Nat National_spend
	
	rename Spend_RHC_3Ys_ERPrel relevant_spend //ERP relevant spending in the 3fy
	rename Spend_RHC_3Ys_ERPspec specific_spend //ERP relevant spending in the 3fy
	
	rename spent_3ys_all total_ERP_3Y // total spending in years 0-2
	rename Spend_RHC_3Ys_all total_RHC_3Y // total RHC
	
	*rename spent_USD USD_spent // total spend since project started 
	
	drop total_*
	
	gen last_update = "Last update: $S_DATE"
	
	export excel using "$dir_dashboard\Projects.xlsx", firstrow(variables) replace sheet("Projects")
	
	restore
	
*2) Make table longer for effective visualization
	
	drop `single_values' 
	

*3) clean some indicators to reshape data from wide to long

	*make names of spending by district shorter (other wise the dofile breaks)
	ds Spnd_RHC_3Ys_ERPspec_*
	
	foreach var in `r(varlist)' {
	
	local new_name =  subinstr("`var'", "RHC_3Ys_ERPspec_", "", . )
	rename `var' `new_name'	
	
	}
	
	reshape long Spend_ Spnd spent_, i(ID) j(prefix) string
	
	gen area = ""
	replace area = "All areas" if strpos(prefix, "all") | strpos(prefix, "USD")
	replace area = "ERP specific" if strpos(prefix, "ERPspec")
	
	
	**FINANCIAL YEAR (2017, 2018, 2019, 3FYS, TOTAL)
	gen financial_year = ""
	
	replace financial_year = "Year 0" if strpos(prefix,"0_all") | strpos(prefix, "Y0")
	replace financial_year = "Year 1" if strpos(prefix, "1_all") | strpos(prefix, "Y1")
	replace financial_year = "Year 2" if strpos(prefix,"2_all") | strpos(prefix, "Y2")
	replace financial_year = "3 FYs" if strpos(prefix,"3ys_all") | strpos(prefix,"3Ys")
	

*4) LEVELS AND DIMENSIONS
	gen level = ""
	gen dimension = ""
		
	
	*these globals are defined in the set_up.do 
 foreach y in $programme_dictionary $outcome_dictionary $activity_dictionary_projects{
	di "`y'"
	replace level = word("`y'",3) if strpos(prefix, word("`y'",1))
	replace dimension = word("`y'",2) if strpos(prefix, word("`y'",1))
	
 } 
 
 *get rid of the under score for dimension
	replace dimension = subinstr(dimension, "_"," ", .)
	replace dimension = "Other" if dimension == "Outcome 4"
	

*5) LEVELS AND DIMENSIONS FOR DISTRICTS

*District level
	foreach d in $distritos {
		
		replace area = "ERP specific" if strpos(prefix,"`d'")
		replace financial_year = "3 FYS" if strpos(prefix,"`d'")
		replace level = "District level" if strpos(prefix,"`d'")
		replace dimension = "`d'" if strpos(prefix, "`d'")
	}
	

*6) make a single spending column
	
	replace Spnd = Spend_ if Spnd == .
	replace Spnd = spent_ if Spnd == .
	drop if Spnd == .
	rename Spnd Spend
	drop Spend_ spent_ prefix
	
	
	export excel using "$dir_dashboard\Projects.xlsx", firstrow(variables) sheetreplace sheet("Spending")
