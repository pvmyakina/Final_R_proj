source("R/00_config.R")

pkgs <- c("pdftools", "tesseract", "stringr", "readr")
for (p in pkgs) if (!requireNamespace(p, quietly=TRUE)) install.packages(p, repos="https://cloud.r-project.org")

library(pdftools)
library(tesseract)
library(stringr)
library(readr)

dir.create(dir_ocr, showWarnings = FALSE, recursive = TRUE)

ocr_one_pdf <- function(pdf_path, out_txt, lang) {
  tmpdir <- tempfile("pdfimg_")
  dir.create(tmpdir)
  on.exit(unlink(tmpdir, recursive = TRUE), add = TRUE)

  out_png <- file.path(tmpdir, "page1.png")

  imgs <- pdftools::pdf_convert(pdf_path, format = "png", dpi = 300, filenames = out_png)

  eng <- tesseract::tesseract(lang)
  txt <- tesseract::ocr(imgs[1], engine = eng)

  readr::write_file(txt, out_txt)
}

pdfs <- list.files(dir_raw, pattern="\\.pdf$", full.names=TRUE)
stopifnot(length(pdfs) >= 10)

for (f in pdfs) {
  id <- tools::file_path_sans_ext(basename(f))
  out <- file.path(dir_ocr, paste0(id, ".txt"))
  message("OCR: ", id)
  ocr_one_pdf(f, out, tess_lang)
}
