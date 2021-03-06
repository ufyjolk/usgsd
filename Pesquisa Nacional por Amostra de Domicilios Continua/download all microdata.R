# analyze survey data for free (http://asdfree.com) with the r language
# pesquisa nacional por amostra de domicilios continua

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# options( encoding = "windows-1252" )		# # only macintosh and *nix users need this line
# library(downloader)
# setwd( "C:/My Directory/PNADC/" )
# source_url( "https://raw.github.com/ajdamico/usgsd/master/Pesquisa%20Nacional%20por%20Amostra%20de%20Domicilios%20Continua/download%20all%20microdata.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# if you have never used the r language before,
# watch this two minute video i made outlining
# how to run this script from start to finish
# http://www.screenr.com/Zpd8

# djalma pessoa
# djalma.pessoa@ibge.gov.br

# anthony joseph damico
# ajdamico@gmail.com

# if you use this script for a project, please send me a note
# it's always nice to hear about how people are using this stuff

# for further reading on cross-package comparisons, see:
# http://journal.r-project.org/archive/2009-2/RJournal_2009-2_Damico.pdf


###########################################################################
# analyze the pesquisa nacional por amostra de domicilios continua with R #
###########################################################################


# set your working directory.
# the PNADC data files will be stored here
# after downloading and importing them.
# use forward slashes instead of back slashes

# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/PNADC/" )
# ..in order to set your current working directory


# # # are you on a non-windows system? # # #
if ( .Platform$OS.type != 'windows' ) print( 'non-windows users: read this block' )
# ibge's ftp site has a few SAS importation
# scripts in a non-standard format
# if so, before running this whole download program,
# you might need to run this line..
# options( encoding="windows-1252" )
# ..to turn on windows-style encoding.
# # # end of non-windows system edits.


# remove the # in order to run this install.packages line only once
# install.packages( c( "SAScii" , "downloader" , "RCurl" ) )


############################################
# no need to edit anything below this line #

# # # # # # # # #
# program start #
# # # # # # # # #


library(SAScii) 	# load the SAScii package (imports ascii data with a SAS script)
library(downloader)	# downloads and then runs the source() function on scripts from github
library(RCurl)		# load RCurl package (downloads https files)


# load the download.cache and related functions
# to prevent re-downloading of files once they've been downloaded.
source_url( 
	"https://raw.github.com/ajdamico/usgsd/master/Download%20Cache/download%20cache.R" , 
	prompt = FALSE , 
	echo = FALSE 
)


# create a temporary file and a temporary directory..
tf <- tempfile() ; td <- tempdir()

# initiate the full ftp path
full.ftp <- "ftp://ftp.ibge.gov.br/Trabalho_e_Rendimento/Pesquisa_Nacional_por_Amostra_de_Domicilios_continua/Microdados/"

# read the text of the microdata ftp into working memory
# download the contents of the ftp directory for all microdata
ftp.listing <- readLines( textConnection( getURL( full.ftp ) ) )

# break up the string based on the ending extension
zip.lines <- grep( "\\.zip$" , ftp.listing , value = TRUE )

# extract the precise filename of the `.zip` file
zip.filenames <- gsub( '(.*) (.*)' , "\\2" , zip.lines )

# identify the `input` zipped file
input.filename <- grep( "input" , zip.filenames , value = TRUE )

# append the full ftp path to the front
input.fullname <- paste0( full.ftp , input.filename )

# remove the input file from the vector of zipped files to download
zip.filenames <- zip.filenames[ !grepl( "input" , zip.filenames ) ]

# download the input file immediately
download.cache( input.fullname , tf , mode = 'wb' )

# unzip its contents on the local disk
z <- unzip( tf , exdir = td )

# identify and store the sas file
sasfile <- grep( "\\.sas$" , z , value = TRUE )

# loop through the `zip.filenames` character vector..
for ( i in seq_along( zip.filenames ) ){

	# construct the full ftp path to the current zipped file
	current.zipfile <-
		paste0(
			full.ftp ,
			zip.filenames[ i ]
		)	
	

	# try to download the zipped file..
	attempt.one <- try( download.cache( current.zipfile , tf , mode = 'wb' ) , silent = TRUE )
	
	# ..but if the first attempt fails,
	# wait for three minutes and try again.
	if ( class( attempt.one ) == 'try-error' ){

		Sys.sleep( 180 )
		
		download.cache( current.zipfile , tf , mode = 'wb' )
		
	}
		
	# unzip all text files to the temporary directory..
	cur.textfiles <- unzip( tf , exdir = td )

	for ( txt in grep( "\\.txt$" , cur.textfiles , value = TRUE ) ){

		quarter <- gsub( "(.*)PNADC_([0-9][0-9])([0-9][0-9][0-9][0-9])\\.txt" , "\\2" , txt )
		year <- gsub( "(.*)PNADC_([0-9][0-9])([0-9][0-9][0-9][0-9])\\.txt" , "\\3" , txt )
	
		# construct the full `.rda` path to the save-location on your local disk
		current.savefile <-	paste0( 'pnadc ' , year , ' ' , quarter , '.rda' )
			
		# ..and read that text file directly into an R data.frame
		# using the sas importation script downloaded before this big fat loop
		x <- read.SAScii( txt , sasfile )

		# convert all column names to lowercase
		names( x ) <- tolower( names( x ) )
		
		# save the data.frame object to the local disk
		save( x , file = current.savefile )
		
		# clear the `x` data.frame object from working memory
		rm( x )
		
		# clear up RAM
		gc()
	
	}
	
	# remove the temporary file
	file.remove( tf )

}

# remove the contents of the temporary directory
unlink( td , recursive = TRUE )
# from your local disk

# print a reminder: set the directory you just saved everything to as read-only!
message( paste0( "all done.  you should set the file " , getwd() , " read-only so you don't accidentally alter these tables." ) )


# for more details on how to work with data in r
# check out my two minute tutorial video site
# http://www.twotorials.com/

# dear everyone: please contribute your script.
# have you written syntax that precisely matches an official publication?
message( "if others might benefit, send your code to ajdamico@gmail.com" )
# http://asdfree.com needs more user contributions

# let's play the which one of these things doesn't belong game:
# "only you can prevent forest fires" -smokey bear
# "take a bite out of crime" -mcgruff the crime pooch
# "plz gimme your statistical programming" -anthony damico
