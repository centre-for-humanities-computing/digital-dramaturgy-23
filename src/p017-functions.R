# This function takes on argument:
#   folder: the path to a folder containing one or more
#           TEI files with the .page extension
#
# The function creates JSONL versions of these files, and
# stores them in the same folder
# The function assumes the existence of two XSLT scripts present
# in the src folder of the project.
convert_TEI_to_JSONL <- function(folder) {
  # Load the XSL tranformations
  stripSeqXSL <- read_xml(here("src","stripSeq.xslt"))
  # TODO: add a column with all the titles
  tei2jsonlXSL <- read_xml(here("src","tei2jsonl.xslt"))
  
  # convert all .page files in the "test-data/tei" directory to JSONL files
  dir_walk(
    folder,
    function(filename) if (str_ends(filename,".page")) filename %>%
      read_xml() %>%
      xml_xslt(stripSeqXSL) %>%
      xml_xslt(tei2jsonlXSL) %>%
      write_file(fs::path(fs::path_ext_remove(filename), ext="jsonl")))
}

# This function reads all JSONL files in a folder into
# a tibble, adding an index numbering each scene within each play
#
# The ndjson::stream_in() function does not work on Microsoft Windows,
# as files are read using Latin-1, even though they are UTF-8.
# read_plays_jsonl <- function(folder) {
#   dir_ls(here(folder), glob = "*.jsonl") %>%
#     map_dfr(function(fn) ndjson::stream_in(fn) %>% tibble() %>% mutate(speaker = stringr::str_remove(speaker, " \\(")) %>% add_column(filename = basename(fn)))
# }
#
# Instead we use jsonlite::stream_in() that dosen't seem to have the same problem.
# This function has another challengde in that it fails to read quoted strings 
# within JSON strings. It's actually weird, that ndjson::stream_in didn't also 
# fail on this!
#
# To mitigate this error, ONE file must be corrected by hand in either the 
# Mascarade.page file before convert_TEI_to_JSONL or the Mascarade_mod.jsonl 
# after the conversion.
#
# The following sed command will do for both file types:
# sed "s/\"nok en kop kaffe\"/\'nok en kop kaffe\'/"
read_plays_jsonl <- function(folder) {
  dir_ls(here(folder), glob = "*.jsonl") %>%
    map_dfr(
      function(fn) jsonlite::stream_in(file(fn), verbose = FALSE) %>% 
        tibble() %>%
        mutate(speaker = stringr::str_remove(speaker, " \\(")) %>%
        add_column(filename = basename(fn)))
}

# This function reads the JSONL file specified as input into
# a tibble, adding an index numbering each scene within each play
# and adds a filename coloumn
read_play_jsonl <- function(file) {
  file %>% 
    map_dfr(
      ~ndjson::stream_in(.) %>%
        tibble() %>%
        mutate(speaker = stringr::str_remove(speaker, " \\(")) %>% 
        add_column(filename = substr(file, 
                                     start = unlist(lapply(str_locate_all(file, '/'), max))+1, 
                                     stop = str_length(file)), .before = 0)
    )
}
