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

  ## Compute data coverage (data.sdate, data.edate) for each version.
  ##
  ## Coverage rules:
  ##   Yearly   X.1       : 1989-01-01 to Dec 31 of year (2000+X-1)
  ##                        e.g. 25.1 -> 1989-01-01 to 2024-12-31
  ##   Monthly  X.0.M      : first to last day of month M in year (2000+X)
  ##                        e.g. 25.0.1 -> 2025-01-01 to 2025-01-31
  ##   Quarterly X.01.X.M  : Jan 1 to last day of month M in year (2000+X)
  ##                        e.g. 25.01.25.09 -> 2025-01-01 to 2025-09-30
  coverageDates <- function(update, version) {
    yy <- as.numeric(substr(version, 1, 2))
    if (update == "yearly") {
      sdate <- as.Date("1989-01-01")
      edate <- as.Date(sprintf("%04d-12-31", 2000 + yy - 1))
    } else if (update == "monthly") {
      mm <- as.numeric(sub(".*\\.", "", version))
      sdate <- as.Date(sprintf("%04d-%02d-01", 2000 + yy, mm))
      edate <- seq(sdate, by = "1 month", length.out = 2)[2] - 1
    } else if (update == "quarterly") {
      mm <- as.numeric(sub(".*\\.", "", version))
      sdate <- as.Date(sprintf("%04d-01-01", 2000 + yy))
      first.of.month <- as.Date(sprintf("%04d-%02d-01", 2000 + yy, mm))
      edate <- seq(first.of.month, by = "1 month", length.out = 2)[2] - 1
    } else {
      stop("Unsupported version type.")
    }
    list(sdate = sdate, edate = edate)
  }

  cov.list <- mapply(coverageDates,
                     version.df$update,
                     version.df$version,
                     SIMPLIFY = FALSE)
  version.df$data.sdate <- as.Date(sapply(cov.list, function(x) as.character(x$sdate)))
  version.df$data.edate <- as.Date(sapply(cov.list, function(x) as.character(x$edate)))

  ## Exclude future datasets: drop any dataset whose coverage end is on or after
  ## the first day of the reference date's month (i.e. not yet complete).
  version.df <- version.df[version.df$data.edate < as.Date(format(date, "%Y-%m-01")), ]

  ## For remaining datasets, ping API to see if they exist
  version.df$exists <- sapply(version.df$version, function(v) {
    checkUcdpAvailable(
      dataset = "gedevents",
      version = v,
      token = token,
      as.vector = TRUE
    )
  })

  ## If no datasets are available, return informative error
  if (all(!version.df$exists)) {
    stop(sprintf(
      "No UCDP GED datasets found. Request failed with status codes: %s",
      paste(sort(unique(version.df$status)), collapse = ", ")
    ))
  }

  ## Retain only available datasets
  keep.version.df <- version.df[version.df$exists == TRUE, ]
  keep.version.df$type <- ifelse(keep.version.df$update == "yearly", "final", "candidate")
  keep.version.df$dataset <- "gedevents"

  ## Yearly: keep the latest final release (the one with the latest data.edate)
  yr.df <- keep.version.df[keep.version.df$update == "yearly", ]
  keep.yr.df <- yr.df[yr.df$data.edate == max(yr.df$data.edate), ]
  yearly.edate <- max(yr.df$data.edate)

  ## Quarterly: keep only quarterlies whose coverage extends past the yearly.
  ## Among those, keep only the latest quarterly per calendar year (largest
  ## data.edate). This ensures e.g. 25.01.25.12 is retained even when
  ## 26.01.26.03 also exists.
  q.df <- keep.version.df[keep.version.df$update == "quarterly" &
                            keep.version.df$data.edate > yearly.edate, ]
  if (nrow(q.df) > 0) {
    q.df$cov.yr <- as.numeric(format(q.df$data.edate, "%Y"))
    keep.q.df <- do.call(rbind, lapply(split(q.df, q.df$cov.yr),
                                       function(d) d[which.max(d$data.edate), , drop = FALSE]))
    keep.q.df$cov.yr <- NULL
  } else {
    keep.q.df <- q.df
  }

  ## Monthly: keep only monthlies whose coverage extends past the latest kept
  ## quarterly (or past the yearly if no quarterlies kept).
  cutoff.edate <- if (nrow(keep.q.df) > 0) max(keep.q.df$data.edate) else yearly.edate
  keep.m.df <- keep.version.df[keep.version.df$update == "monthly" &
                                 keep.version.df$data.edate > cutoff.edate, ]

  ## Return final result
  version.out.df <- unique(rbind(keep.yr.df, keep.q.df, keep.m.df))
  return(version.out.df)
}

