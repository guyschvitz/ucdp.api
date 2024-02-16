#' getUcdpMetaData: Get metadata from UCDP Dataset downloaded through {ucdp.api}
#'
#' This function extracts metadata from a UCDP dataset downloaded through the
#' API using the {ucdp.api} R package and prints the results as a text string
#' or console message.
#'
#' @param ucdp.df A data.frame containing UCDP data with expected metadata columns.
#' @param as.text boolean: Should result be returned as text (TRUE) or printed
#' to the console (FALSE)? Default: FALSE
#'
#' @return A text summary of the metadata or message printed to console
#' @export
#'
#' @examples
#' ucdp.df <- read.csv("your_ucdp_data_file.csv")
#' getUcdpMetaData(ucdp.df, as.text = TRUE)
getUcdpMetaData <- function(ucdp.df, as.text = FALSE) {

  ## Define dataset names and labels
  dataset.names <- c("ucdpprioconflict", "battledeaths", "dyadic", "nonstate",
                     "onesided", "gedevents")
  dataset.lbls <- setNames(c("State-based conflict", "State based conflict, battle-related deaths",
                             "State based conflict, dyadic", "Non-state conflict",
                             "One-sided violence", "Georeferenced event"), dataset.names)

  ## Validate required columns and extract information
  required.cols <- c("dataset", "version", "download.date")
  if (!all(required.cols %in% names(ucdp.df))) {
    warning("Metadata variables not found, outputting only known information.")
    dataset <- version <- "**unknown**"
    download.date <- NA
  } else {
    dataset <- unique(ucdp.df$dataset)
    dataset.lbl <- dataset.lbls[dataset]
    version <- unique(ucdp.df$version)
    download.date <- unique(ucdp.df$download.date)
  }

  ## Process dates and coverage
  if (dataset == "gedevents") {
    ged.dates <- as.Date(unique(ucdp.df$date_start))
    all.dates <- seq(min(ged.dates), max(ged.dates), "1 day")
    date.gaps <- all.dates[!all.dates %in% ged.dates]
    start <- format(min(ged.dates), "%d %b %Y")
    end <- format(max(ged.dates), "%d %b %Y")
  } else {
    years <- unique(ucdp.df$year)
    start <- min(years)
    end <- max(years)
  }

  ## Format download date
  download.date.formatted <- if(!is.na(download.date)){
    format(download.date, '%d %B %Y')
  } else {
    "**unknown date**"
  }

  ## Construct message text
  txt <- glue::glue(
    "UCDP {dataset.lbl} dataset, downloaded through the UCDP API on {download.date.formatted} using the ucdp.api R package:\nhttps://github.com/guyschvitz/ucdp.api \n\n",
    "Dataset version(s): {paste(version, collapse = ', ')} \n",
    "Data coverage: {start} to {end} \n",
    "For more information on the UCDP data and API, visit: https://ucdp.uu.se/apidocs/ \n",
    if (dataset == "gedevents") {
      date.gaps.msg <- if (!as.text && length(date.gaps) > 20) {
        paste(c(as.character(date.gaps[1:20]), "..."), collapse = ", ")
      } else {
        paste(date.gaps, collapse = ", ")
      }
      sprintf("%s Date(s) missing from dataset:\n\n%s.", length(date.gaps), date.gaps.msg)
    } else {
      ""
    }
  )
  if (as.text) {
    return(txt)
  } else {
    message(txt)
  }
}
