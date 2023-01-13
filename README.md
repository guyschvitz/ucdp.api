# ucdp.api
Guy Schvitz, 13. Jan 2023

This package allows users to load data from the Uppsala Conflict Database Program (UCDP) API directly into R. 

Available datasets include: UCDP/PRIO armed conflict, Battle-related deaths, Dyadic conflict, Non-state conflict, One-sided violence, Georeferenced Events Data (GED) and the GED candidate events datasets. 

## Installation
You can install the package as follows:

```r
library(devtools)
devtools::install_github("guyschvitz/ucdp.api")
```
You also need the `dplyr` and `httr` packages. R will try to install these dependencies if not already installed.

## `getUcdpData`: Load UCDP data from the API
This function allows users to download one of the following datasets:

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
dyd.df <- getUcdpData(dataset = "gedevents", version = "22.1", pagesize = 1000)

## Load GED candidate event data for Nov 2022 (version 22.0.11, released Dec 2022)
dyd.df <- getUcdpData(dataset = "gedevents", version = "22.0.11", pagesize = 1000)
```

## `pingUrl`: Helper function to check internet connection and URL/API Query
This function is called from within `getUcdpData` to check if the API can respond to the query entered by the user. 
If there is no response, this is either due to problems with the internet connection, the user's proxy settings or because the specified query / URL is invalid. The error message includes an HTTP error code which may help identify the issue. 

#### Examples
```r
pingUrl("www.google.com") ## Works, no error
pingUrl("www.goooogle.com") ## Does not work, will stop function and return an error
```
