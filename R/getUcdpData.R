#' getUcdpData: Download data from the Uppsala Conflict Database Program API.
#'
#' @param dataset character. Name of UCDP dataset. Needs to be one of the following:
#' "ucdpprioconflict", "battledeaths", "dyadic", "nonstate", "onesided" (yearly data),
#' or "gedevents (daily data, released in monthly batches)
#' The API does not require an account/key but there are use limitations
#' For more information, see: https://ucdp.uu.se/apidocs/
#'
#' @param version character. Dataset version number.
#' For yearly UCDP data: Format: YY.1 (e.g. 22.1 for data released in 2022)
#' For monthly UCDP GED data use format: YY.0.MM (e.g. 22.0.11 for data on November 2022)
#' For quarterly UCDP releases data use format: YY.01.YY.MM (e.g. 22.01.22.09 for data from Jan to Sep 2022)
#'
#' @param pagesize Page size of each individual query. Default: 100. Max: 1000
#' The UCDP API divides dataset into N pages of size S,
#' the query loops over all pages until full dataset is retrieved.
#'
#' @return data.frame with requested UCDP dataset
#' @export
#'
#' @examples
#' getUCDPData(dataset = ucdpprioconflict, version = "22.1", pagesize = 100)
#' getUCDPData(dataset = gedevents, version = "22.1", pagesize = 100)
getUcdpData <- function(dataset, version, pagesize = 100){

  ## Stop if requested pagesize greater than 1000
  if(pagesize > 1000){
    stop("Page size cannot exceed 1000")
  }

  ## Check if dataset name is valid
  dataset.names <- c("ucdpprioconflict", "battledeaths", "dyadic", "nonstate",
                     "onesided", "gedevents")

  dataset.string <- paste(paste0("'", dataset.names, "'"), collapse = ", ")

  if(!dataset %in% dataset.names){
    stop(sprintf("dataset name needs to be one of the following:\n%s",
                 dataset.string))
  }

  ## Build initial URL: Insert dataset number, version and pagesize
  url <- sprintf("https://ucdpapi.pcr.uu.se/api/%s/%s?pagesize=%s",
                 dataset, version, pagesize)

  ## Check if URL is valid
  pingUrl(url)

  ## Get initial response and content
  response <- httr::GET(url)
  content.ls <- httr::content(response, encoding = "UTF-8")
  outdata.ls <- content.ls$Result

  ## Get total number of pages needed to retrieve complete dataset
  pages <- content.ls$TotalPages

  ## Get url of next page
  nxt.url <- content.ls$NextPageUrl

  ## Loop over remaining pages and append results
  ## Stops if NextPageUrl does not exist (empty string)
  while(content.ls$NextPageUrl != ""){
    ## Get content of next page
    response <- httr::GET(content.ls$NextPageUrl)
    content.ls <- httr::content(response, encoding = "UTF-8")
    ## Append content from next page to content from previous n pages
    outdata.ls <- c(outdata.ls, content.ls$Result)
  }

  ## Output results as dataframe
  outdata.df <- dplyr::bind_rows(lapply(outdata.ls, unlist))

  ## Convert true numeric character columns to numeric
  ## ... Function to identify numeric columns
  isNumeric <- function(x){
    all(suppressWarnings(!is.na(as.numeric(na.omit(x)))))
  }

  ## ... Apply function to all columns (only converts true numeric columns)
  outdata.df <- dplyr::mutate_if(outdata.df, isNumeric, as.numeric)

  ## Return output dataframe
  return(outdata.df)
}
