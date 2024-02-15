# ucdp.api
Guy Schvitz, 15. Feb 2024

This package allows users to load data from the Uppsala Conflict Database Program (UCDP) API directly into R. Available datasets include:

#### Yearly data
- Armed conflict dataset (State-based conflict)
- Battle-related deaths dataset (State-based conflict)
- Dyadic conflict dataset (State-based conflict) 
- Non-state conflict dataset
- One-sided violence dataset

#### Daily data (Conflict event data)
- Georeferenced Event Dataset (GED), Stable releases (Updated yearly)
- Georeferenced Event Dataset (GED), Candidate event data (Updated monthly)

For more information on these datasets, available versions and their names, see: https://ucdp.uu.se/apidocs/.

The package only allows complete downloads of each dataset, filtering and subsetting (e.g. by date or country) is not supported.

## Installation
You can install the package as follows:

```r
library(devtools)
devtools::install_github("guyschvitz/ucdp.api")
```
You also need the `dplyr`, `httr`, `stringr` and `lubridate` packages. R will try to install these dependencies if not already installed.

## `getUcdpData`: Load UCDP data from the API
The function takes the following 3 arguments: 

- `dataset`: Name of required UCDP dataset
- `version`: Version of dataset needed
- `pagesize`: Number of entries per query (max 1000). The UCDP API divides dataset into N pages of size S,
the query loops over all pages until full dataset is retrieved.
- `max.retries`: Integer. umeric (integer). Maximum number of retry attempts for API calls in case of failure, default: 10. Useful for managing temporary network or server issues. Exceeding max.retries stops the function with an error.
- `add.metadata`: Boolean. Add metadata variables (dataset name, version, download date)
to output dataset (TRUE) or omit them (FALSE)? Default: TRUE

#### Examples
```r
## Load one-sided violence dataset (version 23.1, released Jul 2023)
osv.df <- getUcdpData(dataset = "onesided", version = "23.1", pagesize = 1000)

# Checking if dataset 'onesided' 23.1 exists...
# 
# Getting UCDP 'onesided' dataset, Version 23.1...
#   |=====================================================================================| 100%
# Done.

## Load GED candidate event data for Nov 2023 (version 23.0.11, released Dec 2023)
gedc.df <- getUcdpData(dataset = "gedevents", version = "23.0.11", pagesize = 1000, add.metadata = FALSE)

# Checking if dataset 'gedevents' 23.0.11 exists...
# 
# Getting UCDP 'gedevents' dataset, Version 23.0.11...
#   |=====================================================================================| 100%
# Done.

```

## `checkUcdpAvailable`: Check which UCDP dataset versions are currently available
This function is helpful to get an overview of currently available UCDP datasets (e.g. to write a procedure to automatically download the latest available version). 

The following two arguments are needed:
- `dataset`: Name of required UCDP dataset
- `version`: Version of dataset needed

#### Examples
```r
## Check if version "23.1" of the GED data is available
checkUcdpAvailable(dataset = "gedevents", version = "23.1")

#     dataset version exists
# 1 gedevents    23.1   TRUE

## Return results as boolean vector
checkUcdpAvailable(dataset = "gedevents", version = "23.1", as.vector = TRUE)

# [1] TRUE

## Check which monthly UCDP GED candidate datasets are available (status as of 2023-01-18)
## ... Generate month ids (1 to 12)
m.ids <- 1:12
## ... Loop over month ids
do.call(rbind, lapply(m.ids, function(x){
  checkUcdpAvailable("gedevents", sprintf("23.0.%s", x))
}))

#     dataset version exists
# 1  gedevents  23.0.1   TRUE
# 2  gedevents  23.0.2   TRUE
# 3  gedevents  23.0.3   TRUE
# 4  gedevents  23.0.4   TRUE
# 5  gedevents  23.0.5   TRUE
# 6  gedevents  23.0.6   TRUE
# 7  gedevents  23.0.7   TRUE
# 8  gedevents  23.0.8   TRUE
# 9  gedevents  23.0.9   TRUE
# 10 gedevents 23.0.10   TRUE
# 11 gedevents 23.0.11   TRUE
# 12 gedevents 23.0.12  FALSE

## Check which quarterly UCDP GED candidate datasets are available
## ... Generate quarter ids (3, 9 and 12)
q.ids <- sprintf("%02d", seq(3, 12, 3))
## ... Loop over quarter ids
do.call(rbind, lapply(q.ids, function(x){
  checkUcdpAvailable("gedevents", sprintf("23.01.23.%s", x))
}))

#     dataset     version exists
# 1 gedevents 23.01.23.03   TRUE
# 2 gedevents 23.01.23.06   TRUE
# 3 gedevents 23.01.23.09   TRUE
# 4 gedevents 23.01.23.12  FALSE
```

