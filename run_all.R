# Reproduce everything. Run from the repository root:  Rscript run_all.R
# First run downloads the raw C5 file (~100 MB) and builds the small CSVs in chapters/datos/.
# Needs: readr, dplyr, tidyr, ggplot2, MASS, knitr, rmarkdown, and Quarto for the landing page.
setwd("chapters")
if (!file.exists("datos/atropellamientos_cdmx.csv")) source("0-datos-atropellamientos.R")
for (f in sort(list.files(pattern = "^[0-6]-.*\.Rmd$"))) {
  rmarkdown::render(f, output_dir = "../docs/chapters", envir = new.env(), quiet = TRUE)
}
setwd("..")
system2("quarto", c("render", "index.qmd"))
