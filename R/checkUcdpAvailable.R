#' checkUcdpAvailable: Check which UCDP datasets are currently available through the API.
#'
#' @param dataset character. Name of UCDP dataset. Needs to be one of the following:
#' "ucdpprioconflict", "battledeaths", "dyadic", "nonstate", "onesided" (yearly data),
#' or "gedevents" (daily data, released in monthly batches)
#' For more information, see: https://ucdp.uu.se/apidocs/
#' @param version character. Dataset version number.
#' For yearly UCDP data: Format: YY.1 (e.g. 22.1 for data released in 2022)
#' For monthly UCDP GED data use format: YY.0.MM (e.g. 22.0.11 for data on November 2022)
#' For quarterly UCDP releases data use format: YY.01.YY.MM
#' (e.g. 22.01.22.09 for data from Jan to Sep 2022)
#' @param token character. UCDP API access token. Required for authentication.
#' Obtain a token from the UCDP API portal: https://ucdp.uu.se/apidocs/
#' @param as.vector boolean: Return output as multi-column data.frame (FALSE) or
#' as simple vector (TRUE)? Default: FALSE
#'
#' @return data.frame with dataset name, version, HTTP status, and availability flag,
#' or a logical scalar if as.vector = TRUE
#' @export
#'
#' @importFrom httr GET add_headers content status_code
#'
#' @examples
#' \dontrun{
#' ## Check which monthly UCDP GED candidate datasets are available
#' m.ids <- 1:12
#' gedc.m.check.df <- do.call(rbind, lapply(m.ids, function(x) {
#'   checkUcdpAvailable(
#'     dataset = "gedevents",
#'     version = sprintf("22.0.%s", x),
#'     token = Sys.getenv("UCDP_TOKEN")
#'   )
#' }))
#' }
checkUcdpAvailable <- function(dataset, version, token, as.vector = FALSE) {

  ## Validate token
  if (missing(token) || !is.character(token) || nchar(token) == 0) {
    stop("A valid API access token is required. Obtain one at https://ucdp.uu.se/apidocs/")
  }

  ## Validate dataset name
  dataset.names <- c(
    "ucdpprioconflict", "battledeaths", "dyadic",
    "nonstate", "onesided", "gedevents"
  )
  if (!dataset %in% dataset.names) {
    stop(sprintf(
      "Invalid dataset name. Please choose one of the following datasets:\n%s.",
      paste(sprintf("'%s'", dataset.names), collapse = ", ")
    ))
  }

  ## Build initial URL: Insert dataset and version number
  url <- sprintf(
    "https://ucdpapi.pcr.uu.se/api/%s/%s?pagesize=1",
    dataset, version
  )

  ## Ping URL
  url.ping <- tryCatch(
    httr::GET(
      url,
      httr::add_headers("x-ucdp-access-token" = token)
    ),
    error = function(e) { e }
  )

  ## Check if query returns an error or not
  if (inherits(url.ping, "error") || httr::status_code(url.ping) %in% 400:504) {
    exists <- FALSE
    status.code <- if (inherits(url.ping, "error")) NA_integer_ else httr::status_code(url.ping)
  } else {
    status.code <- httr::status_code(url.ping)
    content.ls <- httr::content(url.ping, encoding = "UTF-8")
    exists <- content.ls$TotalPages > 0
  }

  ## Return result
  if (as.vector) {
    return(exists)
  }

  out.df <- data.frame(
    dataset = dataset,
    version = version,
    status = status.code,
    exists = exists
  )
  return(out.df)
}
