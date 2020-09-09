
library(tidyverse)
library(httr)
library(jsonlite)
library(stringr)
library(rprojroot)




#set parameters for query =====================================================================================================

base = "https://creator.zoho.eu/api/json/erp/view/"
user = "erp.forms20@gmail.com"
password = "ERPta2020"
token  = "65a7ca968a59099101894c48755e00d1"
scope = "creatorapi"

#reports to download
reports = c("Project_spending", "Roster_donors2",
            "roster_donors_second","Roster_implementors1",
            "Roster_implementors_second")




#Function to get the data ======================================================================================================
get_data = function(l) {
  
  link = paste0(base, l) # creates the link 
  r = GET(link, query = list(
    authtoken = token ,
    scope = scope ,
    zc_ownername = "erp.forms20"
    
    
  ))
  
  print(l)
  text = content(r,"text") #transform report to text
  
  text = content(r,"text")
  text2 = str_remove(text,"var zohoerp.forms20view[0-9]{1,} = ") #this line is blocking from parsing 
  text2 = str_remove(text2,";$") #this semicolon is also blocking from parsing
  
  
  jason = fromJSON(text2, flatten = T, bigint_as_char=TRUE) # parse to json
  p = as.data.frame(jason[1]) #Finally to a dataset 
  
  
  col_old = colnames(p) #clean names (all variables have a prefixx with the name of the table)
  col_new = str_remove_all(col_old,".+(?=\\.)\\.")
  colnames(p) = col_new
  
  
  return(p)
  
  
}





##download data ------------------------------------------------------------------------------------------------------------------------------

my_datas = purrr::map(reports, get_data)   #reports is created in the parameters section
names(my_datas) = reports #name each data in the list

projects = my_datas$Project_spending
donors = my_datas$Roster_donors2
donors_second = my_datas$roster_donors_second
implementors = my_datas$Roster_implementors1
implementors_second = my_datas$Roster_implementors_second



## Number of unanswered questions
projects$no_answered <- rowSums(projects == "")

##remove pr from dates
dates = which(str_detect(names(projects),"date"))
names(projects)[dates] <- str_remove(names(projects[dates]), "pr_")
names(projects)


## remove levels from national and district
levels = which(str_detect(names(projects),"level"))
names(projects)[levels] <- str_remove(names(projects)[levels], "_level")



report = projects %>%
  mutate(url = paste0("https://app.zohocreator.eu/erp.forms20/erp/#Form:Projects?recLinkID=",ID,"&viewLinkName=Project_spending"),
         link = paste0('<a href="',url,'" taget="_blank">Go to form</a>')) %>%
  mutate(across(matches("B_|C_|D_"), as.numeric)) %>%
  rowwise() %>%
  
  ## sum proportions to check they sum to 100
  mutate(sum_outcomes = sum(c_across(starts_with("B_")), na.rm = T),
         sum_programme = sum(c_across(starts_with("C_")), na.rm = T),
         sum_activities = sum(c_across(starts_with("D_")), na.rm = T),
  ## Get budget and currency
        budget = paste(prettyNum(pr_budget, big.mark = ","), pr_budget_currency ),
  ## clean subcounties
        subcounties_focus = str_remove(subcounties_focus, " is in*.+"),
  ## clean districts which
      
        districts_which = str_remove_all(districts_which, "\\[|\\]"),
  districts_which = if_else(districts_which == "", 0, str_count(districts_which,",")+1)
         
         ) %>%
  
  rename(A.Prop_ERP= A_erp,
         ERP_relevant = ERP_relevant_prop,
         subcounties = subcounties_focus)%>%
  
  
  select(Organisation,Project, starts_with("intro"),starts_with("date"), 
         budget,pr_budget_currency,pr_total_spent, pr_spending_currency,A.Prop_ERP,starts_with("sum_"), ERP_relevant, prop_national, prop_district,
         subcounties, districts_number,districts_which,
         no_answered, link, ID)


names(donors) <- c("Project", "donor_detail",  "Donor", "ID_Project", "donor_amount", "ID" ,"donor_currency")

## get list of donors
Donors = donors %>%
  select(ID_Project, Donor) %>%
  group_by(ID_Project) %>%
  mutate(rn = str_c("V", row_number())) %>%
  ungroup() %>%
  pivot_wider(names_from = rn,
              values_from = Donor) %>%
 unite(Donors,starts_with("V"), sep = ",") %>%
  mutate(Donors = str_replace_all(Donors,",NA", "")) 


report_donors = report %>%
  left_join(Donors, by=c("ID" = "ID_Project")) %>%
  select(Organisation,Project, Donors, starts_with("intro"),starts_with("date"), 
         budget,pr_budget_currency,pr_total_spent,pr_spending_currency,A.Prop_ERP,starts_with("sum_"), ERP_relevant, prop_national, prop_district,
         subcounties, districts_number,districts_which,
         no_answered, link, ID)


names(implementors) <- c("implementor_spent","Project" ,"Implementor","ID_Project",
                         "implementor_currency", "ID"  )

Implementors_ = implementors %>%
  select(ID_Project, Implementor) %>%
  group_by(ID_Project) %>%
  mutate(rn = str_c("V", row_number())) %>%
  ungroup() %>%
  pivot_wider(names_from = rn,
              values_from = Implementor) %>%
  unite(Implementors,starts_with("V"), sep = ",") %>%
  mutate(Implementors = str_replace_all(Implementors,",NA", "")) 


report_donors_implementors = report_donors %>%
  left_join(Implementors_, by=c("ID" = "ID_Project")) %>%
  select(Organisation,Project, Donors, Implementors,starts_with("intro"),starts_with("date"), 
         budget,pr_budget_currency,pr_total_spent,pr_spending_currency,A.Prop_ERP,starts_with("sum_"), ERP_relevant, prop_national, prop_district,
         subcounties, districts_number,districts_which,
         no_answered, link)




              
              
              


  
