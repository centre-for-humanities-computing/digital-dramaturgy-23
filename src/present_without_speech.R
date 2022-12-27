## Function: Present without speaking
#source(here("present_without_speech.R"))

# This function calculates characters that are present, but silent, in 
# each scene in each act in a given play
present_without_speech <- function(play) {
  # Find speakers
  play %>%
    filter(!is.na(speaker)) %>% 
    count(speaker) %>%
    mutate(speaker = str_to_lower(speaker)) %>%
    select(speaker) -> speakers
  # Find alle regi-bemærkninger. 
  # These are the people who are directly mentioned in the stage tokens
  (play %>% 
      filter(!is.na(stage)) %>%
      filter(!startsWith(stage, "("))  %>% 
      unnest_tokens(word, stage, drop=FALSE, token="regex", pattern = ", *") %>% #tokenize stage
      select(act, scene, index, word) %>% 
      distinct() -> explicit_stage_tokens)
  
  # These are the the actors who are implicitly mentioned in stage tokens
  (play %>% 
      filter(!is.na(stage)) %>%
      filter(startsWith(stage, "("))  %>% 
      unnest_tokens(word, stage) %>% #tokenize stage
      select(act, scene, index, word) %>% 
      distinct() -> implicit_stage_tokens)
  
  # These are the the actors who are implicitly mentioned in speaker stage tokens
  (play %>% 
      unnest_tokens(word, speaker_stage) %>% #tokenize speaker stage
      filter(!is.na(word)) %>%
      select(act, scene, index, word) -> speaker_stage_tokens)
  
  # Search for speakers in instructions
  (explicit_stage_tokens %>%
      semi_join(speakers, by = c("word" = "speaker")) -> explicit_speakers_in_stage)
  
  (implicit_stage_tokens %>%
      semi_join(speakers, by = c("word" = "speaker")) -> implicit_speakers_in_stage)
  
  (speaker_stage_tokens %>%
      semi_join(speakers, by = c("word" = "speaker")) -> speakers_in_speaker_stage)
  
  
  (explicit_speakers_in_stage %>%
      full_join(implicit_speakers_in_stage) %>% 
      full_join(speakers_in_speaker_stage) -> all_speakers_in_stage)
  
  # Remove the speakers, that are actually speaking?!
  ## Distinct speakers in each scene in each act   
  (play %>% 
      filter(!is.na(speaker)) %>%
      select(act, scene, speaker) %>%
      mutate(speaker = str_to_lower(speaker)) %>%
      distinct() -> distinct_speakers)
  
  ########## student developer addition below ##########
  
  ## Get variantions of character-names
  (variants <- read_excel(here("Rolleliste.xlsx")) %>% 
     filter(Filnavn == play$filename[1]) %>%
     unnest_tokens(variant, Alias, token = "regex", pattern = ", ") %>% 
     mutate(
       Karakter = tolower(Karakter),
       variant = tolower(variant)))
  
  ## Add name variants to distinct_speakers within each act and scene
  (distinct_speakers_w_variants <- data.frame())
  
  (for (i in 1:nrow(distinct_speakers)){
    act <- distinct_speakers$act[i]
    scene <- distinct_speakers$scene[i]
    speaker <- distinct_speakers$speaker[i]
    main_name <- variants$Karakter[variants$variant == speaker]
    alias_names <- variants$variant[variants$Karakter == main_name]
    n <- length(alias_names)
    new_rows <- data.frame(
      "act"=rep(act,n), 
      "scene"=rep(scene,n),
      "speaker"=alias_names)
    
    distinct_speakers_w_variants <- rbind(distinct_speakers_w_variants, new_rows)
  })
  
  
  (distinct_speakers <- rbind(distinct_speakers, distinct_speakers_w_variants) %>% 
      distinct())
  
  ################################################
  
  ## Filter out speakers from words grouped by act and scene!
  all_speakers_in_stage %>%
    anti_join(distinct_speakers, by=c("act"="act", "scene"="scene", "word"="speaker")) %>% 
    distinct()
}

