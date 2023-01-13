#' pingUrl: Check if URL is valid and can be accessed
#'
#' @param url character. URL of website to be accessed
#'
#' @return error message if URL cannot be accessed
#' @export
#'
#' @examples
#' pingUrl("https://www.google.com/") ## Works, no error
#' pingUrl("https://www.goooogle.com/") ## Will not work, results in error
#'
pingUrl <- function(url){

  ## Check URL
  url.ping <- tryCatch(
    httr::GET(url),
    error = function(e){e})

  ## Return error if class of 'url.ping' is error or if status_code 400:504
  if(any(class(url.ping) == "error") |
     url.ping$status_code %in% 400:504) {
    error_code <- url.ping$status_code
    stop(sprintf("The resource %s cannot be reached. Error code: %s \n
    1. Please check your internet connection and/or proxy settings.
    2. Check if your URL or query contains any errors.
    3. If there are no problems with your internet connection and your query is correct, the server may be temporarily unavailable; in this case please try again later.
    4. If the problem persists, please contact the package maintainer as the resource may have moved.", url, error_code))
  }
}
