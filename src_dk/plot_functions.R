## Plot-funktioner
#source(here("plot_functions.R"))

## Tilføj scene indeks
calc_scene_index <- function(act_number, scene_number, act_length) {
  ifelse(is.numeric(scene_number),
         scene_number + ifelse(act_number==1, 0, act_length[act_number-1]),
         NA
  )
}
get_scene_index <- function(my_play) {
  my_play %>% 
  group_by(act_number)  %>% 
  summarise(scenes = max(scene_number)) %>% 
  pull(scenes) %>% cumsum() -> act_length

act_length
}

## Omstrukturer data
get_summary <- function(my_play) {
  my_play %>% 
    # add a scene index for the x-axis
    rowwise() %>% 
    mutate(scene_index = calc_scene_index(act_number, scene_number, act_length)) %>% 
    # remove rows that are not dialogue
    filter(act != "", scene != "", speaker != "", !is.na(spoke)) %>%
    # make a boolean to indicate spoke
    mutate(boolean_spoke = (if (spoke != "") {"X"} else {"Y"})) %>%
    # keep only coloumns that we need
    select(act_number, scene_number, scene_index, speaker, boolean_spoke) %>%
    distinct() -> my_summary
  
  #Husk at tælle hvor mange der er på scenen
  (my_summary %>%
      group_by(act_number, scene_number) %>%
      mutate(total = sum(n_distinct(speaker))) -> my_summary) 
}

## Title
get_title <- function(my_play) {
  my_play %>% 
    select(docTitle) %>% 
    distinct() %>%
    pull(1,1) -> my_title
}

## Year
get_year <- function(my_play) {
  my_play %>% 
    select(year) %>% 
    distinct() %>%
    pull(1,1) -> my_year
}

#Graf over hvem der taler
#Antager der er tilføjet scene index og kørt navnevarianter mm
plot_speakers <- function(my_play, my_summary, my_file, my_title, my_year) {
  #Plot
  my_summary %>% 
    ggplot(aes(y = speaker, x = scene_index, width = 100)) +
    geom_tile(aes(fill = boolean_spoke, colour = speaker), colour = "grey", show.legend = FALSE) + 
    geom_text(aes(label = "X")) +
    labs(
      title = paste(my_title, my_year, my_file),
      subtitle = "Hvem taler hvornår"
    ) +
    xlab("Akt \nScene \nAntal personer der taler i scenen") +
    ylab("Speaker") + 
    theme(axis.text.x=element_blank(), line = element_blank(), rect = element_blank()) + 
    facet_grid(cols = vars("act_number" = act_number, "scene_number" = scene_number, "total" = total), switch="x")
  
  ggsave(here("graphs/plots", paste(my_file, ".hvem_taler_hvornaar.pdf")), width=16, height=9)
}

#Graf over hvem der er til stede
#Indeholder både dem der taler (X) og dem der er til stede (S) men ikke taler
plot_present <- function(my_play, my_summary, my_file, my_title, my_year) {
  # Til stede, men taler ikke
  present_without_speech_numbers(my_play) %>%
    # add a scene index for the x-axis
    rowwise() %>% 
    mutate(scene_index = calc_scene_index(act_number, scene_number, act_length)) %>%
    # add a boolean for "til stede"
    mutate(boolean_spoke = "S") %>%
    select(-index) -> present_silent 
  
  # Sæt "taler" og "til stede" sammen
  my_summary %>%
    select(-total) %>%
    full_join(present_silent, 
              by = c("speaker"="word", "act_number", "scene_number", "scene_index", "boolean_spoke")) -> new_summary
  
  #Husk at tælle hvor mange der NU er på scenen
  (new_summary %>%
      group_by(act_number, scene_number) %>%
      mutate(total = sum(n_distinct(speaker))) -> new_summary) 
  
  new_summary %>% 
    ggplot(aes(y = speaker, x = scene_index, width = 100)) +
    geom_tile(aes(fill = boolean_spoke, colour = speaker), colour = "grey", show.legend = FALSE) + 
    geom_text(aes(label = boolean_spoke)) +
    labs(
      title = paste(my_title, my_year, my_file),
      subtitle = "Hvem er til stede"
    ) +
    xlab("Akt \nScene \nAntal personer i scenen") +
    ylab("Speaker") + 
    theme(axis.text.x=element_blank(), line = element_blank(), rect = element_blank()) + 
    facet_grid(cols = vars("act_number" = act_number, "scene_number" = scene_number, "total" = total), switch = "x")
  
  ggsave(here("graphs/plots", paste(my_file, ".hvem_til_stede.pdf")), width=16, height=9)
  
  new_summary -> my_summary
}

#Graf over omtale
#Indeholder også dem der taler (X) og dem der er stille (S) og så dem der bliver omtalt (O)
plot_omtale <- function(my_play, my_summary, my_file, my_title, my_year) {
  source(here("src", "omtale.R"))
  (spoken_about(my_play) %>%
      # add a scene index for the x-axis
      rowwise() %>% 
      mutate(scene_index = calc_scene_index(act_number, scene_number, act_length)) %>%
      # add a boolean for "omtalt"
      mutate(boolean_spoke = "O") %>%
      select(-index)
    -> spoken_about_summary) 
  
  my_summary %>%
    select(-total) %>%
    full_join(spoken_about_summary, by = c("speaker"="word", "act_number", "scene_number", "scene_index", "boolean_spoke")) %>% 
    ggplot(aes(y = speaker, x = scene_index, width = 100)) +
    geom_tile(aes(fill = boolean_spoke, colour = speaker), colour = "grey", show.legend = FALSE) + 
    geom_text(aes(label = boolean_spoke)) +
    labs(
      title = paste(my_title, my_year, my_file),
      subtitle = "Hvem taler hvornår og hvem bliver omtalt"
    ) +
    xlab("Akt \nScene") +
    ylab("Speaker") + 
    theme(axis.text.x=element_blank(), line = element_blank(), rect = element_blank()) + 
    facet_grid(cols = vars("act_number" = act_number, "scene_number" = scene_number), switch = "x")
  
  ggsave(here("graphs/plots", paste(my_file, ".hvem_til_stede_hvem_omtalt.pdf")), width=16, height=9)
}

