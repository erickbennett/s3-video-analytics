#   This file will:
#      1. download AWS log files from S3
#      2. combine log files into one data set
#      3. query a service for browser details
#      4. output a tidy data set for a shiny to generate reporting
#
#   To add new file names or video sets, update: VideoCollections.R
#
#   Replace < info > with specifics on lines 29, 30, and 75
#
#   Author: erick bennett


# load packages for study
library(dplyr)
library(lubridate)
library(jsonlite)


# download log files
setwd("~/Data")
data.folder <- paste("video-logs-", gsub(c(" |:"), "-", date()), sep = "")
system(paste("mkdir", data.folder))
log.path <- paste("~/Data/", data.folder, sep = "")
setwd(log.path)

# instruct the os to download the log files
# Note: AWS CLI must be configured on the workstation
system("aws s3 cp s3://<your aws bucket> . --recursive")
system("aws s3 cp s3://<your second aws bucket> . --recursive")

#  get list of files in the log directory
log.files <- list.files()

# read log files into a data frame
log.df <- data.frame()

# add column names
columns <- c('Bucket_Owner', 'Bucket', 'Time', 'GMT', 'Remote_IP', 'Requester',
             'Request_ID', 'Operation', 'Key', 'Request_URI', 'HTTP_status',
             'Error_Code', 'Bytes_Sent', 'Object_Size', 'Total_Time',
             'Turn_Around_Time', 'Referrer', 'User_Agent', 'Version_ID')

for (i in 1:length(log.files)) {
  log.df <- rbind(log.df, read.table(log.files[i],
                                     header = FALSE,
                                     sep = " ",
                                     stringsAsFactors = FALSE,
                                     col.names = columns))
}


# convert data frame to table for dplyr
logs <- tbl_df(log.df)

# remove "[" from time field
logs <- mutate(logs, Date_Time_GMT = substr(logs$Time, 2, 21))

# put date_time into time format
logs <- mutate(logs, Date_Time = dmy_hms(logs$Date_Time_GMT))

# S3 logs record in UTC 0000 -- 6 hours ahead of MDT
logs <- mutate(logs, Date_Time = Date_Time - hours(6))

# split date and hours variables
logs$Hour <- format(as.POSIXct(logs$Date_Time), format = '%H:%M:%S')
logs$Date <- as.Date(logs$Date_Time)

# Add a play count value to data set
logs$PlayCount <- 1

# reduce to only 'get' video actions:
logs <- filter(logs,
               Operation == "WEBSITE.GET.OBJECT",
               grepl("<video folder 1 path> | <video folder 2 path>", Key))


# read in the sets of videos
setwd("~/Development/s3-video-analytics/")
source("VideoCollections.R")

# loop through the video sets (i) contained in the list
for (i in 1:length(video.collection)) {

  # loop through each video name in the set i
  for (j in 1:length(video.collection[[i]])) {

    # loop through logs for matches to video j in row k of column Key
    for (k in 1:length(logs$Key)) {

      # when a match is found, add the video name and the set name
      if (grepl(video.collection[[i]][j], logs$Key[k]) == TRUE) {
        logs$Video[k] <- video.collection[[i]][j]
        logs$Video_Set[k] <- names(video.collection[i])
      }
    }

  }
}


# call agent string service to obtain browser details
# store results in a new data frame browser.names
User_Agent <- unique(logs$User_Agent)
browser.names <- data.frame(User_Agent)

browser.names$Browser <- "UNK"
browser.names$Browser_Version <- "UNK"
browser.names$OS <- "UNK"

for (i in 1:length(browser.names$User_Agent)) {
  agent.id <- gsub(" ", "%20", browser.names$User_Agent[i])

  browser.id <- paste("http://www.useragentstring.com/?uas=",
                      agent.id,
                      "&getJSON=all",
                      sep = '')

  json.call <- fromJSON(browser.id)

  browser.names$Browser[i] <- json.call[[2]]
  browser.names$Browser_Version[i] <- json.call[[3]]
  browser.names$OS[i] <- json.call[[4]]
}

# Add browser details to logs data table
for (i in 1:length(logs$User_Agent)) {
  search <- filter(browser.names, User_Agent == logs$User_Agent[i])

  logs$Browser[i] <- search[2]
  logs$Browser_Version[i] <- search[3]
  logs$OS[i] <- search[4]
}


# drop variables from table to create a final tidy set of data
logs <- select(logs, Date, Hour, Video, Video_Set, PlayCount, Remote_IP,
               Browser, Browser_Version, OS)

saveRDS(logs, file = 'videologs.rds')
