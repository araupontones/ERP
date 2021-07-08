

**Define paths 
*-------------------------------------------------------------------------------
	
	*Main directory of the project (this may change by analyst)
	if c(username) == "andre" {
		global dir_project = "C:/repositaries/1.work/ERP"
	}
	
	if c(username) == "Nicola" {
		global dir_project = "C:\Users\nicola\Dropbox\ERP FinTrack Analysis"
	}

	
	*Run the paths and globals of the project
	do "$dir_project/analysis/set_up.do"
	
	
	import excel "$dir_downloads/Project_spending.xls", sheet("Sheet1") firstrow clear
	tempfile projects
	save `projects', replace
	
	

** Read reference data of donors and implementors
*---------------------------------------------------------------------------------------------
	import excel "$dir_reference/list_donors_categories.xlsx", sheet("Sheet 1") firstrow clear
	
	
	keep Donor Category
	rename Category donor_category
	
	*save file to merge it with the roster of donors
	tempfile ref_donors
	save `ref_donors', replace
	
	import excel "$dir_downloads/Roster_donors2.xls", sheet("Sheet1") firstrow clear
	replace Donor = strtrim(Donor)
	
	*merge with reference data of donors
	merge  m:1 Donor using `ref_donors' , assert(3) nogen
	
	

	keep ID Donor donor_*
	bys ID: gen seq = _n
	order ID seq
	
	
	** reshape to have only one row by project (so we can merge with the project's data)
	reshape wide Donor donor_*, i(ID) j(seq)
	
	
	ds donor_category*
	
	
	*Describe which type of funding the project is receivingS
	gen Category = ""
	
	gen combination = 0
	local seq = 2
	foreach var in `r(varlist)' {
		
		
	
		di "`var'"
		replace Category = Category + `var' if Category == ""
		replace Category = Category + ", " + `var' if `var' !="" & Category !="" & !strpos(Category, `var')
		
		*Check combination (if more than one donor type
		
		cap replace combination = combination + 1 if regexm(Category, donor_category`seq') == 0 & `var' != "" 
		
		
	
	local seq = `seq'+1
		
	}
	

	
	**Keep only donor_category and create summary
	keep ID donor_category*  combination
	gen donor_summary = donor_category1
	replace donor_summary = "Combination" if combination > 0 // combination if there's a mix of funding
	drop combination

	
	
	tempfile clean_donors
	save `clean_donors', replace
	

* Load and clean reference data from implementors -----------------------------

	import excel "$dir_reference/list_implementors_categories.xlsx", sheet("Sheet 1") firstrow clear
	keep Implementor Category
	rename Category implementor_category
	
	*save file to merge it with the roster of donors
	tempfile ref_implementors
	save `ref_implementors', replace
	
	import excel "$dir_downloads/Roster_implementors1.xls", sheet("Sheet1") firstrow clear
	
	*use organisation as implementor if implementor is missing
	merge m:1 ID using `projects', keepusing(ID Organisation) assert(3 2)
	replace Implementor = Organisation if _merge == 2
	
	drop if Implementor == ""
	replace Implementor = strtrim(Implementor)
	
	keep Implementor ID 
	
	*merge with reference data of implementors
	merge  m:1 Implementor using `ref_implementors' , assert(2 3) keep(3)
	
	
	
	keep ID Implementor implementor_*
	bys ID: gen seq = _n
	order ID seq
	
	
	** reshape to have only one row by project (so we can merge with the project's data)
	reshape wide Implementor implementor_*, i(ID) j(seq)
		
	ds implementor_category*
	
	*Describe which type of funding the project is receivingS
	gen Category = ""
	gen combination = 0
	local seq = 2
	foreach var in `r(varlist)' {
	

		di "`var'"
		replace Category = Category + `var' if Category == ""
		replace Category = Category + ", " + `var' if `var' !="" & Category !="" & !strpos(Category, `var')
		
		*Check combination (if more than one donor type
		
		cap replace combination = combination + 1 if regexm(Category, implementor_category`seq') == 0 & `var' != "" 
		
		local seq = `seq' + 1
	}
	
	
	**Keep only donor_category and create summary
	
	keep ID implementor_category* Category combination
	
	
	gen implementor_summary = implementor_category1
	replace implementor_summary = "Combination" if combination > 0
	drop combination
	
	*br implementor_summary *_category*
	
	tempfile clean_implementors
	save `clean_implementors', replace
	
	
	
	
**Lookup values for analysis
*------------------------------------------------------------------------------
	
	*Exchange rates into USD: average for the years we are looking at
	*https://www.fiscal.treasury.gov/reports-statements/treasury-reporting-rates-exchange/historical.html June 2019 
	local ex_gbp = 0.788
	local ex_euro = 0.879
	local ex_ugx = 3690
	
	

**Read data
*-------------------------------------------------------------------------------
	
	
	*Main form
	
	import excel "$dir_downloads/Project_spending.xls", sheet("Sheet1") firstrow clear
	
	*Keep only approved reports
	keep if for_analysis != "No"
	
	
	
	
	*merge with data from donors (We are keeping 1 to 3 to drop non-approved reports)
	merge 1:m ID using `clean_donors', keep(1 3) nogen
	
	*merge with data from implementors
	merge 1:m ID using `clean_implementors', keep(1 3) nogen
	

	
	
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
	
		
		replace districts_which = subinstr(districts_which, "Arua (aside from Madi Okollo)", "Arua",.)
		replace districts_which = subinstr(districts_which, "Kikuube (formerly part of Hoima)", "Kikuube",.)
		replace districts_which = subinstr(districts_which, "Madi Okollo (formerly part of Arua)", "Madi Okollo",.)
		replace districts_which = subinstr(districts_which, "Obongi (formerly part of Moyo)", "Obongi",.)
				
		
	
	#delimit ;
local distritos
   "Adjumani
   Arua
   Isingiro
   Kampala
   Kamwenge
   Kikuube
   Kiryandongo
   Koboko
   Kyegegwa
   Lamwo
   Madi
   Obongi
   Yumbe"
     ;
#delimit cr
	

	
	
	
	
	foreach v of local distritos {
		
		di "`v'"
		local newvar =  "Spnd_RHC_3Ys_ERPspec_" + `"`v'"'
		*di "`newvar'"
		gen `newvar' = 0
		
		replace `newvar' = Spend_RHC_3Ys_ERPspec_Dist / Districts_RHC if strpos(districts_which, "`v'")
		
		label var `newvar' "total spend in `v' over years 0-2 on RHC and ERP specific activities"		
		
	
	}
	


**ERP specific spending by year
	format A_erp %3.2f
	

	
	gen Spend_RHC_Y0_ERPspec = spent_0_all *  Spendprop_RHC_all * A_erp
	gen Spend_RHC_Y1_ERPspec = spent_1_all *  Spendprop_RHC_all * A_erp
	gen Spend_RHC_Y2_ERPspec = spent_2_all *  Spendprop_RHC_all * A_erp
	
	*gen AQ_RHC_FY = (Spend_RHC_Y0_ERPspec + Spend_RHC_Y1_ERPspec + Spend_RHC_Y2_ERPspec) - Spend_RHC_3Ys_ERPspec
	
	egen QA_RHC_FY = rowtotal(Spend_RHC_Y*) 
	replace QA_RHC_FY = round(QA_RHC_FY - Spend_RHC_3Ys_ERPspec, 2)
	

	
	

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
	erp_relevant_prop Spend_RHC_3Ys_ERPrel Outcome_* sum_outcomes_* Spend_RHC_3Ys_ERPspec_* Spend_RHC_Y*_ERPspec ///
	Spnd_RHC_3Ys_ERPspec_* ///
	Programme_* sum_programme Activity_* sum_activity Spend_RHC_3Ys_ERPspec_* ///
	donor_* implementor_* Organisation
     ;
#delimit cr
	
	
	
	keep `keep_vars'
	order `keep_vars'
	
	
	

	gen link =	 "https://app.zohocreator.eu/erp.forms20/erp/#Form:Projects?recLinkID=" + ID +"&viewLinkName=Project_spending"
*-------------------------------------------------------------------------------

	
*** EXPORT DATA
*-------------------------------------------------------------------------------
	export excel using "$dir_clean\ERP_projects.xlsx", firstrow(variables) replace
