#' getLatestUcdpGedVersionIds: Get version IDs of latest available UCDP GED datasets.
#'
#' This function retrieves version IDs of the latest available UCDP GED datasets.
#' It fetches the version IDs required to download the full UCDP GED data (final and candidate),
#' covering January 1989 until the latest available update, or up until a
#' user-defined reference date.
#'
#' @param date Date object defining the reference point for available updates.
#' Defaults to the system date.
#' @return A data.frame with the latest available dataset versions.
#' @export
getLatestUcdpGedVersionIds <- function(date = Sys.Date()) {

  ## Extract year and month from date
  date <- as.Date(date)
  yr <- as.numeric(format(date, "%y"))
  mon <- as.numeric(format(date, "%m"))
  yrs <- c(yr, yr - 1)

  ## Function to create GED version names according to UCDP naming convention
  getVersionNames <- function(yrs, type) {
    if (type == "yearly") {
      ## ... Yearly dataset versions
      v.name <- setNames(sprintf("%s.1", yrs), rep("yearly", length(yrs)))
    } else if (type == "monthly") {
      ## ... Monthly dataset versions
      out <- character()
      for (y in yrs) {
        out <- c(out, sprintf("%s.0.%s", y, 1:12))
      }
      v.name <- setNames(out, rep("monthly", length(out)))
    } else if (type == "quarterly") {
      ## ... Quarterly dataset versions
      out <- character()
      for (y in yrs) {
        out <- c(out, sprintf("%s.01.%s.%s", y, y, sprintf("%02d", 1:12)))
      }
      v.name <- setNames(out, rep("quarterly", length(out)))
    } else {
      stop("Unsupported version type.")
    }
    return(v.name)
  }

  ## Get vector of all possible yearly, monthly, quarterly version names for the
  ## current and previous year (defined by 'date')
  version.vec <- c(
    getVersionNames(yrs, "yearly"),
    getVersionNames(yrs, "quarterly"),
    getVersionNames(yrs, "monthly")
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
    return(checkUcdpAvailable("gedevents", v, as.vector = FALSE))
  }))

  ## If all requests fail, return error message
  if (all(!version.check.df$exists)) {
    msg <- sprintf(
      "Request failed with status codes: %s",
      paste(sort(unique(version.check.df$status)), collapse = ", ")
    )
    stop(msg)
  }

  ## Merge original version data.frame with results, keep only datasets that exist
  keep.version.df <- merge(version.df, version.check.df, by = "version")
  keep.version.df <- keep.version.df[keep.version.df$exists == TRUE, ]
  keep.version.df$type <- ifelse(keep.version.df$update == "yearly", "final", "candidate")
  keep.version.df$dataset <- "gedevents"

  ## Ensure that only the latest yearly, quarterly and monthly datasets are kept
  ## to avoid overlaps / duplicate data
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

  ## Return final output dataset
  version.out.df <- unique(rbind(keep.yr.df, keep.q.df, keep.m.df))
  return(version.out.df)
}
