#' checkUcdpAvailable: Check which UCDP datasets are currently available through the API.
#'
#' @param dataset character. Name of UCDP dataset. Needs to be one of the following:
#' "ucdpprioconflict", "battledeaths", "dyadic", "nonstate", "onesided" (yearly data),
#' or "gedevents" (daily data, released in monthly batches)
#' The API does not require an account/key but there are some usage limitations
#' For more information, see: https://ucdp.uu.se/apidocs/
#' @param version character. Dataset version number.
#' For yearly UCDP data: Format: YY.1 (e.g. 22.1 for data released in 2022)
#' For monthly UCDP GED data use format: YY.0.MM (e.g. 22.0.11 for data on November 2022)
#' For quarterly UCDP releases data use format: YY.01.YY.MM
#' (e.g. 22.01.22.09 for data from Jan to Sep 2022)
#' @param as.vector boolean: Return output as multi-column data.frame (FALSE) or
#' as simple vector (TRUE)? Default: FALSE
#'
#' @return data.frame with requested UCDP dataset
#' @export
#'
#' @examples
#' ## Check which monthly UCDP GED candidate datasets are available
#' ## m.ids <- 1:12
#' gedc.m.check.df <- do.call(rbind, lapply(m.ids, function(x){
#'   checkUcdpAvailable("gedevents", sprintf("22.0.%s", x))
#'   }))
#'
#' ## Check which quarterly UCDP GED candidate datasets are available
#' q.ids <- sprintf("%02d", seq(3, 12, 3))
#' gedc.q.check.df <- do.call(rbind, lapply(q.ids, function(x){
#'   checkUcdpAvailable("gedevents", sprintf("22.01.22.%s", x))
#'   }))
#'
checkUcdpAvailable <- function(dataset, version, as.vector = FALSE){

  ## Check if dataset name is valid
  dataset.names <- c("ucdpprioconflict", "battledeaths", "dyadic", "nonstate",
                     "onesided", "gedevents")

  dataset.string <- paste(paste0("'", dataset.names, "'"), collapse = ", ")

  if(!dataset %in% dataset.names){
    stop(sprintf("dataset name needs to be one of the following:\n%s",
                 dataset.string))
  }

  ## Build initial URL: Insert dataset and version number
  url <- sprintf("https://ucdpapi.pcr.uu.se/api/%s/%s?pagesize=1",
                 dataset, version)

  ## ping URL
  url.ping <- tryCatch(
    httr::GET(url),
    error = function(e){e})

  ## Check if query returns an error or not
  if(any(class(url.ping) == "error") | url.ping$status_code %in% 400:504) {
    exists <- F
  } else {
    exists <- T
  }

  ## Collect name of data, version and result of ping
  if(as.vector){
    return(exists)
  } else {
    out.df <- data.frame("dataset" = dataset,
                         "version" = version,
                         "status" = url.ping$status_code,
                         "exists" = exists)
    return(out.df)
  }
}
