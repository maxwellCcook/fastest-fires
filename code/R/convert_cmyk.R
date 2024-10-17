# Function to convert a file into CMYK format using ImageMagick.
# Note that ImageMagick must be installed and accessible via command line.
# PARAMETERS
# file :: a file to convert to cmyk format
# outDir :: a directory to output the converted file. If left empty, will output in same directory as the original file.
# Example usage:
# pngs <- list.files(here::here('figs'), pattern = "\\.png$", full.names = TRUE, ignore.case = TRUE)
# pngs |> purrr::walk(~ convert.to.cmyk(file = .x))
convert.to.cmyk <- function(file, outDir = NA) {
 
 # Check if the file exists
 if (!file.exists(file)) {
  warning(paste("File does not exist:", file))
  next
 }
 
 # Set outdir
 if(is.na(outDir)) {
  directory <- dirname(file)
 } else {
  directory <- outDir
 }
 
 # Construct the new filename by appending '_cmyk' before the file extension
 filePath <- normalizePath(file, mustWork = FALSE)
 fileNm <- tools::file_path_sans_ext(basename(filePath))
 fileExt <- tools::file_ext(filePath)
 newFileNm <- paste0(fileNm, "_cmyk.", fileExt)
 newPath <- file.path(directory, newFileNm)
 
 # newFileName <- file.path(directory, paste0(tools::file_path_sans_ext(basename(file)), "_cmyk", tools::file_ext(file)))
 # 
 # # Construct the new filename by appending '_cmyk' before the file extension
 # file_path <- normalizePath(file, mustWork = FALSE)
 # file_info <- tools::file_path_sans_ext(file_path)
 # file_ext <- tools::file_ext(file_path)
 # new_file_name <- paste0(file_info, "_cmyk.", file_ext)
 
 # Form the command to convert the file to CMYK
 command <- sprintf('magick "%s" -colorspace CMYK "%s"', filePath, newPath)
 
 # Execute the command using system()
 system(command, intern = FALSE)
 
 # Print the status message
 cat("Converted:", filePath, "to CMYK and saved as:", newFileNm, "\n")
}

#Convert all PNGs to CMYK versions per Science journal requirements
pngs_dir <- '/Users/max/Library/CloudStorage/OneDrive-Personal/mcook/earth-lab/fastest-fires/figures/'
pngs <- list.files(pngs_dir,pattern = "\\.png$", full.names = TRUE, ignore.case = TRUE)
pngs |> purrr::walk(~ convert.to.cmyk(file = .x, outDir = here::here(pngs_dir, 'cmyk_converted')))
