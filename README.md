# bactofunc

`bactofunc` is an R package for bacterial functional group extraction from EMU `.tsv` files using a reference Excel sheet.

## Installation

To install manually:

```r
# From source folder (example)
install.packages("C:/Users/bshivamkumar/File_Path/bactofunc", repos = NULL, type = "source")

library(bactofunc)

run_pipeline(
  emu_folder = "C:/Users/bshivamkumar/File_Path/emu_files",
  ref_file = "C:/Users/bshivamkumar/File_Path/N_C_bac_list.xlsx",
  output_folder = "C:/Users/bshivamkumar/File_Path/output"
)

Inputs
EMU .tsv files with abundance data

Excel reference file mapping species/genus to functions

Output
Excel summary files with top contributor, percentages, and per-function breakdown.

Author
Shivam Kumar Bhardwaj (South Dakota State University)
