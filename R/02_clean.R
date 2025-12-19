source("R/00_config.R")

pkgs <- c("stringr", "readr", "purrr")
miss <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(miss)) install.packages(miss, repos = "https://cloud.r-project.org")

library(stringr)
library(readr)
library(purrr)

dir.create(dir_clean, showWarnings = FALSE, recursive = TRUE)

clean_text <- function(x) {
  x <- str_replace_all(x, "\r\n?", "\n")

  x <- str_replace_all(x, "(\\p{L})-\\s*\\n\\s*(\\p{L})", "\\1\\2")

  x <- str_replace_all(x, "[•■◦]", " ")

  x <- str_replace_all(x, "[ \t]+\\n", "\n")
  x <- str_replace_all(x, "\\n[ \t]+", "\n")

  x <- str_replace_all(x, "\n{3,}", "\n\n")

  x <- str_replace_all(x, "[ ]{2,}", " ")

  str_trim(x)
}

txts <- list.files(dir_ocr, pattern = "\\.txt$", full.names = TRUE)
stopifnot(length(txts) >= 10)

walk(txts, function(f) {
  id <- tools::file_path_sans_ext(basename(f))
  x <- read_file(f)
  y <- clean_text(x)
  write_file(y, file.path(dir_clean, paste0(id, ".txt")))
})
