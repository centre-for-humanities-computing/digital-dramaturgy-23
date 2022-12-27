## unction: Mentions
#source(here("omtale.R"))

# This function calculates characters that are spoken about, but not present, in 
# each scene in each act in a given play
spoken_about <- function(play) {
  # Find speakers
  play %>%
    filter(!is.na(speaker)) %>% 
    count(speaker) %>%
    mutate(speaker = str_to_lower(speaker)) %>%
    select(speaker) -> speakers
  
  # Find spoken words.
  (play %>% 
      filter(!is.na(spoke)) %>%
      filter(!spoke=="")  %>% 
      unnest_tokens(word, spoke) %>% #tokenize spoke
      select(act_number, scene_number, index, word) %>% 
      distinct() -> spoke_tokens)
  
  # Search for speakers in spoken words.
  (spoke_tokens %>%
      semi_join(speakers, by = c("word" = "speaker")) -> speakers_in_spoke)
  
  # Remove the speakers, that are actually speaking?!
  ## Distinct speakers in each scene in each act   
  (play %>% 
      filter(!is.na(speaker)) %>%
      select(act_number, scene_number, speaker) %>%
      mutate(speaker = str_to_lower(speaker)) %>%
      distinct() -> distinct_speakers)
  
  ########## Student developer addition below ##########
  
  ## Add present but silent
  (source(here("src", "present_without_speech.R")))
  
  (all_in_stage <- present_without_speech_numbers(play))
  
  (distinct_speakers_and_present <- distinct_speakers %>% 
      full_join(all_in_stage, by=c("act_number", "scene_number", "speaker"="word"))) 
  
  ######################################################
  
  ## Filter out speakers from words grouped by act and scene!
  speakers_in_spoke %>%
    anti_join(distinct_speakers, by=c("act_number"="act_number", "scene_number"="scene_number", "word"="speaker")) %>% 
    distinct()
}


