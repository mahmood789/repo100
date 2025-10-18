# roxygen namespace imports & global vars
#' @importFrom yaml read_yaml write_yaml
#' @importFrom tibble as_tibble
#' @importFrom dplyr filter arrange desc bind_rows
#' @importFrom stats model.frame model.matrix complete.cases
#' @importFrom utils data head

utils::globalVariables(c(
  'yi','vi','sei','ai','bi','ci','di','tpos','tneg','cpos','cneg',
  'm1i','m2i','sd1i','sd2i','n1i','n2i',
  'event.e','event.c','events.e','events.c','n.e','n.c','e1','e0','N1','N0',
  'id','title','k','n_mods'
))
