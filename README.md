# dprtools
Guy Schvitz, 13. Jan 2023

This package allows users to load data from the Uppsala Conflict Database Program (UCDP) API directly into R. Available datasets include: UCDP/PRIO armed conflict, Battle-related deaths, Dyadic conflict, Non-state conflict, One-sided violence, Georeferenced Events Data (GED) and the GED candidate events datasets. For more information on these datasets, see: https://ucdp.uu.se/apidocs/

## Installation
You can install the package as follows:

```r
library(devtools)
install_github("guyschvitz/ucdp.api")
```
You also need the `dplyr` and `httr` packages in R. R will try to install them if not already installed.

## `getUcdpData`: Load UCDP data from the API
This function allows users to download one of the following datasets:

#### Yearly data
- Armed conflict dataset
- Battle-related deaths dataset
- Dyadic conflict dataset
- Non-state conflict dataset
- One-sided violence dataset

#### Daily data (Conflict event data)
- Georeferenced Event Dataset (GED)
- Georeferenced Event Dataset (GED), Candidate eent data

For more information on these datasets, available versions and their names, see: https://ucdp.uu.se/apidocs/.

Currently the package only allows complete downloads of each dataset, filtering and subsetting (e.g. by date or country) is not supported.

The function takes the following 3 arguments: 

#### Examples
```r
## Load one-sided violence dataset (version 22.1, released Jul 2022)
osv.df <- getUcdpData(dataset = "onesided", version = "22.1", pagesize = 1000)

## Load GED data (version 22.1, released Jul 2022)
dyd.df <- getUcdpData(dataset = "gedevents", version = "22.1", pagesize = 1000)

## Load GED candidate event data for Nov 2022 (version 22.0.11, released Dec 2022)
dyd.df <- getUcdpData(dataset = "gedevents", version = "22.0.11", pagesize = 1000)
```

## `pingUrl`: Helper function to check internet connection and URL/API Query
This function is called from within `getUcdpData` to check if the API can respond to the query entered by the user. 
If there is no response, this is either due to problems with the internet connection, the user's proxy settings or because the specified query / URL is invalid. The error message includes an HTTP error code which may help identify the issue. 