## `getLatestUcdpGedVersionIds.R`: Get version IDs of latest available UCDP GED datasets
This function queries the UCDP GED API to retrieve version IDs of the latest available UCDP GED datasets. It fetches the version IDs required to download the full UCDP GED data (final and candidate), covering January 1989 until the month prior to the latest available update, or up until a user-defined reference date.

The function takes the following argument:

- `date`: Reference date. The function will retrieve all available version id's up to this date. Defaults to current date. 

#### Examples
```
## Get latest version ids for UCDP GED data (reference date: current date)
getLatestUcdpGedVersionIds()

#     dataset      type    update     version exists
# 2  gedevents     final    yearly        23.1   TRUE
# 26 gedevents candidate quarterly 23.01.23.12   TRUE


## Get UCDP GED version ids up to user-specified dates
getLatestUcdpGedVersionIds(date = "2023-05-01")

#     dataset      type    update     version exists
# 1 gedevents     final    yearly        23.1   TRUE
# 6 gedevents candidate quarterly 23.01.23.04   TRUE

getLatestUcdpGedVersionIds("2023-04-01")

#      dataset      type    update     version exists
# 1  gedevents     final    yearly        23.1   TRUE
# 26 gedevents candidate quarterly 22.01.22.12   TRUE
# 27 gedevents candidate   monthly      23.0.1   TRUE
# 28 gedevents candidate   monthly      23.0.2   TRUE
# 29 gedevents candidate   monthly      23.0.3   TRUE

getLatestUcdpGedVersionIds("2022-12-01")

#      dataset      type    update     version exists
# 1  gedevents     final    yearly        22.1   TRUE
# 11 gedevents candidate quarterly 22.01.22.09   TRUE
# 36 gedevents candidate   monthly     22.0.10   TRUE
# 37 gedevents candidate   monthly     22.0.11   TRUE

```

## `getFullUcdpGedData.R`: Download complete UCDP GED data up to latest available release
This wrapper function downloads the full UCDP GED data up to the latest release (default) or a user-specified release date.

Note: Downloading the full UCDP GED dat can take some time, depending on your connection, server traffic, network congestion etc.

The function takes the following 3 arguments: 

- `date`: Name of required UCDP dataset
- `candidate.only`: boolean. If set to TRUE, the call will only download the latest monthly and quarterly candidate datasets, and skip downloading the latest yearly release of final GED data, which can take a long time to complete. Default: FALSE
- `add.metadata`: Boolean. Add metadata variables (dataset name, version, download date)
to output dataset (TRUE) or omit them (FALSE)? Default: TRUE

#### Examples
```r
## Get complete UCDP dataset up until latest monthly update (this takes a long time)
getFullUcdpGedData()

## Skip downloading latest yearly dataset to save time
getFullUcdpGedData(candidate.only = TRUE)
```

## `getUcdpMetaData.R`: Get metadata from UCDP Dataset downloaded through ucdp.api package
This function extracts metadata from a UCDP dataset downloaded through the API using the {ucdp.api} R package and prints the results as a text string or a console message.

The function takes the following arguments:
- `ucdp.df`: A data.frame containing UCDP data with expected metadata columns.
- `as.text`: boolean. Should result be returned as text (TRUE) or printed 
to the console (FALSE)? Default: FALSE

```
## Download UCDP data
sbc.df <- getUcdpData(dataset = "ucdpprioconflict", "23.1", add.metadata = TRUE)

# Checking if dataset 'ucdpprioconflict' 23.1 exists...
# 
# Getting UCDP 'ucdpprioconflict' dataset, Version 23.1...
#   |=====================================================================================| 100%
# Done.

## Extract metadata
getUcdpMetaData(sbc.df, as.text = FALSE)

# UCDP State-based conflict dataset, downloaded through the UCDP API on 15 February 2024 using the ucdp.api R package:
# https://github.com/guyschvitz/ucdp.api 
# 
# Dataset version(s): 23.1 
# Data coverage: 1946 to 2022 
# For more information on the UCDP data and API, visit: https://ucdp.uu.se/apidocs/ 

## Store output as text (e.g. to save to txt file)
meta.txt <- getUcdpMetadata(sbc.df, as.text = TRUE)
```
