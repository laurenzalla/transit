#Compute Transit Times to Bartlett Practice using r5r
#https://cran.r-project.org/web/packages/r5r/vignettes/r5r.html

setwd("S:/JHU_HIVcohorts/Analyses_Zalla/Transit")
source("libraries.R")
here::i_am("transit_network.R")

#Download transit data (zip file paths from Mobility Data)

#MTA - Local Bus
path_bus <- paste0(here(),"/Data/mdotmta_gtfs_localbus.zip")
download.file(url="https://mdotmta-gtfs.s3.amazonaws.com/mdotmta_gtfs_localbus.zip", destfile=path_bus)
bus <- read_gtfs(path=path_bus)
summary(bus)
head(bus$routes)

#MTA - Light Rail
path_lightrail <- paste0(here(),"/Data/mdotmta_gtfs_lightrail.zip")
download.file(url="https://mdotmta-gtfs.s3.amazonaws.com/mdotmta_gtfs_lightrail.zip", destfile=path_lightrail)
lightrail <- read_gtfs(path=path_lightrail)
summary(lightrail)
head(lightrail$routes)

#MTA - Metro
path_metro <- paste0(here(), "/Data/mdotmta_gtfs_metro.zip")
download.file(url="https://mdotmta-gtfs.s3.amazonaws.com/mdotmta_gtfs_metro.zip", destfile=path_metro)
metro <- read_gtfs(path=path_metro)
summary(metro)
head(metro$routes)

#Charm City Circulator
path_circulator <- paste0(here(), "/Data/cccgtfs824.zip")
download.file(url="https://github.com/mobilityequity/maryland-local-gtfs/raw/master/CCC_GTFS.zip", destfile=path_circulator)
circulator <- read_gtfs(path=path_circulator)
summary(circulator)
head(circulator$routes)

#Harbor Connector
path_connector <- paste0(here(), "/Data/harborconnector-md-us.zip")
download.file(url="http://data.trilliumtransit.com/gtfs/harborconnector-md-us/harborconnector-md-us.zip", destfile=path_connector)
connector <- read_gtfs(path=path_connector)
summary(connector)
head(connector$routes)

#Towson Loop
path_towson <- paste0(here(), "/Data/google_transit.zip")
download.file(url="https://passio3.com/towson/passioTransit/gtfs/google_transit.zip", destfile=path_towson)
towson <- read_gtfs(path=path_towson)
summary(towson)
head(towson$routes)

#Load all road network and public transit data into R5R
path <- paste0(here(),"/Data")
r5r_core <- setup_r5(data_path = path, verbose = F, overwrite = F)

#Pull street and public transit networks
street_net <- street_network_to_sf(r5r_core)
transit_net <- transit_network_to_sf(r5r_core)

#Add indicator of paid vs. free fare
transit_net$routes <- transit_net$routes %>%
  mutate(fare = ifelse(agency_name=="Maryland Transit Administration","paid","free"))

#Download ACS data and geographies for census block groups in Baltimore City and Baltimore County
varlist <- c(pop = "B01003_001",
             median_income = "B19013_001")
#5-year ACS 2011-2015 (corresponding to 2010 block group boundaries and 2015 ADI)
bc <- get_acs(geography = "block group",
              variables = varlist,
              survey = "acs5",
              output = "wide",
              state = "Maryland",
              county = c("Baltimore city","Baltimore County"),
              geometry = TRUE,
              year = 2015)

#Origins: geometric centroid of each census block group
centroids <- bc %>%
  mutate(centroid = st_centroid(geometry),
         coord = st_coordinates(centroid))
origins <- data.frame(id=centroids$GEOID, lon=centroids$coord[, "X"], lat=centroids$coord[, "Y"])

#Destination: Bartlett Practice
bartlett <- data.frame(id="bartlett", lat=39.298399, lon=-76.593530)
bartlett_sf <- st_as_sf(bartlett, coords = c("lon", "lat"), crs = st_crs(bc))

#Map transit routes
ggplot() +
  geom_sf(data = bc, color = "gray50") +
  geom_sf(data=transit_net$routes, aes(color=fare)) +
  geom_sf(data=bartlett_sf, aes(color = "Bartlett"), size = 1) +
  theme_void()


#Set routing inputs
modes <- c("TRANSIT","WALK")
max_walk_time <- 15 #per leg of trip (i.e., access, transfer, egress)
max_trip_duration <- 90
#take median travel time over departure_datetime + time_window
departure_datetime <- as.POSIXct("16-06-2025 07:30:00", format = "%d-%m-%Y %H:%M:%S")
time_window <- 570 #7:30AM-5:00PM

ttm <- travel_time_matrix(r5r_core = r5r_core,
                             origins = origins,
                             destinations = bartlett,
                             mode = modes,
                             max_walk_time = max_walk_time,
                             max_trip_duration = max_trip_duration,
                             departure_datetime = departure_datetime,
                             time_window = time_window,
                             progress = TRUE)
summary(ttm)
save(ttm, file=paste0(here(),"/Data/ttm.RData"))

#Expanded travel time matrix includes breakdown of walking, waiting, # routes, etc.
ettm <- expanded_travel_time_matrix(r5r_core = r5r_core,
                                    origins = origins,
                                    destinations = bartlett,
                                    mode = modes,
                                    departure_datetime = departure_datetime,
                                    time_window = time_window,
                                    max_walk_time = max_walk_time,
                                    max_trip_duration = max_trip_duration,
                                    breakdown = TRUE,
                                    progress = TRUE)
summary(ettm)
save(ettm, file=paste0(here(),"/Data/ettm.RData"))

#Driving time to Bartlett Practice
drivetime <- travel_time_matrix(r5r_core = r5r_core,
                          origins = origins,
                          destinations = bartlett,
                          mode = "CAR",
                          max_trip_duration = max_trip_duration,
                          departure_datetime = departure_datetime,
                          time_window = time_window,
                          progress = TRUE)

summary(drivetime)
save(drivetime, file=paste0(here(),"/Data/drivetime.RData"))

#Sensitivity analysis: 120-minute cutoff
max_trip_duration <- 120
ttm_120 <- travel_time_matrix(r5r_core = r5r_core,
                              origins = origins,
                              destinations = bartlett,
                              mode = modes,
                              max_walk_time = max_walk_time,
                              max_trip_duration = max_trip_duration,
                              departure_datetime = departure_datetime,
                              time_window = time_window,
                              progress = TRUE)
summary(ttm_120)
save(ttm_120, file=paste0(here(),"/Data/ttm_120.RData"))
ettm_120 <- expanded_travel_time_matrix(r5r_core = r5r_core,
                                        origins = origins,
                                        destinations = bartlett,
                                        mode = modes,
                                        departure_datetime = departure_datetime,
                                        time_window = time_window,
                                        max_walk_time = max_walk_time,
                                        max_trip_duration = max_trip_duration,
                                        breakdown = TRUE,
                                        progress = TRUE)
summary(ettm_120)
save(ettm_120, file=paste0(here(),"/Data/ettm_120.RData"))

#Clean up and reallocate memory
stop_r5(r5r_core)
.jgc(R.gc = TRUE)


