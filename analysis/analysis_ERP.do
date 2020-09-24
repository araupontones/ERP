

**Define paths 
*-------------------------------------------------------------------------------
	
	*Main directory of the project (this may change by analyst)
	
	if c(username) == "andre" {
		global dir_project = "C:/repositaries/1.work/ERP"
	}


	
	*Directory where data from zoho is downloaded to:
	global dir_downloads = "$dir_project/downloads"
	global dir_reference  = "$dir_project/reference_data"
	global dir_clean =  "$dir_project/clean_data"
	global dir_dashboard = "$dir_project/dashboard"
	
	
	
** Read reference data of donors and implementors

	import excel "$dir_reference/list_donors_categories.xlsx", sheet("Sheet1") firstrow clear
	
	keep Donor Category
	rename Category donor_category

	*save file to merge it with the roster of donors
	tempfile ref_donors
	save `ref_donors', replace
	
	import excel "$dir_downloads/Roster_donors2.xls", sheet("Sheet1") firstrow clear
	
	*merge with reference data of donors
	merge  m:1 Donor using `ref_donors', assert(3) nogen
	
	keep ID Donor donor_*
	bys ID: gen seq = _n
	order ID seq
	
	** reshape to have only one row by project (so we can merge with the project's data)
	reshape wide Donor donor_*, i(ID) j(seq)
	
	
	ds donor_category*
	
	*Describe which type of funding the project is receivingS
	gen Category = ""
	foreach var in `r(varlist)' {
	
		
		di "`var'"
		replace Category = Category + `var' if Category == ""
		replace Category = Category + ", " + `var' if `var' !="" & Category !="" & !strpos(Category, `var')
	}
	
	
	**Keep only donor_category and create summary
	keep ID donor_category*
	gen donor_summary = donor_category1
	replace donor_summary = "Combination" if donor_category2 !=""

	
	
	tempfile clean_donors
	save `clean_donors', replace
	
	
	
	
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
	
	
	*merge with data from donors
	merge 1:m ID using `clean_donors', assert(1 3) nogen
	
	

	
** CLEAN OUTCOMES, PROGRAMMES, AND ACTIVITIES 
**------------------------------------------------------------------------------

** Proportion spent by outcome
	
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
	egen sum_outcomes_raw = rowtotal(`r(varlist)')
	format sum_outcome* %3.2f
	label var sum_outcomes_raw "QA to check that the sum of the outcomes is 100"
	
	
*** Clean outcome_other (assuming that the missing information was spent in other)
	
	replace  Outcome_other = Outcome_other + 1 - sum_outcomes_raw if (1 - sum_outcomes_raw)> 0 
	replace Outcome_other = 1 - sum_outcomes_raw if Outcome_other==. & (1 - sum_outcomes_raw)> 0 
	
	

	
** Proportion spent by programme


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
	egen sum_programme_raw = rowtotal(`r(varlist)')
	format sum_programme_raw %3.2f
	label var sum_programme_raw "QA to check that the sum of the programmes is 100"
	
	replace  Programme_other = Programme_other + 1 - sum_programme_raw if (1 - sum_programme_raw)> 0 
	replace Programme_other = 1 - sum_outcomes_raw if Programme_other==. & (1 - sum_programme_raw)> 0 
	

*Clean variables of Activity level spending
	
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
	egen sum_activity_raw = rowtotal(`r(varlist)')
	format sum_activity_raw %3.2f
	label var sum_activity_raw "QA to check that the sum of the Activities is 100"
	
	replace  Activity_other = Activity_other + 1 - sum_activity_raw if (1 - sum_activity_raw)> 0 
	replace Activity_other = 1 - sum_activity_raw if Activity_other==. & (1 - sum_activity_raw)> 0 
	
		
	
	
** Create indicators
* ----------------------------------------------------------------------------
	
*Budget in USD 
	gen budget_USD = .
	replace budget_USD =  pr_budget if pr_budget_currency == "USD"
	replace budget_USD =  pr_budget / `ex_gbp' if pr_budget_currency == "GBP"
	replace budget_USD =  pr_budget / `ex_euro' if pr_budget_currency == "EURO"
	replace budget_USD =  pr_budget / `ex_ugx' if pr_budget_currency == "Ugandan shilling"
	label var budget_USD "Total budget for the duration of the project into USD"

*Amoung spent in USD
	gen spent_USD = .
	replace spent_USD =  pr_total_spent if pr_spending_currency == "USD"
	replace spent_USD =  pr_total_spent / `ex_gbp' if pr_spending_currency == "GBP"
	replace spent_USD =  pr_total_spent / `ex_euro' if pr_spending_currency == "EURO"
	replace spent_USD =  pr_total_spent / `ex_ugx' if pr_spending_currency == "Ugandan shilling"
	
	label var spent_USD "Total spending for the duration of the project into USD"
	
	format budget_USD spent_USD %22.1f
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
	format monthly_spend_all %22.1f
	label var monthly_spend_all "Average spend in every month of the duration of the project"
	
	
	

					*-SPEND FOR EACH FINANCIAL YEAR
*------------------------------------------------------------------------------
	
	
*Spend for each financial year
	
	local seq = 0 
	//calculate number of active months in financial year
	foreach y in "0" "1819" "1920" {
	
	
		
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
	gen active_`seq' = .
	
	//count months between project start and end of the financial year (only if project was alive during FY)
	replace active_`seq' =  round((`end_FY' - date_start)/(365/12),.1) if date_end >= `start_FY' & date_start <= `end_FY' 
	
	//adjust for those projects that were alive but ended before the end of FY
	replace active_`seq' = round((date_end - `start_FY')/(365/12),.1) if date_end  <=  `end_FY' & active_`seq' !=. 
	
	//adjust for those projects that were alive but ended after end of FY
	replace active_`seq' = 12 if active_`seq' >12 & active_`seq'!=.
	
	//replace to 0 if missing (this is to be able to sum accross columns)
	*replace active_`y' = 0 if active_`y' ==.
	
	label var active_`seq' "Number of months that the project was active in FY `seq'"
	
*Calculate amount spent in financial year

	gen spent_`seq'_all = monthly_spend_all * active_`seq'
	label var spent_`seq'_all "Total spend in financial year `seq'"
	
	
	local seq = `seq' + 1
		
	}
	
	format spent_* %22.1f
	
	

	
*Amount spent in years 0-2 of the ERP

	egen spent_3ys_all = rowtotal(spent_0_all spent_1_all spent_2_all)
	label var spent_3ys_all "Total spending in years 0-2 of ERP"
	format spent_* %22.1f



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
	
	
	//Porportio spent at the district level 
	
	
	
	*destring prop_national_level, gen(Prop_district_school_level)
	destring prop_district_level, gen(Prop_district_school_level)
	drop prop_district_level	
	
	replace Prop_district_school_level = Prop_district_school_level/100
	label var Prop_district_school_level "proportion spend at the district/school level"
	format Prop_district_school_level %3.2f

	
	
	gen Spendprop_Distlevel_all = (Districts_RHC/districts_number) * perc_subcounties * Prop_district_school_level
	
	replace Spendprop_Distlevel_all = 0 if Spendprop_Distlevel_all==.
	label var Spendprop_Distlevel_all "proportion of all spending on refugees/host communities at the district level"
	
	format Spendprop_Distlevel_all %3.2f
	


	
*Proportion of all spending on refugees/host communities in total (national and district level)

//clean proportion at national level (from string to numeric) and rename it as Spendprop_Nat_all
	destring prop_national_level, gen(Spendprop_Nat_all)
	drop prop_national_level
	replace Spendprop_Nat_all = Spendprop_Nat_all/100
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
	

	
* the total spending in years 0-2 that is on RHC and specific to the ERP, on ACTIVITY TYPES
	
	//list all outcome variables
	ds Activity_*
		
	// define prefix of activities	
	#delimit ;
local prefix_activities
   "IN
   MA
   TS
   TT
   CH
   CO
   DS
   NS
   PI
   AO"

     ;
#delimit cr


	
	local seq = 1
	foreach var in `r(varlist)' {
		 
		//name of new var
		local newvar = "Spend_RHC_3Ys_ERPspec_"+  word("`prefix_activities'", `seq')
		*di word("`prefix_activities'", `seq')
		di "`var'"
		di "`newvar'"
		
		// name for label of variable
		local a_off =  subinstr("`var'", "Activity_", "",.)
		
		di "`a_off'"
		
		//generate variable
		 gen `newvar' = Spend_RHC_3Ys_ERPspec * `var'
		label var `newvar' "the total spending in years 0-2 that is on RHC and specific to the ERP, on `a_off'"
		
		local seq = `seq' + 1
	
	}



	
					*-DETAILS OF ERP SPECIFIC GEOGRAPHICAL LEVEL
*------------------------------------------------------------------------------

*Total spend over years 0-2 on RHC and ERP specific activities, at the national level
	gen Spend_RHC_3Ys_ERPspec_Nat = Spend_RHC_3Ys_ERPspec * Spendprop_Nat_all / Spendprop_RHC_all
	label var Spend_RHC_3Ys_ERPspec_Nat "Total spend over years 0-2 on RHC and ERP specific activities, at the national level"

*Total spend over years 0-2 on RHC and ERP specific activities, at the district level
	gen Spend_RHC_3Ys_ERPspec_Dist = Spend_RHC_3Ys_ERPspec * Spendprop_Distlevel_all /Spendprop_RHC_all
	label var Spend_RHC_3Ys_ERPspec_Dist "Total spend over years 0-2 on RHC and ERP specific activities, at the district level"


	
	
*-----------------BY DISTRICT-------------------------------------------------

*Spend_RHC_3Ys_ERPspec *Districts_RHC/districts_number
	
		
	
	#delimit ;
local distritos
   "Yumbe
   Obongi
   Madi
   Lamwo 
	Kyegegwa 
	Koboko 
	Kiryandongo 
	Kikuube
	Kamwenge
	Kampala 
	Isingiro 
	Arua 
	Adjumani"
     ;
#delimit cr
	
	
	
	
	
	foreach v of local distritos {
		
		di "`v'"
		local newvar =  "Spnd_RHC_3Ys_ERPspec_" + `"`v'"'
		*di "`newvar'"
		gen `newvar' = 0
		
		replace `newvar' = Spend_RHC_3Ys_ERPspec_Dist * Districts_RHC if strpos(districts_which, "`v'")
		
		label var `newvar' "total spend in `v' over years 0-2 on RHC and ERP specific activities"	 
		
		
	
	}
	
 

* 			FORMAT VARIABLES
*-------------------------------------------------------------------------------
	rename date_until date_up_todate
	
	format Spendprop* %3.2f
	format Spend_RHC_* %22.1f
	format *_prop %3.2f
	
*Variables created : ----------------------------------------------------------
	
	
	#delimit ;
local keep_vars
   ID Project pr_budget pr_budget_currency pr_total_spent pr_spending_currency ///
	budget_USD spent_USD execution_rate date_start date_up_todate date_end Months monthly_spend_all ///
	active_* spent_* spent_3ys_all ///
	Districts_RHC districts_number perc_subcounties Prop_district_school_level Spendprop_Distlevel_all ///
	Spendprop_Nat_all Spendprop_RHC_all Spend_RHC_3Ys_all A_erp Spend_RHC_3Ys_ERPspec ///
	erp_relevant_prop Spend_RHC_3Ys_ERPrel Outcome_* sum_outcomes_* Spend_RHC_3Ys_ERPspec_* Spnd_RHC_3Ys_ERPspec_* ///
	Programme_* sum_programme Activity_* sum_activity Spend_RHC_3Ys_ERPspec_* ///
	donor_*
     ;
#delimit cr
	
	
	
	keep `keep_vars'
	order `keep_vars'
	
	
	
*-------------------------------------------------------------------------------

	
*** EXPORT DATA
*-------------------------------------------------------------------------------
	export excel using "$dir_clean\ERP_projects.xlsx", firstrow(variables) replace
	

*** EXPORT DATA FOR DASHBOARD
*------------------------------------------------------------------------------
	
	*drop non-key variables for analysis
	drop pr_total_spent pr_budget donor_category* *currency
	
	
	* identify values that are unique at the project level
	
	#delimit ;
local single_values
   budget_USD execution_rate  date_start date_end Month monthly_spend_all ///
	 active_* Districts_RHC districts_number perc_subcounties Prop_district_school_level ///
	 A_erp Spendprop_Distlevel_all Spendprop_Nat_all Spendprop_RHC_all Outcome_* Programme_* ///
	 Activity_* donor_* date_up_todate erp_relevant_prop sum_*
     ;
#delimit cr
	
	 
	 
	 * Export table of Projects to be used in the dashboard
	 preserve	 
	 
	 keep ID Project `single_values'
	 
	 export excel using "$dir_dashboard\Projects.xlsx", firstrow(variables) replace sheet("Projects")
	 
	 
	 restore
	 
	 
	 
	 drop `single_values' Project
	
	
	
	
** RESHAPE DATA FOR EFFECTIVE VISUALIZATION
*-------------------------------------------------------------------------------
	
	*rename long variables of spending in specific district
	*(THIS IS BECAUSE THE NAME OF THE DISTRICT SPECIFIC SPENDING WAS TO LONG)
	
	
	ds Spnd_RHC_3Ys_ERPspec_*
	
	foreach var in `r(varlist)' {
	
	local new_name =  subinstr("`var'", "RHC_3Ys_ERPspec_", "", . )
	rename `var' `new_name'	
	
	}
	
	

	*Reshape from wide to long by ID
	
	reshape long spent_ Spend_RHC_ Spnd_, i(ID) j(prefix) string
	order ID spent_ Spend_RHC_  Spnd_ prefix 
	
	
	** AREA OF SPENDING (ALL, SPECIFIC, RELATED)
	gen area = ""
	replace area = "All areas" if strpos(prefix, "all") | strpos(prefix, "USD")
	replace area = "ERP specific" if strpos(prefix, "ERPspec")
	replace area = "ERP related" if strpos(prefix, "ERPrel")
	
	foreach d in `distritos' {
	
		replace area = "ERP specific" if prefix  == "`d'"
	
	}
	
	
	
	**FINANCIAL YEAR (2017, 2018, 2019, 3FYS, TOTAL)
	gen financial_year = ""
	
	replace financial_year = "2017" if strpos(prefix,"0_all")
	replace financial_year = "2018" if strpos(prefix, "1_all")
	replace financial_year = "2019" if strpos(prefix,"2_all")
	replace financial_year = "3 FYs" if strpos(prefix,"3ys_all") | strpos(prefix,"3Ys")
	replace financial_year = "Total" if strpos(prefix,"USD") // TOTAL SPENDING INDEPENDENTLY OF THE FINANCIAL YEARS
	
	
	foreach d in `distritos' {
	
		replace financial_year = "3 FYs" if prefix  == "`d'"
	
	}
	
	
	**LEVEL OF SPENDING (Programme, Outcome,  Activity, District_level)
	
	gen level = ""
	replace level = "Programme" if inlist(prefix, "3Ys_ERPrel", "3Ys_ERPspec", "USD") 
	
	
	foreach d in `distritos' {
	
		replace level = "District level" if prefix  == "`d'"
	
	}
	
	
	* Identify programme level activities and categorize them as such
	#delimit ;
