## Create list of donors and list of implementors

#First run donwloads.R

# run set up
source("R/set_up.R")


##create list of donors and export to clean folder


#' list of projects
raw_projects = import(file.path(dir_downloads, "Project_spending.xls")) %>%
  select(ID, Organisation)

#'list of implementers
raw_implementers = import(file.path(dir_downloads,"Roster_implementors1.xls")) %>%
  select(ID...5, Implementor) %>%
  rename(ID = ID...5)


#' unique impementers
unique_implementor = right_join(raw_implementers, raw_projects) %>%
  mutate(Implementor = if_else(is.na(Implementor), Organisation, Implementor)) %>% 
  group_by(Implementor) %>% 
  slice(1) %>% 
  ungroup() %>% 
  select(Implementor)


#' list of implementers by category
reference_implementors = import(file.path(dir_reference, "list_implementors_categories.xlsx")) %>%
  right_join(check_implementor) %>%
  select(Implementor, Category)


#'export
export(reference_implementors,file.path(dir_reference, "list_implementors_categories.xlsx"), row.names = F) 



### List of donors

unique_donors = tibble(unique(my_datas$Roster_donors2$Donor))
names(unique_donors) <- "Donor"
  


reference_donors = import(file.path(dir_reference, "list_donors_categories.xlsx")) %>% 
  right_join(unique_donors) %>%
  select(-`...1`) %>%
  export(.,file.path(dir_reference, "list_donors_categories.xlsx"))



# fn_export_list = function(db, variable, exfile,...){
#   
#       data = unique(db[[variable]]) %>%
#       as.data.frame()
#   
#       names(data) = c(variable)
#     
#       write.xlsx(data, file.path(dir_clean, exfile))
#   
# }
# 
# 
# 
# 
# fn_export_list(my_datas$Roster_implementors1, "Implementor", "list_implementors.xlsx")
# fn_export_list(my_datas$Roser_tdonors2, "Donor", "list_donors.xlsx")
