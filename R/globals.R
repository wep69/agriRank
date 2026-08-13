# Column names used inside ggplot2 aesthetics are evaluated in the data mask,
# not in the package namespace. Declaring them keeps `R CMD check` accurate
# about which symbols are genuinely undefined.
utils::globalVariables(c(
  ".a", ".b", ".cell", ".label", ".median", ".y",
  "contrast", "derivative", "difference", "estimate", "fit", "fitted",
  "lower", "median", "missing_rate", "n", "occasion", "residual", "status",
  "relative_marginal_effect",
  "to", "upper", "x", "x1", "x2", "y"
))
