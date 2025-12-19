source("R/00_config.R")

pkgs <- c("udpipe", "dplyr", "readr", "stringr", "purrr")
miss <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(miss)) install.packages(miss, repos = "https://cloud.r-project.org")

library(udpipe)
library(dplyr)
library(readr)
library(stringr)
library(purrr)

dir.create(dir_out_t, showWarnings = FALSE, recursive = TRUE)

m <- udpipe_download_model(language = ud_lang)
udm <- udpipe_load_model(m$file_model)

files <- list.files(dir_clean, pattern = "\\.txt$", full.names = TRUE)
stopifnot(length(files) >= 10)

texts <- map_chr(files, read_file)
ids   <- tools::file_path_sans_ext(basename(files))

anno <- udpipe_annotate(udm, x = texts, doc_id = ids)
anno <- as.data.frame(anno)

write_csv(anno, file.path(dir_out_t, "udpipe_tokens.csv"))

freq_total <- anno %>%
  filter(!is.na<lemma), upos != "PUNCT") %>%
  mutate(lemma = str_to_lower<lemma)) %>%
  count(lemma, sort = TRUE)

write_csv(freq_total, file.path(dir_out_t, "lemma_freq_total.csv"))
write_csv(freq_total %>% slice_head(n = 50),
          file.path(dir_out_t, "lemma_freq_top50.csv"))

freq_by_doc <- anno %>%
  filter(!is.na<lemma), upos != "PUNCT") %>%
  mutate(lemma = str_to_lower<lemma)) %>%
  count(doc_id, lemma, sort = TRUE) %>%
  group_by(doc_id) %>%
  slice_head(n = 20) %>%
  ungroup()

write_csv(freq_by_doc, file.path(dir_out_t, "lemma_freq_by_doc_top20.csv"))
