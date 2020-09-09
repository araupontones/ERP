

**Define paths 
*-------------------------------------------------------------------------------
	
	*Main directory of the project (this may change by analyst)
	
	if c(username) == "andre" {
		global dir_project = "C:/repositaries/1.work/ERP"
	}


	
	*Directory where data from zoho is downloaded to:
	global dir_downloads = "$dir_project/downloads"
	global dir_clean =  "$dir_project/clean_data"
	
	
	
**Lookup values for analysis
*------------------------------------------------------------------------------
	
	*Exchange rates into USD: average for the years we are looking at
	*https://www.fiscal.treasury.gov/reports-statements/treasury-reporting-rates-exchange/historical.html December 
	local ex_gbp = 0.7580
	local ex_euro = 0.890
	local ex_ugx = 3660
	
	

**Read data
*-------------------------------------------------------------------------------
	
	
	*Main form
	
	import excel "$dir_downloads/Project_spending.xls", sheet("Sheet1") firstrow clear
	

** Create indicators
* ----------------------------------------------------------------------------
	
*Budget in USD 
	gen budget_USD = .
	replace budget_USD =  pr_budget if pr_budget_currency == "USD"
	replace budget_USD =  pr_budget * `ex_gbp' if pr_budget_currency == "GBP"
	replace budget_USD =  pr_budget * `ex_euro' if pr_budget_currency == "EURO"
	replace budget_USD =  pr_budget / `ex_ugx' if pr_budget_currency == "Ugandan shilling"

*Amoung spent in USD
	gen spent_USD = .
	replace spent_USD =  pr_total_spent if pr_spending_currency == "USD"
	replace spent_USD =  pr_total_spent * `ex_gbp' if pr_spending_currency == "GBP"
	replace spent_USD =  pr_total_spent * `ex_euro' if pr_spending_currency == "EURO"
	replace spent_USD =  pr_total_spent / `ex_ugx' if pr_spending_currency == "Ugandan shilling"
	
	label var spent_USD "Total budget for the duration of the project into USD"
	
*Execution rate
	gen execution_rate = round(spent_USD / budget_USD,.01)
	label var execution_rate "A sense check that they’ve given spend in the correct currency. We won’t use this for any final presentation but some internal QA analysis"
	
	
*Months: total moths of spending reported by the project
	
//transform dates in readable format for stata	
	
	gen date_start = date(pr_date_start, "DMY")
	gen date_until = date(pr_date_endbudget, "DMY")
	gen date_end = date(pr_date_dueend, "DMY")
	drop pr_date_start pr_date_endbudget pr_date_dueend
	
	format date_start date_until date_end %td
	
	gen Months = round((date_until - date_start)/(365/12),.01)
	label var Months "Total months of project spending"
	
	
*Amount spent monthly
	gen monthly_spend_all  = spent_USD / Months
	label var monthly_spend_all "Average spend in every month of the duration of the project"


	

					*-SPEND FOR EACH FINANCIAL YEAR
*------------------------------------------------------------------------------
	
	
*Spend for each financial year

	//calculate number of active months in financial year
	foreach y in "0" "1718" "1819" "1920" {
	
		
		//dates if year 0 (*check this with Nicola)
		if "`y'" == "0" {
		
			
			local start_FY = "1-Jan-2018"
			local end_FY = "30-Jun-2018"
			
		} 
		
		else {
			

			local start_FY = "1-Jul-20" + substr("`y'", 1,2)
			local end_FY = "30-Jun-20" + substr("`y'", 3,4)
		
		}
	
	
	//transform dates in readable numbers for stata
	local start_FY = date("`start_FY'", "DMY")
	local end_FY = date("`end_FY'", "DMY")
	
	

	// Calculate active months in the financial year
	gen active_`y' = .
	
	//count months between project start and end of the financial year (only if project was alive during FY)
	replace active_`y' =  round((`end_FY' - date_start)/(365/12),.1) if date_end >= `start_FY' & date_start <= `end_FY' 
	
	//adjust for those projects that were alive but ended before the end of FY
	replace active_`y' = round((date_end - `start_FY')/(365/12),.1) if date_end  <=  `end_FY' & active_`y' !=. 
	
	//adjust for those projects that were alive but ended after end of FY
	replace active_`y' = 12 if active_`y' >12 & active_`y'!=.
	
	//replace to 0 if missing (this is to be able to sum accross columns)
	*replace active_`y' = 0 if active_`y' ==.
	
	label var active_`y' "Number of months that the project was active in FY `y'"
	
*Calculate amount spent in financial year

	gen spent_`y'_all = monthly_spend_all * active_`y'
	label var spent_`y'_all "Total spend in financial year `y'"
		
	}
	
	

	
*Amount spent in years 0-2 of the ERP

	egen spent_3ys_all = rowtotal(spent_1718_all spent_1819_all spent_1920_all)
	label var spent_3ys_all "Total spending in years 0-2 of ERP"
	

	

					*-SPEND ON REFUGEE HOST COMMUNITIES