local prefix_programe
   "all
   Dist
   Nat
   ECD
   Accele
   Primar
   second
   Skills
   System
   other"
     ;
#delimit cr

	
	foreach pre in `prefix_programe' {
		
		local catch = "_" + "`pre'"
		replace level = "Programme" if strpos(prefix, "`catch'")
		
		
	
	}
	
	
	
	*Identify spending at the outcome level
	replace level = "Outcome" if strpos(prefix, "01") | strpos(prefix, "02") | strpos(prefix, "03") |strpos(prefix, "04")
	
	
	
	
	*identify activities (prefix activities is define above)
	foreach pre in `prefix_activities' {
		
		local catch = "_" + "`pre'"
		replace level = "Activity" if strpos(prefix, "`catch'")
		
		
	
	}
	
	

	*DIMENSIONS (THE EXACT DIMENSION IN WHICH THE SPENDING WAS ALLOCATED TO)

	
	*Identify text to correctly label the dimensions
#delimit ;
local look_for
   "01
   02
   03
   04
   ECD
   Primar
   second
   Accele
   Skills
   System
   other
   Dist
   Nat
   _IN
   _MA
   _TS
   _TT
   _CH
   _CO
   _DS
   _NS
   _PI
   _AO
   "
     ;
#delimit cr


 * define the dimensions
