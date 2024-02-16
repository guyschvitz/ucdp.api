#' getUcdpData: Download data from the Uppsala Conflict Database Program API.
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
#' @param pagesize numeric. Page size of each individual query. Default: 100. Max: 1000
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
#'
#' @examples
#' getUcdpData(dataset = ucdpprioconflict, version = "22.1", pagesize = 100)
#' getUcdpData(dataset = gedevents, version = "22.1", pagesize = 100)
getUcdpData <- function(dataset, version, pagesize = 100, max.retries = 10,
                        add.metadata = TRUE) {

  if(pagesize > 1000) {
    stop("Page size cannot exceed 1000")
  }

  ## Validate dataset name
  dataset.names <- c("ucdpprioconflict", "battledeaths", "dyadic", "nonstate",
                     "onesided", "gedevents")

  if(!dataset %in% dataset.names) {
    stop(sprintf("Invalid dataset name. Please choose one of the following datasets:\n%s.",
         paste(sprintf("'%s'", dataset.names), collapse = ", ")))
  }

  ## Build initial URL
  url <- sprintf("https://ucdpapi.pcr.uu.se/api/%s/%s?pagesize=%s",
                 dataset, version, pagesize)

  message(sprintf("Checking if dataset '%s' %s exists...", dataset, version))

  ## Attempt initial download with retries
  attempt <- 1
  while(attempt <= max.retries) {
    tryCatch({
      response <- httr::GET(url)
      content.ls <- httr::content(response, encoding = "UTF-8")
      break # Exit loop on success
    }, error = function(e) {
      if(attempt == max.retries) {
        stop("Failed to retrieve data after ", attempt, " attempts.")
      }
      attempt <- attempt + 1
      Sys.sleep(5) # Wait before retrying
    })
  }

  if(!is.list(content.ls)){
    stop(content.ls)
  }

  ## Initialize list and define number of pages with first page results
  pages <- content.ls$TotalPages
  outdata.ls <- list(content.ls$Result)

  message(sprintf("\nGetting UCDP '%s' dataset, Version %s...", dataset, version))
  ## Initialize progress bar
  pb <- txtProgressBar(min = 0, max = pages, style = 3)

  ## Loop over pages and handle retries
  for(page in 2:pages) {
    ## ... Reset attempt counter for each page
    attempt <- 1
    while(attempt <= max.retries) {
      tryCatch({
        nxt.url <- sprintf("%s&page=%s", url, page)
        ## ... Send query and fetch results
        response <- httr::GET(nxt.url)
        content.ls <- httr::content(response, encoding = "UTF-8")
        ## ... Append results
        outdata.ls[[page]] <- content.ls$Result
        ## ... Update progress bar
        setTxtProgressBar(pb, page)
        ## ... Exit loop on success
        break
      }, error = function(e) {
        if(attempt == max.retries) {
          ## ... Close progress bar on final attempt
          close(pb)
          stop("Failed to retrieve page ", page, " after ",
               attempt, " attempts.")
        }
        attempt <- attempt + 1
        ## ... Wait before retrying
        Sys.sleep(3)
      })
    }
  }
  close(pb)

  ## Process and return the data
  outdata.df <- dplyr::bind_rows(lapply(outdata.ls, dplyr::bind_rows))

  ## Convert numeric columns
  isNumeric <- function(x) {
    all(suppressWarnings(!is.na(as.numeric(na.omit(x)))))
  }
  outdata.df <- dplyr::mutate_if(outdata.df, isNumeric, as.numeric)

  ## Add metadata if metadata == TRUE
  if(add.metadata == TRUE){
    outdata.df$dataset <- dataset
    outdata.df$version <- version
    outdata.df$download_date <- Sys.Date()
  }

  message("Done.")

  return(outdata.df)
}
