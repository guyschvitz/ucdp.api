#' Get version IDs of latest available UCDP GED datasets.
#'
#' This function retrieves version IDs of the latest available UCDP GED datasets.
#' It fetches the version IDs required to download the full UCDP GED data (final and candidate),
#' covering January 1989 until the latest available update, or up until a
#' user-defined reference date.
#'
#' @param date Date object defining the reference point for available updates.
#' Defaults to the system date.
#' @param token character. UCDP API access token. Required for authentication.
#' Obtain a token from the UCDP API portal: https://ucdp.uu.se/apidocs/
#' @return A data.frame with the latest available dataset versions.
#' @export
#'
#' @examples
#' \dontrun{
#' getLatestUcdpGedVersionIds(
#'   date = as.Date("2024-06-15"),
#'   token = Sys.getenv("UCDP_TOKEN")
#' )
#' }
getLatestUcdpGedVersionIds <- function(date = Sys.Date(), token) {

  ## Validate token
  if (missing(token) || !is.character(token) || nchar(token) == 0) {
    stop("A valid API access token is required. Obtain one at https://ucdp.uu.se/apidocs/")
  }

  ## Extract year and month from date
  date <- as.Date(date)
  yr <- as.numeric(format(date, "%y"))
  mon <- as.numeric(format(date, "%m"))
  yrs <- c(yr, yr - 1)

  ## Function to create GED version names according to UCDP naming convention
  getVersionNames <- function(yrs, type) {
    out <- character()
    if (type == "yearly") {
      out <- sprintf("%s.1", yrs)
      v.name <- setNames(out, rep("yearly", length(out)))
    } else if (type == "monthly") {
      for (y in yrs) {
        out <- c(out, sprintf("%s.0.%s", y, 1:12))
      }
      v.name <- setNames(out, rep("monthly", length(out)))
    } else if (type == "quarterly") {
      for (y in yrs) {
        out <- c(out, sprintf("%s.01.%s.%s", y, y, sprintf("%02d", 1:12)))
      }
      v.name <- setNames(out, rep("quarterly", length(out)))
    } else {
      stop("Unsupported version type.")
    }
    return(v.name)
  }

  ## Get vector of all possible yearly, monthly, quarterly version names
  version.vec <- c(
    getVersionNames(yrs = yrs, type = "yearly"),
    getVersionNames(yrs = yrs, type = "quarterly"),
    getVersionNames(yrs = yrs, type = "monthly")
  )

  ## Compile in data.frame
  version.df <- data.frame(
    update = names(version.vec),
    version = unname(version.vec),
    stringsAsFactors = FALSE
  )

  ## Add dataset year, month, and reference date
  version.df$yr <- as.numeric(substr(version.df$version, 1, 2))
  version.df$mon <- as.numeric(sub(".*\\.", "", version.df$version))
  version.df$ref_date <- as.Date(sprintf("20%02d-%02d-01", version.df$yr, version.df$mon))

  ## Exclude future datasets: only keep datasets with ref_date before the first day of the current month
  version.df <- version.df[version.df$ref_date < as.Date(format(date, "%Y-%m-01")), ]

  ## For remaining datasets, ping API to see if they exist
  version.check.df <- do.call(rbind, lapply(version.df$version, function(v) {
    checkUcdpAvailable(
      dataset = "gedevents",
      version = v,
      token = token,
      as.vector = FALSE
    )
  }))

  ## If no datasets are available, return informative error
  if (all(!version.check.df$exists)) {
    stop(sprintf(
      "No UCDP GED datasets found. Request failed with status codes: %s",
      paste(sort(unique(version.check.df$status)), collapse = ", ")
    ))
  }

  ## Merge original version list with availability results
  keep.version.df <- merge(version.df, version.check.df, by = "version")
  keep.version.df <- keep.version.df[keep.version.df$exists == TRUE, ]
  keep.version.df$type <- ifelse(keep.version.df$update == "yearly", "final", "candidate")
  keep.version.df$dataset <- "gedevents"

  ## Retain only the latest yearly, quarterly, and monthly versions
  keep.yr.df <- keep.version.df[keep.version.df$update == "yearly" &
                                  keep.version.df$yr == max(keep.version.df$yr), ]

  keep.q.df <- keep.version.df[keep.version.df$update == "quarterly" &
                                 keep.version.df$yr == max(keep.version.df$yr), ]
  if (nrow(keep.q.df) > 0) {
    keep.q.df <- keep.q.df[keep.q.df$mon == max(keep.q.df$mon), ]
  }

  keep.m.df <- keep.version.df[keep.version.df$update == "monthly" &
                                 keep.version.df$yr >= max(keep.version.df$yr), ]
  if (nrow(keep.q.df) > 0) {
    keep.m.df <- keep.m.df[keep.m.df$ref_date > max(keep.q.df$ref_date), ]
  }

  ## Return final result
  version.out.df <- unique(rbind(keep.yr.df, keep.q.df, keep.m.df))
  return(version.out.df)
}
