#' getFullUcdpGedData: Wrapper function to download full UCDP GED data up to the
#' latest release (default) or a user-specified release date.
#'
#' Note: Final date of data coverage is always one month prior to the UCDP
#' release date.
#'
#' @param date A date object defining the reference date for retrieving the latest dataset
#' versions. Defaults to the current system date.
#' @return A data.frame listing the latest available versions of the UCDP GED dataset.
#'
#' @examples
#' # Get the latest UCDP GED data using the current system date
#' getFullUcdpGedData()
#'
#' # Get the latest UCDP GED data using a specific date
#' getFullUcdpGedData(as.Date("2022-12-31"))
getFullUcdpGedData <- function(date = Sys.Date()){

  ## Get list of latest available GED datasets
  ged.version.df <- getLatestUcdpGedVersionIds(date = date)

  ## Loop through list and download datasets
  ged.ls <- lapply(1:nrow(ged.version.df), function(x){
    query.df <- getUcdpData(dataset = ged.version.df$dataset[x],
                            version = ged.version.df$version[x])
    query.df$update <- ged.version.df$update[x]
    query.df$source <- ged.version.df$version[x]
    return(query.df)
  })

  ## Combine list into data.frame
  ged.full.df <- do.call("rbind", ged.ls)

  ## Handling potential duplicates
  ## (if an event entry is updated from one release to the next, keep only the
  ## latest version of the event entry)

  ## ... Arrange combined data frame by 'id' and in descending order of 'query'
  ged.full.df <- ged.full.df[order(ged.full.df$id, -ged.full.df$query), ]

  ## ... Add a column 'rn' to count observations for each event id
  ged.full.df$rn <- ave(rep(1, nrow(ged.full.df)), ged.full.df$id, FUN = seq_along)

  ## ... Subset the data frame to keep only the first occurrences of each event id
  ged.full.df <- ged.full.df[ged.full.df$rn == 1, ]

  ## ... Remove temporary columns 'query' and 'dupl'
  ged.full.df <- ged.full.df[, !(names(ged.full.df) %in% c("rn"))]

  return(ged.full.df)
}
