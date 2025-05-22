#' Download data from the Uppsala Conflict Database Program API.
#'
#' @param dataset character. Name of UCDP dataset. Needs to be one of the following:
#' "ucdpprioconflict", "battledeaths", "dyadic", "nonstate", "onesided" (yearly data),
#' or "gedevents" (daily data, released in monthly batches)
#' The API does not require an account/key but there are some usage limitations
#' For more information, see: https://ucdp.uu.se/apidocs/
#' @param version character. Dataset version number.
#' For yearly UCDP data: Format: YY.1 (e.g. 22.1 for data released in 2022)
#' For monthly UCDP GED data use format: YY.0.MM (e.g. 22.0.11 for data on November 2022)
#' For quarterly UCDP releases data use format: YY.01.YY.MM (e.g. 22.01.22.09 for data from Jan to Sep 2022)
#' @param pagesize numeric. Page size of each individual query. Default: 1000. Max: 1000
#' The UCDP API divides dataset into N pages of size S,
#' the query loops over all pages until full dataset is retrieved.
#' @param max.retries numeric (integer). Maximum number of retry attempts for API
#' calls in case of failure, default: 10. Useful for managing temporary network or server issues.
#' Exceeding max.retries stops the function with an error.
#' @param add.metadata boolean: Add metadata to output dataset (TRUE) or not (FALSE).
#' Default: TRUE
#'
#' @return data.frame with requested UCDP dataset
#' @export
#'
#' @importFrom httr GET content
#' @importFrom dplyr bind_rows mutate_if
#' @importFrom stats ave setNames
#' @importFrom utils txtProgressBar setTxtProgressBar
#'
#' @examples
#' getUcdpData(dataset = ucdpprioconflict, version = "22.1", pagesize = 100)
getUcdpData <- function(dataset, version, pagesize = 1000, max.retries = 10, add.metadata = TRUE) {
  if(pagesize > 1000) {
    stop("Page size cannot exceed 1000")
  }

  ## Validate dataset name
  dataset.names <- c("ucdpprioconflict", "battledeaths", "dyadic", "nonstate", "onesided", "gedevents")
  if(!dataset %in% dataset.names) {
    stop(sprintf("Invalid dataset name. Please choose one of the following datasets:\n%s.",
                 paste(sprintf("'%s'", dataset.names), collapse = ", ")))
  }

  ## Build initial URL
  url <- sprintf("https://ucdpapi.pcr.uu.se/api/%s/%s?pagesize=%s", dataset, version, pagesize)
  message(sprintf("Checking if dataset '%s' %s exists...", dataset, version))

  ## Function to perform the GET request with retry logic
  safeGET <- function(url, max.retries) {
    attempt <- 1
    repeat {
      tryCatch({
        response <- httr::GET(url)
        if(httr::status_code(response) == 200) {
          return(httr::content(response, encoding = "UTF-8"))
        } else {
          stop("Server returned error: ", httr::status_code(response))
        }
      }, error = function(e) {
        if(attempt >= max.retries) {
          stop("Failed to retrieve data after ", attempt, " attempts. Error: ", e$message)
        } else {
          message(sprintf("Attempt %d failed, retrying...", attempt))
          attempt <- attempt + 1
          Sys.sleep(5) # Wait before retrying
        }
      })
    }
  }

  ## Initial query
  query.ls <- safeGET(url, max.retries)
  n.pages <- query.ls$TotalPages

  message(sprintf("Getting UCDP '%s' dataset, Version %s...", dataset, version))

  ## Create list to store output data in
  output.ls <- vector("list", length = n.pages)
  output.ls[[1]] <- query.ls$Result
  next.url <- query.ls$NextPageUrl

  ## Initialize progress bar
  pb <- txtProgressBar(min = 1, max = n.pages, style = 3)
  setTxtProgressBar(pb, 1) # Set progress for the first page

  ## Loop over remaining pages and query data
  for(i in 2:length(output.ls)) {
    if(next.url != "") {
      query.ls <- safeGET(next.url, max.retries)
      output.ls[[i]] <- query.ls$Result
      next.url <- query.ls$NextPageUrl
      setTxtProgressBar(pb, i) # Update progress bar
    }
  }
  close(pb) # Close the progress bar after the loop

  ## Bind rows
  output.df <- dplyr::bind_rows(output.ls)

  ## Make sure the query returned the full dataset
  if(nrow(output.df) != query.ls$TotalCount) {
    warning(sprintf("Query did not return full number of records!\nExpected: %s.\nReceived: %s",
                    query.ls$TotalCount, nrow(output.df)))
  }

  ## Convert numeric columns
  isNumeric <- function(x) all(suppressWarnings(!is.na(as.numeric(x))))
  output.df <- dplyr::mutate_if(output.df, isNumeric, as.numeric)

  ## Add metadata if required
  if(add.metadata) {
    output.df$dataset <- dataset
    output.df$version <- version
    output.df$download_date <- Sys.Date()
  }
  message("Done.")
return(output.df)
}
