
# Load libraries ----------------------------------------------------------
library(tidyverse)
library(readxl)
library(here)
library(fs)
library(tidytext)
source(here("src", "p017-functions.R"))


# Load and transform the manual excelsheet ----------------------------------------------
excel_sheet <- read_excel(here("allspeakers_gender_and_mask.xlsx"))

excel_sheet %>% 
  select(-`...1`) %>% # hvor kommer denne kolonne fra?
  separate_rows(plays, sep = ",") %>% 
  rename(play = plays) %>% 
  mutate(
    speaker = str_to_lower(speaker),
    play    = str_trim(str_to_lower(play))
  ) -> manual_decapitalized_trimmed

# Load and ready data for the the variants table ----------------------------------------
read_excel(here("Rolleliste.xlsx")) %>% 
  unnest_tokens(variant, Alias, token = "regex", pattern = ", ") %>% 
  mutate(
    Karakter = tolower(Karakter),
    variant = tolower(variant)
  ) -> variants

# Generate the auto table ---------------------------------------------------------
read_plays_jsonl(here("test-data")) %>% 
  filter(!is.na(speaker) & speaker != "") %>%
  rename(play = docTitle) %>% 
  mutate(
    speaker = str_to_lower(speaker),
    play    = str_to_lower(play)
  ) %>% 
  left_join(variants, by = c("filename" = "Filnavn", "speaker"="variant")) %>% 
  mutate(speaker = if_else(!is.na(Karakter), Karakter, speaker)) %>%
  count(speaker,play) -> auto_decapitalized

# Combine and save the two tables -------------------------------------------
auto_decapitalized %>% 
  mutate(in_auto = TRUE) %>% 
  full_join(
    manual_decapitalized_trimmed %>%
      mutate(in_manual = TRUE),
    by = c("speaker","play")
  ) %>% 
  mutate(
    in_auto = !is.na(in_auto),
    in_manual = !is.na(in_manual)
  ) %>% 
  select(speaker, play, in_auto, in_manual, everything()) -> gender_and_mask

write_excel_csv2(gender_and_mask,here("gender-and-mask.csv"))
# open the CSV file
system(str_c("open ", here("gender-and-mask.csv")))