*------------------------------------------------------------------------------
	
	
* Proportion of all spending on refugees/host communities at the district level

	//percentage of how focused on refugee hosting subcounties is the spend
	gen perc_subcounties = .
	replace perc_subcounties = 0 if strpos(subcounties_focus, "None")
	replace perc_subcounties = .25 if strpos(subcounties_focus, "Some")
	replace perc_subcounties = .5 if strpos(subcounties_focus, "Half")
	replace perc_subcounties = .75 if strpos(subcounties_focus, "Most")
	replace perc_subcounties = 1 if strpos(subcounties_focus, "All")

	
	//number of ERP districts in which the project works in
	gen Districts_RHC = length(districts_which) - length(subinstr(districts_which, ",", "", .)) + 1
	label var Districts_RHC "Number of ERP districts that the project works in"
	

	
	gen Spendprop_Distlevel_all = (Districts_RHC/districts_number) * perc_subcounties
	replace Spendprop_Distlevel_all = 0 if Spendprop_Distlevel_all==.
	label var Spendprop_Distlevel_all "proportion of all spending on refugees/host communities at the district level"

	

	
*Proportion of all spending on refugees/host communities in total (national and district level)

//clean proportion at national level (from string to numeric) and rename it as Spendprop_Nat_all
	destring prop_national_level, gen(Spendprop_Nat_all)
	drop prop_national_level
	replace Spendprop_Nat_all = Spendprop_Nat_all/100
	*replace Spendprop_Nat_all = 0 if Spendprop_Nat_all==.
	label var Spendprop_Nat_all "Proportion spend at the national level"
	
	
	egen Spendprop_RHC_all = rowtotal(Spendprop_Nat_all Spendprop_Distlevel_all)
	label var Spendprop_RHC_all "the proportion of all spending on refugees/host communities in total (national and district level)"

	

* total spending in years 0-2 that is on RHC, but not necessarily specific to the ERP
	
	gen Spend_RHC_3Ys_all = spent_3ys_all * Spendprop_RHC_all
	label var Spend_RHC_3Ys_all "total spending in years 0-2 that is on RHC, but not necessarily specific to the ERP"
	

* total spending in years 0-2 that is on RHC and specific to the ERP
	
	replace A_erp = A_erp /100
	label var A_erp "Proportion of spending which is ERP specific"
	
	gen Spend_RHC_3Ys_ERPspec =	round(Spend_RHC_3Ys_all * A_erp,.01)
	label var Spend_RHC_3Ys_ERPspec "Total spending in years 0-2 that is on RHC and specific to ERP"


* total spending in years 0-2 that is on RHC and relevant -but not specific to ERP

	destring ERP_relevant_prop, gen(erp_relevant_prop)
	drop ERP_relevant_prop
	replace erp_relevant_prop = erp_relevant_prop / 100
	label var erp_relevant_prop "Proportion of spend that is relevant but not specific to ERP"
	
	
	gen Spend_RHC_3Ys_ERPrel = Spend_RHC_3Ys_all * erp_relevant_prop
	label var Spend_RHC_3Ys_ERPrel "total spending in years 0-2 that is on RHC and relevant – but not specific - to the ERP"
	
 

 
					*-DETAILS OF ERP SPECIFIC SPENDING BY OUTCOME AREA
*------------------------------------------------------------------------------