# This function calculates characters that are present, but silent, in 
# each scene in each act in a given play, and returns a tibble with "act_number" and "scene_number"
# instead of "act" and "scene"
present_without_speech_numbers <- function(play) {
  # Find speakers
  play %>%
    filter(!is.na(speaker)) %>% 
    count(speaker) %>%
    mutate(speaker = str_to_lower(speaker)) %>%
    select(speaker) -> speakers
  # Find alle stage directions 
  # These are the characters who are directly mentioned in the stage tokens
  (play %>% 
      filter(!is.na(stage)) %>%
      filter(!startsWith(stage, "("))  %>% 
      unnest_tokens(word, stage, drop=FALSE, token="regex", pattern = ", *") %>% # Tokenize stage
      select(act_number, scene_number, index, word) %>% 
      distinct() -> explicit_stage_tokens)
  
  # These are the the characters who are implicitly mentioned in stage tokens
  (play %>% 
      filter(!is.na(stage)) %>%
      filter(startsWith(stage, "("))  %>% 
      unnest_tokens(word, stage) %>% #tokenize stage
      select(act_number, scene_number, index, word) %>% 
      distinct() -> implicit_stage_tokens)
  
  # These are the the characters who are implicitly mentioned in speaker stage tokens
  (play %>% 
      unnest_tokens(word, speaker_stage) %>% #tokenize speaker stage
      filter(!is.na(word)) %>%
      select(act_number, scene_number, index, word) -> speaker_stage_tokens)
  
  # Search for speakers in stage directions
  (explicit_stage_tokens %>%
      semi_join(speakers, by = c("word" = "speaker")) -> explicit_speakers_in_stage)
  
  (implicit_stage_tokens %>%
      semi_join(speakers, by = c("word" = "speaker")) -> implicit_speakers_in_stage)
  
  (speaker_stage_tokens %>%
      semi_join(speakers, by = c("word" = "speaker")) -> speakers_in_speaker_stage)
  
  
  (explicit_speakers_in_stage %>%
      full_join(implicit_speakers_in_stage) %>% 
      full_join(speakers_in_speaker_stage) -> all_speakers_in_stage)
  
  # Remove the speakers, that are actually speaking
  ## Distinct speakers in each scene in each act   
  (play %>% 
      filter(!is.na(speaker)) %>%
      select(act_number, scene_number, speaker) %>%
      mutate(speaker = str_to_lower(speaker)) %>%
      distinct() -> distinct_speakers)
  
  
  ########## student developer addition below ##########
  
  ## Get variantions of character-names
  (variants <- read_excel(here("Rolleliste.xlsx")) %>% 
     filter(Filnavn == play$filename[1]) %>%
     unnest_tokens(variant, Alias, token = "regex", pattern = ", ") %>% 
     mutate(
       Karakter = tolower(Karakter),
       variant = tolower(variant)))
  
  ## Add name variants to distinct_speakers within each act and scene
  (distinct_speakers_w_variants <- data.frame())
  
  (for (i in 1:nrow(distinct_speakers)){
    act <- distinct_speakers$act_number[i]
    scene <- distinct_speakers$scene_number[i]
    speaker <- distinct_speakers$speaker[i]
    main_name <- variants$Karakter[variants$variant == speaker]
    alias_names <- variants$variant[variants$Karakter == main_name]
    n <- length(alias_names)
    new_rows <- data.frame(
      "act_number"=rep(act,n), 
      "scene_number"=rep(scene,n),
      "speaker"=alias_names)
    
    distinct_speakers_w_variants <- rbind(distinct_speakers_w_variants, new_rows)
  })
  
  (distinct_speakers <- rbind(distinct_speakers, distinct_speakers_w_variants) %>% 
      distinct())
  
  ################################################
  
  ## Filter out speakers from words grouped by act and scene!
  all_speakers_in_stage %>%
    anti_join(distinct_speakers, by=c("act_number", "scene_number", "word"="speaker")) %>% 
    distinct()
}