#delimit ;
local return_this
   "Outcome_1
   Outcome_2
   Outcome_3
   Outcome_4
   ECD
   Primary
   Secondary
   Accelerated_education
   Skills_and_vocational_training
   System_strengthening
   Other   
   District_ALL
   National
   Infrastructure
   Materials
   Teacher_Salary
   Teacher_training
   Training_to_the_children
   Strengthening_communities
   System_strengthening_(District) 
   System_strengthening_(National) 
   Piloting/innovations
   Other   
   "
     ;
#delimit cr


	
	
	*create dimensions
	gen dimension = ""
	
	
	local seq = 1 
	foreach lk in `look_for' {
	
		replace dimension = word("`return_this'", `seq') if strpos(prefix, word("`look_for'", `seq'))
		
		local seq = `seq' + 1
	
	}
	
	
		foreach d in `distritos' {
	
		replace dimension = prefix if prefix  == "`d'"
	
	}
	
	
	*get rid of the under score for dimension
	replace dimension = subinstr(dimension, "_"," ", .)
	
	
	
	order ID Spend_RHC_ spent_ Spnd_ prefix area financial_year level dimension
	
	
	
	*name spend
	replace Spend_RHC_ = spent_ if Spend_RHC == .
	replace Spend_RHC_ = Spnd_ if Spend_RHC == .
	rename Spend_RHC Spend
	drop spent_ Spnd_ 
	
	
	
	
	*export excel using "$dir_dashboard\spending.xlsx", firstrow(variables) replace sheet("Spending")
	
	
	
	
	

