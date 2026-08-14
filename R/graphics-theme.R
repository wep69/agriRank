# Journal-oriented graphics helpers ------------------------------------------
#
# Every agriRank figure is an editable ggplot and every table a data frame.
# These helpers standardize the visual finish for submission: a common theme
# with the sizes journals expect, a colour-blind-safe palette, and an export
# function that writes the archival formats (TIFF, PDF, SVG, EPS) at the
# dimensions journals ask for, instead of leaving each author to rediscover
# ggsave options.

# Okabe-Ito, the classical colour-blind-safe qualitative palette. Grey ramps
# are offered for outlets that print in black and white; there the groups are
# also separated by point shape and line type, never by tone alone.
.np_okabe_ito <- c("#E69F00", "#56B4E9", "#009E73", "#F0E442",
                   "#0072B2", "#D55E00", "#CC79A7", "#999999")

.np_discrete_palette <- function(n, palette = c("color", "grey")) {
  palette <- match.arg(palette)
  n <- max(1L, as.integer(n))
  if (identical(palette, "grey"))
    return(grDevices::grey(seq(0.05, 0.75, length.out = max(2L, n))))
  if (n <= length(.np_okabe_ito)) return(.np_okabe_ito[seq_len(n)])
  grDevices::hcl(h = seq(15, 375, length.out = n), c = 60, l = 65)
}

#' Graphical theme for agriRank figures
#'
#' @description
#' A clean ggplot2 theme intended for journal figures: no minor gridlines,
#' drawn axis lines, readable base size, and a compact legend. It is applied
#' to the graphics produced by the regression module and can be added to any
#' other agriRank ggplot. Because figures are returned as ggplot objects, the
#' theme can always be replaced or extended with ordinary ggplot2 layers.
#' @param base_size Base font size in points. Most journals require axis
#'   labels of at least 8 points after scaling; 14 points at column width is a
#'   safe starting value.
#' @param legend_position Legend position passed to the theme.
#' @return A ggplot2 theme object.
#' @examples
#' data(agri_dose)
#' f <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")
#' p <- agri_np_plot(f, type = "fit")
#' # The default finish:
#' p
#' # Any ggplot2 layer can still be added on top:
#' p + ggplot2::labs(x = expression("Nitrogen rate (kg ha"^-1*")"),
#'                   y = expression("Yield (Mg ha"^-1*")"))
#' @export
agri_theme <- function(base_size = 14, legend_position = "right") {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(colour = "grey92", linewidth = 0.3),
      axis.line = ggplot2::element_line(colour = "grey30", linewidth = 0.4),
      strip.text = ggplot2::element_text(face = "bold", colour = "grey15"),
      legend.position = legend_position,
      legend.background = ggplot2::element_blank(),
      plot.subtitle = ggplot2::element_text(size = ggplot2::rel(0.82), colour = "grey30")
    )
}

#' Save an agriRank figure in journal-ready formats
#'
#' @description
#' Writes a ggplot to an archival figure format with the dimensions journals
#' request. The file extension selects the device: `.tif`/`.tiff` (LZW
#' compressed, the usual submission format), `.pdf`, `.svg` and `.eps`
#' (vector, editable in Inkscape or Illustrator), or `.png`/`.jpg` for
#' previews. Vector formats preserve editability of text and lines.
#' @param plot A ggplot object, such as those returned by `agri_np_plot()`,
#'   `agri_np_forest()` or `agri_plot()`.
#' @param file Output path. The extension selects the format.
#' @param layout Preset width: `column` (8.5 cm, one journal column),
#'   `middle` (11.4 cm) or `full` (17.8 cm, full page width). `custom` uses
#'   `width` alone.
#' @param width Figure width in `units`. Defaults to full width when `layout`
#'   is `custom` and no width is given.
#' @param height Figure height in `units`; defaults to three quarters of the
#'   width.
#' @param units Size units.
#' @param dpi Resolution for raster devices.
#' @param ... Additional arguments passed to `ggplot2::ggsave()`.
#' @return The output path, invisibly.
#' @examples
#' data(agri_dose)
#' f <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")
#' p <- agri_np_plot(f, type = "fit")
#' file <- agri_save_figure(p, tempfile(fileext = ".png"), layout = "column")
#' # For submission, prefer a vector or TIFF target such as "figure1.tif" or
#' # "figure1.pdf" and check the journal's required dimensions and dpi.
#' @export
agri_save_figure <- function(plot, file,
                             layout = c("custom", "column", "middle", "full"),
                             width = NULL, height = NULL,
                             units = c("cm", "mm", "in"), dpi = 300, ...) {
  if (!inherits(plot, "ggplot"))
    .agri_stop("`plot` must be a ggplot object, such as those returned by agri_np_plot(), agri_np_forest() or agri_plot().")
  layout <- match.arg(layout)
  units <- match.arg(units)
  preset_cm <- switch(layout, column = 8.5, middle = 11.4, full = 17.8, custom = NULL)
  if (!is.null(preset_cm)) {
    width <- switch(units, cm = preset_cm, mm = preset_cm * 10, `in` = preset_cm / 2.54)
  }
  if (is.null(width)) width <- switch(units, cm = 17.8, mm = 178, `in` = 7)
  if (!is.finite(width) || width <= 0) .agri_stop("`width` must be a positive number.")
  if (is.null(height)) height <- width * 0.75
  if (!is.finite(height) || height <= 0) .agri_stop("`height` must be a positive number.")
  ext <- tolower(sub("^.*\\.", "", basename(file)))
  if (ext == tolower(basename(file)) ||
      !ext %in% c("tif", "tiff", "pdf", "svg", "eps", "png", "jpg", "jpeg"))
    .agri_stop("Unsupported figure format `.", ext, "`. Journals typically accept TIFF, EPS, PDF or SVG; use one of those so the figure stays editable.")
  if (ext %in% c("tif", "tiff")) {
    # LZW-compressed TIFF is the most frequently requested submission format;
    # write it through the grDevices device directly so the compression is
    # guaranteed regardless of which graphics backend ggsave would select.
    grDevices::tiff(file, width = width, height = height, units = units,
                    res = dpi, compression = "lzw")
    on.exit(grDevices::dev.off(), add = TRUE)
    print(plot)
  } else {
    ggplot2::ggsave(file, plot = plot, width = width, height = height,
                    units = units, dpi = dpi, ...)
  }
  invisible(file)
}
