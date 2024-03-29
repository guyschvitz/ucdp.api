% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/getLatestUcdpGedVersionIds.R
\name{getLatestUcdpGedVersionIds}
\alias{getLatestUcdpGedVersionIds}
\title{getLatestUcdpGedVersionIds: Get version IDs of latest available UCDP GED datasets.}
\usage{
getLatestUcdpGedVersionIds(date = Sys.Date())
}
\arguments{
\item{date}{A date object defining the reference date for finding the latest dataset
versions. Defaults to the current system date.}
}
\value{
A data.frame listing the latest available versions of the UCDP GED dataset.
}
\description{
This function queries the UCDP GED API to retrieve version IDs of the latest
available UCDP GED datasets. It fetches the version IDs required to download
the full UCDP GED data (final and candidate), covering January 1989 until the
month prior to the latest available update, or up until a user-defined reference
date.
}
\examples{
# Get the latest UCDP GED version IDs using the current system date
getLatestUcdpGedVersionIds()

# Get the latest UCDP GED version IDs using a specific date
getLatestUcdpGedVersionIds(as.Date("2022-12-31"))
}
