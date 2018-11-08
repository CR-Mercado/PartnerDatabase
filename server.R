#'
#'
#' Searches for Capabilities in the Partner Database and outputs a table of recommended partners
#'
#' downloads the top 20 suggested partners after a search
#'
#' 

library(shiny)
library(rvest)
library(tm)

# Define server logic required to 
shinyServer(function(input, output) {
  # stop app when done 
 
  
  
   # Current Partner Database
   
   current.partners <- read.csv("PartnerDatabase.csv", stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
   
   #due to BOM encoding issues in Excel reading of csv files this is an error catch: spaces become .  X gets added randomly, and ï.. gets put in
   colnames(current.partners) <- gsub("ï..","",colnames(current.partners), fixed = TRUE)
   colnames(current.partners) <- gsub("X","",colnames(current.partners))
   colnames(current.partners) <- gsub(".","_",colnames(current.partners), fixed = TRUE)
   
   current.capabilities <- read.csv("Capabilities.csv", stringsAsFactors = FALSE, header = FALSE,fileEncoding = "UTF-8-BOM")
   
   print("getting started")
   # Adding a new partner 
   # input$new.partners is a dataframe of 4 columns:  name | size | type | datapath // read only the exact item in the datapath column
    
  addpartner <- observeEvent(input[["partner.add"]], handlerExpr = {
                              
            if(input$confirm == TRUE){
            print("getting started")  
              inFile <- input$new.partners
              for(i in inFile$datapath){
            the.newpartners <- read.csv(i, stringsAsFactors = FALSE, strip.white = TRUE,fileEncoding = "UTF-8-BOM")
            colnames(the.newpartners) <- gsub("ï..","",colnames(the.newpartners), fixed = TRUE)
              }
            print("loaded new partners")
          
            temp.df <- NULL  
            
             for(i in 1:nrow(the.newpartners)){
               # for each new partner 
               # get a dataframe of their capabilities and stick it the bottom of the current capabilities
               temp.df <- rbind.data.frame(temp.df, 
                                           PartnerCaps(partner.name = the.newpartners[i,"partner"],
                                                       website = the.newpartners[i,"website"],
                                                       caps.table = current.capabilities), stringsAsFactors = FALSE)
             }
            
            print("done searching all partner websites")
            
              current.partners <- rbind.data.frame(current.partners,temp.df, stringsAsFactors = FALSE)
              write.csv(current.partners, file = "PartnerDatabase.csv", row.names = FALSE)
            
              print("database updated")   
              
                              }
    else print("please checkmark") # demand checkbox 
    })
  
    
   # Creating the Top Partners Table
  partners.df <- eventReactive(input$partner.search, {
    the.partnersearch <-  read.csv("PartnerDatabase.csv", stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
    
    #due to BOM encoding issues in Excel reading of csv files this is an error catch: spaces become .  X gets added randomly, and ï.. gets put in
    colnames(the.partnersearch) <- gsub("ï..","",colnames(the.partnersearch), fixed = TRUE)
    colnames(the.partnersearch) <- gsub("X","",colnames(the.partnersearch))
    colnames(the.partnersearch) <- gsub(".","_",colnames(the.partnersearch), fixed = TRUE)
    
     # type in free text:  health, communication, marketing      --> read as  "health" "communication" "marketing"
     caps.to.search <- tolower(unlist(strsplit(input$capabilities.to.search,", ")))
     caps.to.search <- gsub(" ","_",caps.to.search)
     print("databaser read")
     temp.capabilites <- current.capabilities
     temp.capabilites <- gsub(" ","_", temp.capabilites[,1])
     # ignore requested capabilities that aren't actually in the database. lowercasing to be safe. 
     relevant.capabilities.to.search <- subset(temp.capabilites,
                                               temp.capabilites %in% caps.to.search)
    
      # select only the relevant columns 
     
     the.partnersearch <- the.partnersearch[,c("partner","website",relevant.capabilities.to.search)]
     print("database sorted") 
     # create sum column for sorting //don't sum the partner and website columns, since they're not numbers lol 
     the.partnersearch$sum <- apply(X = the.partnersearch[,-c(1:2)], 
                                    MARGIN = 1, # 1 = row, 2 = column
                                    FUN = sum)  # sum by margin (row) 
     # then sort by sum 
     the.partnersearch <- the.partnersearch[order(the.partnersearch$sum, decreasing = TRUE),]        
     print("partners ready")
     # output the sorted dataset. 
     the.partnersearch
     
     }
                 ) # this is the partners.df close of eventReactive
  
  # render the top 20 as a dataset
   output$top.partners <-  renderDataTable({
     d <- partners.df()
     colnames(d) <- gsub("_"," ",colnames(d))
     data.frame(d, check.names = FALSE)
     }) 
  
 
 # output the top partners data  - this is taken from my previous PFE app, the filename actually doesn't work as expected 
 # and will require a rename at download as well. Not sure why. 
 output$get.data <- downloadHandler(
   filename = function(){ 
     paste("toppartners",".csv",sep="")
     },
   content = function(file){ 
     write.csv(partners.df(), file, row.names = FALSE)
     }
   
   
 )

})


################################## Webscrape for adding partners 

PartnerCaps <- function(partner.name, website, caps.table){
  # this function checks a website
  # identifies all of the links on that website
  # then goes to each link and and concatenates everything from the link
  # it then searches for the capabilities and outputs a table of:  partner.name,0,0,1,0,1,0,1,1,1,0,....1  where 
  # the 0s and 1s are whether or not a specific cability is present on any of that partners links 
  # the caps.table is a table of all the capabilities to search for in a single column 
  # the output of this function can be rbind() to the table 
  
  if(grepl("http" ,website,fixed = TRUE) == FALSE){return("website requires http part")} #R needs http:// to search the web 
  site <- read_html(url(website))
  site.nodes <- html_nodes(x=site,"a") # "a" gets the links 
  sites.list <- html_attr(site.nodes, "href") # get a list of those links
  socialnet.index <- grep("facebook|linkedin|twitter|google|\\.pdf|\\.php|youtube|mailto|index\\.asp|^/|404|#|instagram", sites.list) 
  # don't go to social networking sites or items that cannot be opened.  
  #   the \\ allows for . to be read as a . normally . means any-character.  the ^/ means begins with / 
  #readLines doesnt work on these well and its super slow. 
  sites.list[socialnet.index] <- NA   # make any social networking sites NA 
  sites.list <- sites.list[!is.na(sites.list)] # remove all the NAs
  sites.list <- unique(sites.list)
  
  # go through the sites and bind up all of the text - this is NOT optimized and very large and ugly 
  temp.company = NULL
  for(j in sites.list){  
    print(j)
    # if theres an error with the site, skip it  also lowercase everything
    # errors are typically a link that goes to an image (such as a thumbnail) 
    # this error catching function does nothing, thus ignoring errors. 
    temp. = cleaner(tolower(tryCatch(expr = readLines(j),error=function(e){}))) 
    temp.company = c(temp.company,temp.)
  }
  
  # search for each capability and if TRUE exists at list once then give it a 1   VERY not optimized. 
  addition <- NULL
  for(i in caps.table[,1]){
    cap.exists <- unique(grepl(i,temp.company))
    if(length(cap.exists) == 2){
      addition <- c(addition, 1)
    }
    else addition <- c(addition, 0)
  }
  
  if(nrow(caps.table) != length(addition)){return("mismatch on number of capabilities and searches completed")}
  
  # return a data frame with partner as row, and columns = partner, website, addition 
  # desired column names
  return.colnames <- c("partner","website",as.character(caps.table[,1]))
  
  # combine into a dataframe with 1s and 0s as numbers, partner and website as characters
  return.df <- cbind.data.frame(partner.name, 
                                website,
                                # transpose the additions 
                                t(data.frame(addition)) , stringsAsFactors = FALSE)  
  
  colnames(return.df) <- return.colnames
  row.names(return.df)<- NULL # remove row names.
  return(return.df)
}



removestopwords <- function(inputtext, language = "en", lowercase =TRUE){
  
  stops <- stopwords(kind = language)
  if(lowercase == TRUE){inputtext = tolower(inputtext)}
  inputtext <- subset(inputtext, !(inputtext %in% stops))
  return(inputtext)
}

makeinternational <- function(inputtext){
  inputtext <- iconv(inputtext, to = "ASCII//TRANSLIT")
  return(inputtext)
}


cleaner <- function(t){
  t <- gsub("[[:punct:]]","",t)
  t <- removestopwords(t)
  t <- makeinternational(t)
  t <- gsub("\n", " ",t, fixed = TRUE)
  t <- unique(t)
  return(t)
}
