.onLoad <- function(libname, pkgname) {
  # broom is a suggestion. Registering its generics here, rather than declaring
  # S3method(tidy, agri_np_reg_fit) in NAMESPACE, keeps the package usable when
  # broom is absent while still supplying the methods when it is present.
  .agri_register_broom()
  invisible()
}
