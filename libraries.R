#Install Java Development Kit 21
install.packages("rJavaEnv")
rJavaEnv::rje_consent(provided=TRUE)
rJavaEnv::java_quick_install(version=21)
rJavaEnv::java_check_version_rjava()

#Store Census API Key
#census_api_key("YOURAPIKEY", install=TRUE)

#Increase the amount of memory available to r5r
options(java.parameters = '-Xmx8G') #default is 512MB, increase to 8GB

#Install and load packages
install.packages(c("here","r5r","tidytransit"))
library(data.table)
library(dplyr)
library(here)
library(rJava)
library(r5r)
library(sf)
library(tidycensus)
library(tidyverse)
library(tidytransit)
