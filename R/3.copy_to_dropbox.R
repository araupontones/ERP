#Copy relevant pieces of project to dropbox folder

source("R/set_up.R")

#directories to copy into the dropbox folder of the programme
dirs_to_copy = c("analysis", "downloads", "clean_data", "reference_data")


#copy files 
copy_files = map(dirs_to_copy, function(x){
  
  from_dir = paste0(x,"/.")
  to_dir = file.path(dir_db_analysis, x)
  
  file.copy(from_dir, to_dir, recursive=TRUE, overwrite = T)
  
})




