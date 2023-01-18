# ucdp.api
Guy Schvitz, 13. Jan 2023

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

Currently the package only allows complete downloads of each dataset, filtering and subsetting (e.g. by date or country) is not supported.

## Installation
You can install the package as follows:

```r
library(devtools)
devtools::install_github("guyschvitz/ucdp.api")
```
You also need the `dplyr` and `httr` packages. R will try to install these dependencies if not already installed.

## `getUcdpData`: Load UCDP data from the API
The function takes the following 3 arguments: 

- `dataset`: Name of required UCDP dataset
- `version`: Version of dataset needed
- `pagesize`: Number of entries per query (max 1000). The UCDP API divides dataset into N pages of size S,
the query loops over all pages until full dataset is retrieved.

#### Examples
```r
## Load one-sided violence dataset (version 22.1, released Jul 2022)
osv.df <- getUcdpData(dataset = "onesided", version = "22.1", pagesize = 1000)

## Load GED data (version 22.1, released Jul 2022)
ged.df <- getUcdpData(dataset = "gedevents", version = "22.1", pagesize = 1000)

## Load GED candidate event data for Nov 2022 (version 22.0.11, released Dec 2022)
gedc.df <- getUcdpData(dataset = "gedevents", version = "22.0.11", pagesize = 1000)
```

## `checkUcdpAvailable`: Check which UCDP dataset versions are currently available
This function is helpful to get an overview of currently available UCDP datasets (e.g. to write a procedure to automatically download the latest available version). 

The following two arguments are needed:
- `dataset`: Name of required UCDP dataset
- `version`: Version of dataset needed

#### Examples
```r
## Check if version "22.1" of the GED data is available
checkUcdpAvailable(dataset = "gedevents", version = "22.1")

#     dataset version exists
# 1 gedevents    22.1   TRUE

## Check which monthly UCDP GED candidate datasets are available (status as of 2023-01-18)
## ... Generate month ids (1 to 12)
m.ids <- 1:12
## ... Loop over month ids
do.call(rbind, lapply(m.ids, function(x){
  checkUcdpAvailable("gedevents", sprintf("22.0.%s", x))
}))

#     dataset version exists
# 1  gedevents  22.0.1   TRUE
# 2  gedevents  22.0.2   TRUE
# 3  gedevents  22.0.3   TRUE
# 4  gedevents  22.0.4   TRUE
# 5  gedevents  22.0.5   TRUE
# 6  gedevents  22.0.6   TRUE
# 7  gedevents  22.0.7   TRUE
# 8  gedevents  22.0.8   TRUE
# 9  gedevents  22.0.9   TRUE
# 10 gedevents 22.0.10   TRUE
# 11 gedevents 22.0.11   TRUE
# 12 gedevents 22.0.12  FALSE

## Check which quarterly UCDP GED candidate datasets are available
## ... Generate quarter ids (3, 9 and 12)
q.ids <- sprintf("%02d", seq(3, 12, 3))
## ... Loop over quarter ids
do.call(rbind, lapply(q.ids, function(x){
  checkUcdpAvailable("gedevents", sprintf("22.01.22.%s", x))
}))

#     dataset     version exists
# 1 gedevents 22.01.22.03   TRUE
# 2 gedevents 22.01.22.06   TRUE
# 3 gedevents 22.01.22.09   TRUE
# 4 gedevents 22.01.22.12  FALSE
```

## `pingUrl`: Helper function to check internet connection and URL/API Query
This function is called from within `getUcdpData` to check if the API can respond to the query entered by the user. 
If there is no response, this is either due to problems with the internet connection, the user's proxy settings or because the specified query / URL is invalid. The error message includes an HTTP error code which may help identify the issue. 

#### Examples
```r
pingUrl("www.google.com") ## Works, no error
pingUrl("www.goooogle.com") ## Does not work, will stop function and return an error
```
