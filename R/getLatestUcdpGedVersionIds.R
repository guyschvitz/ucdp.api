#' getLatestUcdpGedVersionIds: Get version IDs of latest available UCDP GED datasets
#'
#' This function queries the UCDP GED API to retrieve version IDs of the latest
#' available UCDP GED datasets. It fetches the version IDs required to download
#' the full UCDP GED data (final and candidate), covering January 1989 until the
#' month prior to the latest update.
#'
#' @param date A date object defining the reference date for finding the latest dataset
#' versions. Defaults to the current system date.
#'
#' @return A data.frame listing the latest available versions of the UCDP GED dataset.
#'
#' @examples
#' # Get the latest UCDP GED version IDs using the current system date
#' getLatestUcdpGedVersionIds()
#'
#' # Get the latest UCDP GED version IDs using a specific date
#' getLatestUcdpGedVersionIds(as.Date("2022-12-31"))
getLatestUcdpGedVersionIds <- function(date = Sys.Date()){

  ## Define yearly UCDP GED data version numbers:
  ## Yearly updates cover 1989 until (excluding) year of the update
  ## Example: UCDP GED 23.1 covers Jan 1989 to Dec 2022
  ## ... Extract year from current date
  date <- as.Date(date)
  yr <- as.numeric(format(date, "%y"))

  ## ... Also include previous yearly data in case current year version has
  ## ... Not been released yet (released around June/July)
  prev.yr <- yr - 1
  yrs <- c(yr, prev.yr)

  ## ... Construct yearly version numbers
  yr.versions <- sprintf("%s.1", yrs)
  names(yr.versions) <- rep("yearly", length(yr.versions))

  ## Define monthly version numbers.
  m.versions <- unlist(lapply(yrs, function(x){sprintf("%s.0.%s", x, 1:12)}))
  names(m.versions) <- rep("monthly", length(m.versions))

  ## Define quarterly version numbers
  ## NOTE: Normally the quarterly releases would end with months 3, 6, 9 and 12,
  ## But UCDP's quarterly release schedule is not 100% consistent so we have to
  ## consider all months
  q.versions <- unlist(lapply(yrs, function(x){sprintf("%s.01.%s.%s", x, x,
                                                       ## ... Add leading zero
                                                       sprintf("%02d", 1:12))}))
  names(q.versions) <- rep("quarterly", length(q.versions))

  ## Combine all version names into single vector and data.frame
  version.vec <- c(yr.versions, q.versions, m.versions)
  version.df <- data.frame(update = names(version.vec),
                           version = unname(version.vec))

  ## Code additional variables
  ## ... Year label
  version.df$yr <- substr(version.df$version, 1,2)

  ## ... Month label
  version.df$mon <- as.numeric(stringr::str_extract(version.df$version, "[0-9]{1,}$"))

  ## Check which datasets exist and keep only those dataset names
  version.df$exists <- sapply(1:nrow(version.df), function(x) {
    checkUcdpAvailable(dataset = "gedevents", version = version.df$version[x],
                       as.vector = TRUE)
  })

  ## ... Keep only existing datasets
  version.df <- version.df[version.df$exists == TRUE,]

  ## ... Add "final" vs "candidate" label
  version.df$type <- ifelse(grepl("yearly", version.df$update), "final", "candidate")

  ## ... Add dataset name label
  version.df$dataset <- "gedevents"

  ## ... Keep only required yearly update
  keep.yr.df <- subset(version.df, update == "yearly")
  keep.yr.df <- subset(keep.yr.df, yr == max(yr))

  ## Keep only required quarterly update:
  keep.q.df <- subset(version.df, update == "quarterly")
  keep.q.df <- subset(keep.q.df, yr == max(yr) & mon == max(mon))

  ## Keep only required monthly update:
  keep.m.df <- subset(version.df, update == "monthly")
  keep.m.df <- subset(keep.m.df,
                      ## Case 1: Monthly update is from year after latest
                      ## Quarterly update
                      yr > keep.q.df$yr |
                        ## Case 2: Monthly update is from month after latest
                        ## Quarterly update in the same year
                        yr == keep.q.df$yr & mon > keep.q.df$mon)

  ## Compile final UCDP GED version ids
  version.df <- unique(rbind(keep.yr.df, keep.q.df, keep.m.df))
  version.df <- version.df[,c("dataset", "type", "update", "version", "exists")]

  return(version.df)
}
