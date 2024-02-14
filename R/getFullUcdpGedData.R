#' getFullUcdpGedData: Function to download full Ucdp GED data up to a user-
#' specified release date.
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
    query.df$query <- x
    return(query.df)
  })

  ## Combine list into data.frame
  ged.df <- do.call("rbind", ged.ls)

  ## Handling potential duplicates
  ## ... Arrange combined data frame by 'id' and in descending order of 'query'
  ged.full.df <- ged.full.df[order(ged.full.df$id, -ged.full.df$query), ]

  ## ... Add a column 'dupl' for duplicates and mark the first occurrence
  ged.full.df$dupl <- ave(ged.full.df$id, ged.full.df$id,
                          FUN = function(x){length(x) > 1})

  ## ... Convert logical to actual TRUE/FALSE values for clarity
  ged.full.df$dupl <- ged.full.df$dupl == "TRUE"

  ## ... Subset the data frame to keep only the first occurrences
  ged.full.df <- ged.full.df[!duplicated(ged.full.df$id), ]

  ## ... Remove temporary columns 'query' and 'dupl'
  ged.full.df <- ged.full.df[, !(names(ged.full.df) %in% c("query", "dupl"))]

  return(ged.full.df)
}