*Clean variables of ERP specific spending	
	
	//order variables to follow the outcome order of the programme
	order B_learningOpportunities B_QltyEducation B_Systems B_other	
	ds B_*	
	foreach var in `r(varlist)' {
		
		// create name of the new varable with prefix Outcome_
		local newvar =  "Outcome_"+ subinstr("`var'", "B_","",.)
		
		//convert original variabe from text to number
		destring `var', gen(`newvar')
		drop `var'
		
		//divide new variable to 100
		replace `newvar' = round(`newvar'/100, .01)
		format `newvar' %3.2f
		label var `newvar' "Proportion of spending in `newvar'"
		
	}

	
	//Check that the outcomes add to 100
	ds Outcome_*
	egen sum_outcomes = rowtotal(`r(varlist)')
	format sum_outcomes %3.2f
	label var sum_outcomes "QA to check that the sum of the outcomes is 100"
	


* the total spending in years 0-2 that is on RHC and specific to the ERP, on Outcomes
	
	//list all outcome variables
	ds Outcome_*
	local seq = 1
	
	foreach var in `r(varlist)' {
		
		//name of new variable (sufix goes from 1 to 4)
		local newvar = "Spend_RHC_3Ys_ERPspec_0" + "`seq'"
		
		//generate variable
		gen `newvar' = Spend_RHC_3Ys_ERPspec * `var'
		label var `newvar' "the total spending in years 0-2 that is on RHC and specific to the ERP, on `var'"
		
		
		//increase number of sequence
		local seq = `seq' + 1
	
	
	}
	
	
	// check that the four outcome variables sum to Spend_RHC_3Ys_ERPspec
	ds Spend_RHC_3Ys_ERPspec_0*	
	egen sum_ERPspec = rowtotal(`r(varlist)') 
	gen check_ERPspec = round(sum_ERPspec - Spend_RHC_3Ys_ERPspec,1)
	
	
	
 
					*-DETAILS OF ERP SPECIFIC SPENDING BY PROGRAMME LEVEL
*------------------------------------------------------------------------------
	
*Clean variables of programme level spending
	
	//order variables to follow the programme level order of the guide
	
	
	order C_ECD C_Primary C_secondary C_AcceleratedEducation C_Skills C_Systems C_other
	ds C_*	
	foreach var in `r(varlist)' {
		
		// create name of the new varable with prefix Outcome_
		local newvar =  "Programme_"+ subinstr("`var'", "C_","",.)
		
		//convert original variabe from text to number
		destring `var', gen(`newvar')
		drop `var'
		
		//divide new variable to 100
		replace `newvar' = round(`newvar'/100, .01)
		format `newvar' %3.2f
		label var `newvar' "Proportion of spending in `newvar'"
		
	}

	
	
	//Check that the outcomes add to 100
	ds Programme_*
	egen sum_programme = rowtotal(`r(varlist)')
	format sum_programme %3.2f
	label var sum_programme "QA to check that the sum of the programmes is 100"
	
	
	
* the total spending in years 0-2 that is on RHC and specific to the ERP, on Programme levels
	
	//list all outcome variables
	ds Programme_*
		
	foreach var in `r(varlist)' {
		
		
		di "`var'"
		local p_off =  subinstr("`var'", "Programme_", "",.)
		 
		//name of new var
		local newvar = "Spend_RHC_3Ys_ERPspec_" + substr("`p_off'", 1,6)
		
		
		//generate variable
		 gen `newvar' = Spend_RHC_3Ys_ERPspec * `var'
		label var `newvar' "the total spending in years 0-2 that is on RHC and specific to the ERP, on `p_off'"
		
	
	
	}



 
					*-DETAILS OF ERP SPECIFIC SPENDING BY ACTIVITY TYPE
*------------------------------------------------------------------------------
	
*Clean variables of programme level spending
	
	//order variables to follow the programme level order of the guide
	
	
	
	order D_Infrastructure D_Materials D_Salary D_training D_Training_Children D_community D_Strengthening_District D_Strengthening_National D_piloting D_other
	ds D_*
		
	foreach var in `r(varlist)' {
		
		// create name of the new varable with prefix Outcome_
		local newvar =  "Activity_"+ subinstr("`var'", "D_","",.)
		
		//convert original variabe from text to number
		destring `var', gen(`newvar')
		drop `var'
		
		//divide new variable to 100
		replace `newvar' = round(`newvar'/100, .00)
		format `newvar' %3.2f
		label var `newvar' "Proportion of spending in `newvar'"
		
	}

	
	
	
	//Check that the outcomes add to 100
	ds Activity_*
	egen sum_activity = rowtotal(`r(varlist)')
	format sum_activity %3.2f
	label var sum_activity "QA to check that the sum of the Activities is 100"
	
	
* the total spending in years 0-2 that is on RHC and specific to the ERP, on ACTIVITY TYPES
	
	//list all outcome variables
	ds Activity_*
	local seq = 1
		
	foreach var in `r(varlist)' {
		
	
		 
		//name of new var
		local newvar = "Spend_RHC_3Ys_ERPspec_"+ "Act_" + "`seq'"
		
		// name for label of variable
		local a_off =  subinstr("`var'", "Activity_", "",.)
		
		
		//generate variable
		 gen `newvar' = Spend_RHC_3Ys_ERPspec * `var'
		label var `newvar' "the total spending in years 0-2 that is on RHC and specific to the ERP, on `a_off'"
		
		local seq = `seq' + 1
	
	}



					*-DETAILS OF ERP SPECIFIC GEOGRAPHICAL LEVEL
*------------------------------------------------------------------------------
	
	
	
*Variables created : ----------------------------------------------------------
	order Project pr_budget pr_budget_currency pr_total_spent pr_spending_currency ///
	budget_USD spent_USD execution_rate date_start date_until date_end Months monthly_spend_all ///
	active_0 spent_0_all active_1718 spent_1718_all active_1819 spent_1819_all ///
	active_1920 spent_1920_all spent_3ys_all ///
	Districts_RHC districts_number perc_subcounties Spendprop_Distlevel_all ///
	Spendprop_Nat_all Spendprop_RHC_all Spend_RHC_3Ys_all A_erp Spend_RHC_3Ys_ERPspec ///
	erp_relevant_prop Spend_RHC_3Ys_ERPrel Outcome_* sum_outcomes Spend_RHC_3Ys_ERPspec_* ///
	Programme_* sum_programme Activity_* sum_activity 
	
*-------------------------------------------------------------------------------
	
	
*** EXPORT DATA
*-------------------------------------------------------------------------------
	export excel using "$dir_clean\ERP_projects.xlsx", firstrow(variables) replace
	ex

