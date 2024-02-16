#' getFullUcdpGedData: Wrapper function to download full UCDP GED data up to the
#' latest release (default) or a user-specified release date.
#'
#' @param date A date object defining the reference date for retrieving the latest dataset
#' versions. Defaults to the current system date.
#' @param candidate.only boolean. If set to TRUE, the call will only download the latest
#' monthly and quarterly candidate datasets, and skip downloading the latest yearly
#' release of final GED data, which can take a long time to complete. Default: FALSE
#' @param add.metadata boolean: Add metadata variables to output dataset (TRUE)
#' or not (FALSE)? Includes dataset name, version number, download date. Default: TRUE
#'
#' @return A data.frame containing the latest full UCDP GED data (final + candidate
#' or candidate only)
#' @export
#'
#' @examples
#' # Get the latest UCDP GED data using the current system date
#' getFullUcdpGedData()
#'
#' # Get the latest UCDP GED data using a specific date
#' getFullUcdpGedData(as.Date("2022-12-31"))
getFullUcdpGedData <- function(date = Sys.Date(), candidate.only = FALSE,
                               add.metadata = TRUE){

  ## Get list of latest available GED datasets
  ged.version.df <- getLatestUcdpGedVersionIds(date = date)

  ## If candidate.only == TRUE, skip downloading yearly data
  if(candidate.only == TRUE){
    ged.version.df <- ged.version.df[!grepl("yearly", ged.version.df$update),]
  }

  ## Loop through list and download datasets
  ged.ls <- lapply(1:nrow(ged.version.df), function(x){
    query.df <- getUcdpData(dataset = ged.version.df$dataset[x],
                            version = ged.version.df$version[x])
    if(add.metadata == TRUE){
    query.df$dataset <- "gedevents"
    query.df$version <- ged.version.df$version[x]
    query.df$type <- ged.version.df$type
    query.df$update <- ged.version.df$update[x]
    query.df$download_date <- Sys.Date()
    }
    query.df$query <- x
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
  ged.full.df <- ged.full.df[, !(names(ged.full.df) %in% c("rn", "query"))]

  return(ged.full.df)
}
