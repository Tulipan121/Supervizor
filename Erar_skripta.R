library(dplyr)
library(sharepointr)
library(data.table)
library(stringr)

setwd("D:/R/GitHub/Supervizor")

"%!in%" <- Negate("%in%")

sp_con = sharepointr::sp_connection("https://ztslo.sharepoint.com",
                                    "blaz.zupancic@taborniki.si", "Caf46557", Office365 = T)

davcne_rodov <- sp_list(con = sp_con, listName = "Rodovi") %>%
  sp_collect(table = ., n = 200) %>% data.table()



# Check the 'origin' field in the response to verify TOR is working.
library(httr)
GET("https://httpbin.org/get", use_proxy("socks5://localhost:9150"))

# Set proxy in curl
library(curl)
h <- new_handle(proxy = "socks5://localhost:9150")
req <- curl_fetch_memory("https://httpbin.org/get", handle = h)
cat(rawToChar(req$content))

# Set proxy globally (case sensitive!)
Sys.setenv(http_proxy = "socks5://localhost:9050")
Sys.setenv(HTTPS_PROXY = "socks5://localhost:9050")

library(jsonlite)
 

# 
# davcne_rodov <- read.csv2("Davcne_stevilke.csv", header = T, stringsAsFactors=FALSE)


vse_transakcije <- data.frame(matrix(ncol = 12, nrow = 0))

n <- 0

for (j in davcne_rodov$`Davčna št.`) {
  
  placniki <- fromJSON(url(paste("http://erar.si/api/placniki/?prejemnik=",j, sep="")))
  
  #Sys.sleep(2)
  
  for (i in c(1:length(placniki$data$sifra_pu))) {
    
    #Sys.sleep(2)
    
    transakcije <- fromJSON(a <- url(paste("http://erar.si/api/transakcije/?placnik=", placniki$data$sifra_pu[i], "&prejemnik=", j, sep="")))  
    
    closeAllConnections()
    
    if(length(transakcije$data$datum) != 0) {
      transakcije$data["sifra_pu"] <- c(rep.int(placniki$data$sifra_pu[i], length(transakcije$data$datum)))
      transakcije$data["naziv_placnika"] <- c(rep.int(placniki$data$naziv[i], length(transakcije$data$datum)))
      transakcije$data["rod_davcna"] <- c(rep.int(j, length(transakcije$data$datum)))
      #transakcije$data <- transakcije$data[-"mferac"]
      colnames(vse_transakcije)[1:12] <- colnames(transakcije$data)
      vse_transakcije <<- rbind(vse_transakcije, transakcije$data)

    }
  }
  print(str_c(n , "/", nrow(davcne_rodov), sep = ""))
  n <- n + 1
}

closeAllConnections()

vse_transakcije$znesek <- as.numeric(vse_transakcije$znesek)
vse_transakcije$mferac <- NULL

write.csv2(vse_transakcije, "./Supervizor_rodovi_2.csv", row.names = FALSE)
