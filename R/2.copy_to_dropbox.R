#Copy relevant pieces of project to dropbox folder

source("R/set_up.R")

#directories to copy into the dropbox folder of the programme
dirs_to_copy = c("analysis", "downloads", "clean_data")


#copy files 
copy_files = map(dirs_to_copy, function(x){
  
  file.copy(x, dir_db_analysis, recursive=TRUE, overwrite = T)
  
})



