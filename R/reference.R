# Convert and unite .Rd files to 'docs/reference.md'.
.make_reference <- function(update = FALSE, path = ".",
                            custom_reference = NULL) {

  cli::cli_h1("Building reference")
  if (!is.null(custom_reference)) {
    cli::cli_progress_bar("{cli::pb_spin} Running file {.file {custom_reference}}")
    source(custom_reference, echo = FALSE)
    cli::cli_alert_success("Custom file for {.pkg Reference} finished running.")
    return(invisible)
  }

  good_path <- .doc_path(path = path)
  if (fs::file_exists(paste0(good_path, "/reference.md"))) {
    fs::file_delete(paste0(good_path, "/reference.md"))
  }

  files <- list.files("man", full.names = TRUE)
  files <- files[grepl("\\.Rd", files)]

  all_rd_as_md <- lapply(files, function(x){
    .rd2md(x)
  })

  fs::file_create(paste0(good_path, "/reference.md"))
  writeLines(c("# Reference \n", unlist(all_rd_as_md)), paste0(good_path, "/reference.md"))

  cli::cli_alert_success("Functions reference {if (update) 'updated' else 'created'}.")
}


# Convert Rd file to Markdown
.rd2md <- function(rdfile) {

  tmp_html <- tempfile(fileext = ".html")
  tmp_md <- tempfile(fileext = ".md")

  tools::Rd2HTML(rdfile, out = tmp_html, permissive = TRUE)
  rmarkdown::pandoc_convert(tmp_html, "markdown_strict", output = tmp_md)

  cat("\n\n---", file = tmp_md, append = TRUE)

  # Get function title and remove HTML tags left
  md <- .readlines(tmp_md)
  md <- md[-c(1:10)]

  # Title to put in sidebar
  title <- gsub(".Rd", "", rdfile)
  title <- gsub("man/", "", title)
  title <- gsub("_", " ", title)
  initial <- substr(title, 1, 1)
  title <- paste0(toupper(initial), substr(title, 2, nchar(title)))

  md <- c(
    paste0("## ", title),
    md
  )

  # Syntax used for examples is four spaces, which prevents code
  # highlighting. So I need to put backticks before and after the examples
  # and remove the four spaces.
  start_examples <- which(grepl("^### Examples$", md))
  if (length(start_examples) != 0) {
    examples <- md[start_examples:length(md)]
    not_empty_lines <- which(examples != "")[-1]
    examples[not_empty_lines[1]] <-
      paste0("```r\n", examples[not_empty_lines[1]])
    examples[not_empty_lines[length(not_empty_lines)-1]] <-
      paste0(examples[not_empty_lines[length(not_empty_lines)-1]], "\n```")
    md[start_examples:length(md)] <- examples
    for (i in start_examples:length(md)) {
      md[i] <- gsub("    ", "", md[i])
    }
  }
  md
}


