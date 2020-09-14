## Create list of donors and list of implementors

#First run donwloads.R

# run set up
source("R/set_up.R")


##create list of donors and export to clean folder


fn_export_list = function(db, variable, exfile,...){
  
      data = unique(db[[variable]]) %>%
      as.data.frame()
  
      names(data) = c(variable)
    
      write.xlsx(data, file.path(dir_clean, exfile))
  
}




fn_export_list(my_datas$Roster_implementors1, "Implementor", "list_implementors.xlsx")
fn_export_list(my_datas$Roster_donors2, "Donor", "list_donors.xlsx")
