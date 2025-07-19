#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(optparse)
  library(bactofunc)
})

option_list <- list(
  make_option(c("--emu_folder"), type = "character", help = "Path to folder with EMU .tsv files"),
  make_option(c("--ref_file"), type = "character", help = "Path to reference Excel file"),
  make_option(c("--output_folder"), type = "character", help = "Folder to write output Excel files")
)

opt <- parse_args(OptionParser(option_list = option_list))

if (is.null(opt$emu_folder) || is.null(opt$ref_file) || is.null(opt$output_folder)) {
  stop("❌ Please provide --emu_folder, --ref_file, and --output_folder")
}

bactofunc::run_pipeline(opt$emu_folder, opt$ref_file, opt$output_folder)

