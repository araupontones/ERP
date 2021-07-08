#Copy relevant pieces of project to dropbox folder

source("R/set_up.R")

#directories to copy into the dropbox folder of the programme
#"clean_data", "reference_data", "dashboard" "analysis",
dirs_to_copy = c( "downloads")


#copy files 
copy_files = map(dirs_to_copy, function(x){
  
  from_dir = paste0(x,"/.")
  to_dir = file.path(dir_db_analysis, x)
  
  #folder to share with externals
  to_dir_external = file.path(dir_db_external, x)
  
  #file.copy(from_dir, to_dir, recursive=TRUE, overwrite = T)
  file.copy(from_dir, to_dir_external, recursive=TRUE, overwrite = T)
  
})




