## Plot functions
#source(here("plot_functions.R"))

## Add a scene-index
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

## Restructure data
get_summary <- function(my_play) {
  my_play %>% 
    # Add a scene index for the x-axis
    rowwise() %>% 
    mutate(scene_index = calc_scene_index(act_number, scene_number, act_length)) %>% 
    # Remove rows that are not dialogue
    filter(act != "", scene != "", speaker != "", !is.na(spoke)) %>%
    # Make a boolean to indicate spoke
    mutate(boolean_spoke = (if (spoke != "") {"X"} else {"Y"})) %>%
    # Keep only coloumns that we need
    select(act_number, scene_number, scene_index, speaker, boolean_spoke) %>%
    distinct() -> my_summary
  
  # Remember to count how many characters are on stage at present
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

# Plotting who speaks
# It is supposed that before running this a scene-index has been added and that variations of names have been joined 
plot_speakers <- function(my_play, my_summary, my_file, my_title, my_year) {
  #Plot
  my_summary %>% 
    ggplot(aes(y = speaker, x = scene_index, width = 100)) +
    geom_tile(aes(fill = boolean_spoke, colour = speaker), colour = "grey", show.legend = FALSE) + 
    geom_text(aes(label = "X")) +
    labs(
      title = paste(my_title, my_year, my_file),
      subtitle = "Who speaks when"
    ) +
    xlab("Act \nScene \nNumber of characters speaking in the scene") +
    ylab("Speaker") + 
    theme(axis.text.x=element_blank(), line = element_blank(), rect = element_blank()) + 
    facet_grid(cols = vars("act_number" = act_number, "scene_number" = scene_number, "total" = total), switch="x")
  
  ggsave(here("graphs/plots", paste(my_file, ".hvem_taler_hvornaar.pdf")), width=16, height=9)
}

# Plotting who is present
# Contains both characters speaking (X) and characters present but not speaking (S)
plot_present <- function(my_play, my_summary, my_file, my_title, my_year) {
  # Characters present but do not speak
  present_without_speech_numbers(my_play) %>%
    # Add a scene index for the x-axis
    rowwise() %>% 
    mutate(scene_index = calc_scene_index(act_number, scene_number, act_length)) %>%
    # Add a boolean for "present"
    mutate(boolean_spoke = "S") %>%
    select(-index) -> present_silent 
  
  # Combine "speaking" and "present"
  my_summary %>%
    select(-total) %>%
    full_join(present_silent, 
              by = c("speaker"="word", "act_number", "scene_number", "scene_index", "boolean_spoke")) -> new_summary
  
  # Remember to count how many characters are on stage at present
  (new_summary %>%
      group_by(act_number, scene_number) %>%
      mutate(total = sum(n_distinct(speaker))) -> new_summary) 
  
  new_summary %>% 
    ggplot(aes(y = speaker, x = scene_index, width = 100)) +
    geom_tile(aes(fill = boolean_spoke, colour = speaker), colour = "grey", show.legend = FALSE) + 
    geom_text(aes(label = boolean_spoke)) +
    labs(
      title = paste(my_title, my_year, my_file),
      subtitle = "Who is present"
    ) +
    xlab("Act \nScene \nNumber of characters in the scene") +
    ylab("Speaker") + 
    theme(axis.text.x=element_blank(), line = element_blank(), rect = element_blank()) + 
    facet_grid(cols = vars("act_number" = act_number, "scene_number" = scene_number, "total" = total), switch = "x")
  
  ggsave(here("graphs/plots", paste(my_file, ".hvem_til_stede.pdf")), width=16, height=9)
  
  new_summary -> my_summary
}

# Plotting mention
# Contains both characters speaking (X) and characters present but not speaking (S) and characters mentioned (0)
plot_omtale <- function(my_play, my_summary, my_file, my_title, my_year) {
  source(here("src", "omtale.R"))
  (spoken_about(my_play) %>%
      # Add a scene index for the x-axis
      rowwise() %>% 
      mutate(scene_index = calc_scene_index(act_number, scene_number, act_length)) %>%
      # Add a boolean for "omtalt"
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
      subtitle = "Who speaks and who is mentioned?"
    ) +
    xlab("Act \nScene") +
    ylab("Speaker") + 
    theme(axis.text.x=element_blank(), line = element_blank(), rect = element_blank()) + 
    facet_grid(cols = vars("act_number" = act_number, "scene_number" = scene_number), switch = "x")
  
  ggsave(here("graphs/plots", paste(my_file, ".hvem_til_stede_hvem_omtalt.pdf")), width=16, height=9)
}

