# AWS S3 Log File Analytics Application

## Purpose
AWS S3 bucket logging creates text files that are stored in another S3 bucket.
This application will read all log files and generate a dynamic Shiny App.

The S3 log bucket being analyzed is generated from visits to a video webapp.

## Log File Format
Each log file contains the following headers:

Bucket_Owner
Bucket
Time
GMT
Remote_IP
Requester
Request_ID
Operation
Key
Request_URI
HTTP_status
Error_Code
Bytes_Sent
Object_Size
Total_Time
Turn_Around_Time
Referrer
User_Agent
Version_ID

The application will read each entry for every log file and create a data table with these headers as column or variable names.

## Data Transformation

### Date and Time
The default format of 'Time' is unusuable. Upon reading all entries, the date
variable is formated to: YYYY/DD/MM and the time value is split into a separate variable.

### Video File Names
A new variable 'Video' is created from reading what video was requested by the user from the Request_URI variable.

### User Agent String
User_Agent records the browser type, version, and OS of the user in the form of a non-friendly string. This agent string is passed to a web service, which returns a friendly browser name, version, and OS, all of which are recorded as new variables in the data table.

The web service is located here: http://useragentstring.com/

## Plot and Analytics
After the tidy data set is created, it is passed to ggvis which is hosted on shiny.io as a plotting web app.

## Asumptions
You copy the log files locally to your usr directory\Data.
You have the application in usr\Development\.

# Specific S3 Information
In LogGeneration.R -- replace text in < > with your specific information.
