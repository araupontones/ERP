**Define paths of the project
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
	
	
	
	*globals for analysis
	
	#delimit ;
global distritos
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



* Global to look for programme level dimensions
#delimit ;
global programme_dictionary
  `" "Dist District_ALL Programme"
  "Nat National Programme"
	"ECD ECD Programme"
	"Accele Acceleration Programme"
	"Primar Primary Programme"
   "second Secondary Programme"
   "Skills Skills_and_vocational_training Programme"
   "System System_strengthening Programme"
   "other Other Programme"
	
	"'
     ;
#delimit cr


*global to look for outcome level dimensions
#delimit ;
global outcome_dictionary
`" "01 Access Outcome"
"02 Quality Outcome"
"03 System_Strengthening  Outcome"
"04 Outcome_4 Outcome"

"'
;
#delimit cr



   
   
   
   
   
   
   
   
   

*global to look for activity level dimensions   
 #delimit ;
 global activity_dictionary
 `" "IN Infrastructure Activity"
 "MA Materials Activity" 
 "TS Teacher_Salary Activity"
 "TT Teacher_training Activity"
 "CH Training_to_the_children Activity"
 "CO Strengthening_communities Activity"
 "DS System_strengthening_(District) Activity"
 "NS System_strengthening_(National) Activity"
 "PI Piloting/innovations Activity"
 "AO Other Activity"
 
 "'
 ;
 #delim cr
 
 #delimit ;
 global activity_dictionary_projects
 	`" "_IN Infrastructure Activity"
   "_MA Materials Activity"
   "_TS Teacher_Salary Activity"
   "_TT Training_to_the_children Activity"
   "_CH Training_to_the_children Activity"
   "_CO Strengthening_communities Activity"
   "_DS System_strengthening_(District) Activity"
   "_NS System_strengthening_(National) Activity"
   "_PI Piloting/innovations Activity"
   "_AO Other Activity"
   
   "'
 ;
 #delimit cr
 
 
 foreach y in $programme_dictionary $outcome_dictionary $activity_dictionary_projects{
	di "`y'"
	
 } 

