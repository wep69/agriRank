\name{agri_graphics}
\alias{agri_theme}
\alias{agri_save_figure}
\title{Journal-oriented graphics: theme and archival export}
\usage{
agri_theme(base_size = 14, legend_position = "right")

agri_save_figure(
  plot,
  file,
  layout = c("custom", "column", "middle", "full"),
  width = NULL,
  height = NULL,
  units = c("cm", "mm", "in"),
  dpi = 300,
  ...
)
}
\arguments{
  \item{base_size}{Base font size in points for the theme.}
  \item{legend_position}{Legend position for the theme.}
  \item{plot}{A \code{ggplot} object, such as those returned by \code{\link{agri_np_plot}}, \code{\link{agri_np_forest}} or \code{\link{agri_plot}}.}
  \item{file}{Output path. The extension selects the format.}
  \item{layout}{Preset width: \code{column} (8.5 cm, one journal column), \code{middle} (11.4 cm) or \code{full} (17.8 cm). \code{custom} uses \code{width} alone.}
  \item{width}{Figure width in \code{units}.}
  \item{height}{Figure height in \code{units}; defaults to three quarters of the width.}
  \item{units}{Size units.}
  \item{dpi}{Resolution for raster devices.}
  \item{...}{Additional arguments passed to \code{ggplot2::ggsave()}.}
}
\description{
\code{agri_theme()} is the common ggplot2 theme of the package: no minor gridlines, drawn axis lines, readable base size and a compact legend. It is applied to the graphics of the regression module and can be added to any other agriRank figure. \code{agri_save_figure()} writes a figure in an archival format with the dimensions journals request.
}
\details{
Every agriRank figure is returned as an editable \code{ggplot} object, so the theme can always be replaced or extended with ordinary ggplot2 layers; nothing is baked into a raster.

For submission, the file extension selects the device: \code{.tif}/\code{.tiff} writes an LZW-compressed TIFF, the most frequently requested submission format; \code{.pdf}, \code{.svg} and \code{.eps} are vector formats that stay editable in Inkscape or Illustrator; \code{.png} and \code{.jpg} are intended for previews. Check the target journal's required dimensions and resolution before submission; the layout presets cover the usual one-column, middle and full-width sizes.
}
\value{
\code{agri_theme()} a ggplot2 theme object; \code{agri_save_figure()} the output path, invisibly.
}
\seealso{\code{\link{agri_np_plot}}, \code{\link{agri_np_forest}}, \code{\link{agri_np_levels}}, \code{\link{agri_plot}}}
\examples{
data(agri_dose)
f <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")
p <- agri_np_plot(f, type = "fit")
p

# Units belong in the axis labels; the figure stays fully editable:
p + ggplot2::labs(x = expression("Nitrogen rate (kg ha"^-1*")"),
                  y = expression("Yield (Mg ha"^-1*")"))

# Archival export at one-column width. For submission prefer TIFF or a
# vector format and the dimensions required by the journal.
file <- agri_save_figure(p, tempfile(fileext = ".png"), layout = "column")
}
