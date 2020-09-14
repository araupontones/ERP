## Download from zoho

source("R/set_up.R")



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


## Export csvs to downloads folder
export = map2(my_datas,names(my_datas), function(x,y){
  
  exfile = paste0(y,".xls")
  write.xlsx(x, file.path(dir_downloads, exfile))
})





