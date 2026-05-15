#' Conservation land correction fractions for NPS/MS4 allocation assessment
#'
#' @format A data frame with one row per unique bay segment, basin, entity, and
#'   CLUCSID combination where conservation land is present:
#' \describe{
#'   \item{bay_seg}{Integer bay segment identifier (1 = OTB, 2 = HB, 3 = MTB,
#'     4 = LTB, 55 = RALTB).}
#'   \item{basin}{Character drainage basin identifier.}
#'   \item{entity}{MS4 jurisdiction name.}
#'   \item{clucsid}{Integer Coastal Land Use Classification System identifier.}
#'   \item{conserv_frac}{Fraction of entity area x runoff-coefficient
#'     attributable to conservation land within that bay segment / basin /
#'     CLUCSID combination. Computed as conservation area x RC divided by
#'     total entity area x RC (conservation + non-conservation) for that group.}
#' }
#'
#' @details
#' The tbeploads-built \code{\link{tbbase}} is derived from routinely updated
#' GIS sources (land use, soils, jurisdictions) and does not include a
#' conservation land spatial overlay.  The conservation layer was available 
#' only for prior SAS workflows and cannot reproduced.
#' 
#' \code{conserv_correction} provides entity-specific fractions derived from
#' the SAS land cover file (\code{npsag_3_2224_25Sep25.sas7bdat}), which
#' includes a binary \code{conservation} column (0/1) indicating conservation
#' land while retaining the original MS4 jurisdiction in \code{entity}. Within
#' \code{\link{anlz_aa}}, each MS4 entity's disaggregated TN load for a given
#' basin and CLUCSID is scaled by \code{(1 - conserv_frac)} to remove the
#' conservation land contribution before hydrologic normalization.
#'
#' Preprocessing matches \code{\link{util_aa_npsfactors}}: non-contributing
#' drainage (\code{drnfeat = "NONCON"}) and water / tidal CLUCSIDs (17, 21, 22)
#' are excluded, compound hydrologic soil groups are simplified, and nested basins
#' are remapped. Only entity, basin, CLUCSID combinations with
#' \code{conserv_frac > 0} are retained.
#'
#' @source Derived from \code{data-raw/npsag_3_2224_25Sep25.sas7bdat}, the SAS
#'  NPS land cover file. Built by \code{data-raw/conserv_correction.R}.
#'
#' @seealso \code{\link{anlz_aa}}, \code{\link{tbbase}},
#'   \code{\link{util_aa_npsfactors}}
"conserv_correction"
