# === Load Required Libraries ===
library(readr)
library(readxl)
library(dplyr)
library(tidyr)
library(writexl)
library(stringr)
library(tools)
library(magrittr)

# Define pipe and read_excel globally to ensure they're available
`%>%` <- magrittr::`%>%`
read_excel <- readxl::read_excel

#' Run Bacterial Functional Group Analysis
#'
#' This function reads EMU `.tsv` files, matches species/genus with reference functions,
#' and writes detailed summaries to Excel.
#'
#' @param emu_folder Path to folder containing EMU `.tsv` files.
#' @param ref_file Path to reference Excel file with functional groups.
#' @param output_folder Path where output `.xlsx` files will be saved.
#'
#' @importFrom readxl read_excel
#' @importFrom magrittr %>%
#' @importFrom dplyr mutate filter group_by summarise select rename bind_rows left_join n
#' @importFrom tidyr pivot_longer
#' @importFrom stringr str_replace_all str_trim word
#' @importFrom writexl write_xlsx
#' @importFrom tools file_path_sans_ext
#' @export
run_pipeline <- function(emu_folder, ref_file, output_folder) {

  # Create output folder if it doesn't exist
  dir.create(output_folder, showWarnings = FALSE, recursive = TRUE)

  # === Step 1: Load and clean reference file ===
  ref_wide <- read_excel(ref_file)

  # Remove unnamed or empty columns
  ref_wide <- ref_wide[, !grepl("^Unnamed|^\\s*$", names(ref_wide))]

  # Clean column names
  names(ref_wide) <- stringr::str_trim(names(ref_wide))

  # Convert wide format to long format
  ref_long <- ref_wide %>%
    pivot_longer(cols = everything(), names_to = "Function", values_to = "species") %>%
    filter(!is.na(species)) %>%
    mutate(
      species = str_replace_all(str_trim(species), " ", "_"),
      genus = word(species, 1, sep = "_"),
      Function = str_trim(Function)
    )

  # === Step 2: Process each EMU file ===
  emu_files <- list.files(emu_folder, pattern = "\\.tsv$", full.names = TRUE)

  for (file in emu_files) {
    message("📦 Processing: ", basename(file))

    df <- read_tsv(file, show_col_types = FALSE) %>%
      mutate(
        species = str_replace_all(str_trim(species), " ", "_"),
        genus = word(species, 1, sep = "_"),
        sample = file_path_sans_ext(basename(file))
      )

    match_species <- left_join(df, ref_long, by = "species")
    unmatched <- filter(match_species, is.na(Function))
    matched <- filter(match_species, !is.na(Function))

    final <- if (nrow(unmatched) > 0) {
      unmatched <- unmatched %>%
        select(-Function, -genus.y) %>%
        rename(genus = genus.x) %>%
        left_join(ref_long, by = "genus")
      bind_rows(matched, unmatched)
    } else {
      matched
    }

    # === Step 3: Summarize and write output ===
    summary_df <- final %>%
      filter(!is.na(Function)) %>%
      group_by(sample, Function) %>%
      summarise(
        Count = n(),
        Total_Abundance = sum(abundance, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      mutate(
        Percentage = round(100 * Total_Abundance / sum(Total_Abundance), 2),
        Top_Species = NA_character_
      )

    sheets <- list()

    if (nrow(summary_df) > 0) {
      all_functions <- unique(summary_df$Function)
      for (func in all_functions) {
        func_df <- final %>%
          filter(Function == func) %>%
          mutate(
            species = ifelse(is.na(species) | species == "", genus, species)
          ) %>%
          group_by(species) %>%
          summarise(
            abundance = sum(abundance, na.rm = TRUE),
            .groups = "drop"
          ) %>%
          mutate(
            Percentage = round(100 * abundance / sum(abundance), 2),
            Top_Contributor = FALSE
          )

        top_idx <- which.max(func_df$abundance)
        func_df$Top_Contributor[top_idx] <- TRUE
        summary_df$Top_Species[summary_df$Function == func] <- func_df$species[top_idx]
        sheets[[func]] <- func_df
      }

      sheets[["Summary"]] <- summary_df

      out_file <- file.path(output_folder, paste0(summary_df$sample[1], "_detailed_summary.xlsx"))
      write_xlsx(sheets, path = out_file)
      message("✅ Saved enhanced summary: ", basename(out_file))
    } else {
      message("⚠️ No matching functional group found for: ", basename(file))
    }
  }
}
