

**Define paths 
*-------------------------------------------------------------------------------
	
	*Main directory of the project (this may change by analyst)
	
	if c(username) == "andre" {
		global dir_project = "C:/repositaries/1.work/ERP"
	}


	
	*Directory where data from zoho is downloaded to:
	global dir_downloads = "$dir_project/downloads"
	
	
	
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
	
	
*Execution rate
	gen execution_rate = round(spent_USD / budget_USD,.01)
	
	
*Months: total moths of project spending
	gen date_start = date(pr_date_start, "DMY")
	gen date_until = date(pr_date_endbudget, "DMY")
	gen date_end = date(pr_date_dueend, "DMY")
	
	format date_start date_until date_end %td
	
	gen Months = round((date_until - date_start)/(365/12),.01)
	drop pr_date_start pr_date_endbudget
	
	
*Amount spent monthly
	gen monthly_spend_all  = spent_USD / Months
	
	
*Amount spent year 0

	local start_FY_0 = date("1-Jan-2018", "DMY")
	local end_FY_0 = date("30-Jun-2018", "DMY")
	
	
	gen active_0 = .	
	//count months between project start and 31st June 2019
	replace active_0 =  round((`end_FY_0' - date_start)/(365/12),.1) if date_end >= `start_FY_0' & date_start <= `end_FY_0' 
	
	//adjust for those projects that ended before the end of FY
	replace active_0 = round((date_end - `start_FY_0')/(365/12),.1) if date_end  <=  `end_FY_0' & active_0 !=. 
	
	//adjust for those projects that ended after end of FY
	replace active_0 = 12 if active_0 >12 & active_0!=.
	
	
	gen spent_0_all = .
	replace spent_0_all = monthly_spend_all * active_0
	

*Amount spent in financial year 2017 - 2018
	//Set start and end date of financial year
	
	local start_FY_1718 = date("1-Jul-2017", "DMY")
	local end_FY_1718 = date("30-Jun-2018", "DMY")
	
	
	gen active_1718 = .	
	//count months between project start and 31st June 2019
	replace active_1718 =  round((`end_FY_1718' - date_start)/(365/12),.1) if date_end >= `start_FY_1718' & date_start <= `end_FY_1718' 
	
	//adjust for those projects that ended before the end of FY
	replace active_1718 = round((date_end - `start_FY_1718')/(365/12),.1) if date_end  <=  `end_FY_1718' & active_1718 !=. 
	
	//adjust for those projects that ended after end of FY
	replace active_1718 = 12 if active_1718 >12 & active_1718!=.
	
	
	gen spent_1718_all = .
	replace spent_1718_all = monthly_spend_all * active_1718
	
	
	*Amount spent in financial year 2018-2019
	
	//Set start and end date of financial year
	local start_FY_1819 = date("1-Jul-2018", "DMY")
	local end_FY_1819 = date("30-Jun-2019", "DMY")
	
	gen active_1819 = .	
	//count months between project start and 31st June 2019
	replace active_1819 =  round((`end_FY_1819' - date_start)/(365/12),.1) if date_end >= `start_FY_1819' & date_start <= `end_FY_1819' 
	
	//adjust for those projects that ended before the end of FY
	replace active_1819 = round((date_end - `start_FY_1819')/(365/12),.1) if date_end  <=  `end_FY_1819' & active_1819 !=. 
	
	//adjust for those projects that ended after end of FY
	replace active_1819 = 12 if active_1819 >12 & active_1819!=.
	
	
	
	gen spent_1819_all = .
	replace spent_1819_all = monthly_spend_all * active_1819
	
	
	order Project pr_budget pr_budget_currency pr_total_spent pr_spending_currency ///
	budget_USD spent_USD execution_rate date_start date_until date_end Months monthly_spend_all ///
	active_0 spent_0_all active_1718 spent_1718_all active_1819 spent_1819_all
	
	
	
	br
	ex

