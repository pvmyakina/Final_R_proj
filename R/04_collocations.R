source("R/00_config.R")

pkgs <- c("dplyr", "readr", "stringr", "ggplot2", "igraph")
miss <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(miss)) install.packages(miss, repos = "https://cloud.r-project.org")

library(dplyr)
library(readr)
library(stringr)
library(ggplot2)
library(igraph)

dir.create(dir_out_f, showWarnings = FALSE, recursive = TRUE)
dir.create(dir_out_t, showWarnings = FALSE, recursive = TRUE)

anno <- read_csv(file.path(dir_out_t, "udpipe_tokens.csv"), show_col_types = FALSE)

tok <- anno %>%
  filter(!is.na(lemma), upos != "PUNCT") %>%
  mutate(lemma = str_to_lower(lemma)) %>%
  arrange(doc_id, paragraph_id, sentence_id, token_id) %>%
  group_by(doc_id, sentence_id) %>%
  mutate(lemma2 = lead(lemma)) %>%
  ungroup() %>%
  filter(!is.na(lemma2)) %>%
  transmute(w1 = lemma, w2 = lemma2)

b  <- tok %>% count(w1, w2, name = "n")
c1 <- tok %>% count(w1, name = "n1")
c2 <- tok %>% count(w2, name = "n2")

N <- nrow(tok)

coll <- b %>%
  left_join(c1, by = "w1") %>%
  left_join(c2, by = "w2") %>%
  mutate(pmi = log2((n / N) / ((n1 / N) * (n2 / N)))) %>%
  filter(n >= 3) %>%
  arrange(desc(pmi))

write_csv(coll, file.path(dir_out_t, "collocations_pmi.csv"))

top <- coll %>% slice_head(n = 20) %>%
  mutate(pair = paste(w1, w2, sep = " "))

p1 <- ggplot(top, aes(x = reorder(pair, pmi), y = pmi)) +
  geom_col() +
  coord_flip() +
  labs(x = NULL, y = "PMI", title = "Top-20 collocations (PMI)")

ggsave(file.path(dir_out_f, "collocations_bar.png"), p1, width = 10, height = 6)

edges <- coll %>% slice_head(n = 50) %>% select(w1, w2, pmi, n)
g <- graph_from_data_frame(edges, directed = FALSE)

png(file.path(dir_out_f, "collocations_network.png"), width = 1400, height = 1000)
plot(
  g,
  vertex.size = 6,
  vertex.label.cex = 0.8,
  edge.width = 1 + 3 * E(g)$pmi / max(E(g)$pmi),
  main = "Collocations network (top-50 by PMI)"
)
dev.off()
