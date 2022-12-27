## Plot functions (all in one)
#source(here("plot_func.R"))

plot_all <- function(my_file) {
  my_play <- read_play_jsonl(here("test-data", my_file))
  
  ## Variations of character-names
  # Read in the excel sheet of name variations
  variants <- read_excel(here("Rolleliste.xlsx")) %>% 
    unnest_tokens(variant, Alias, token = "regex", pattern = ", ") %>% 
    mutate(
      Karakter = tolower(Karakter),
      variant = tolower(variant)
    )
  # Use the excel sheet to gather and join variations of character-names
  my_play %>%
    mutate(speaker = tolower(speaker)) %>% 
    left_join(variants, by = c("filename"="Filnavn", "speaker"="variant")) %>% 
    mutate(speaker = if_else(!is.na(Karakter), Karakter, speaker)) %>%
    filter(!is.na(speaker), !(speaker=="")) %>%
    distinct -> my_play
  
  ## Add a scene-index
  my_play %>% 
    group_by(act_number)  %>% 
    summarise(scenes = max(scene_number)) %>% 
    pull(scenes) %>% cumsum() -> act_length
  
  act_length
  
  calc_scene_index <- function(act_number, scene_number, act_length) {
    ifelse(is.numeric(scene_number),
           scene_number + ifelse(act_number==1, 0, act_length[act_number-1]),
           NA
    )
  }
  
  ## Restructure the data
  my_play %>% 
    # Add a scene index for the x-axis
    rowwise() %>% 
    mutate(scene_index = calc_scene_index(act_number, scene_number, act_length)) %>% 
    # Remove rows that are not dialogue
    filter(act != "", scene != "", speaker != "", !is.na(spoke)) %>%
    # Make a boolean to indicate spoke
    mutate(boolean_spoke = (if (spoke != "") {"X"} else {"Y"})) %>%
    # Keep only the columns that we need
    select(act_number, scene_number, scene_index, speaker, boolean_spoke) %>%
    distinct() -> my_summary
  
  (my_summary %>%
      # Make a small scene_index, act_number, scene_number table
      select(scene_index, act_number, scene_number) %>% 
      distinct() -> my_acts_and_scenes)
  (my_acts_and_scenes %>% pull(act_number) -> my_acts)
  
  
  
  my_summary %>%
    # Select only the columns, that we are interested in
    select(scene_index, speaker, boolean_spoke) %>% 
    distinct() %>%
    # Now pivot speakers to rows
    pivot_wider(names_from = scene_index, values_from = boolean_spoke) -> my_speakers
  
  # Now remove NA
  my_speakers[is.na(my_speakers)] <- ""
  my_speakers
  
  ## Write the table to a csv
  # write.csv(my_speakers, file = here(paste("csv/","plot_who_speaks_", my_file, ".csv")))
  # 
  # # Pretty print my_speakers
  # # install.packages("DT")
  # library(DT)
  # datatable(my_speakers)
  
  ## Plotting who speaks
  my_play %>% 
    select(docTitle) %>% 
    distinct() %>%
    pull(1,1) -> my_title
  
  my_play %>% 
    select(year) %>% 
    distinct() %>%
    pull(1,1) -> my_year
  
  # Remember to count how many are on stage at present
  (my_summary %>%
      group_by(act_number, scene_number) %>%
      mutate(total = sum(n_distinct(speaker))) -> my_summary) 
  
  # Plot
  my_summary %>% 
    ggplot(aes(y = speaker, x = scene_index, width = 100)) +
    scale_fill_manual(
      name = "",
      labels = c("Stum (S)", "Talende (X)"),
      values = c(rgb(240/255,228/255,66/255))
    ) +
    geom_tile(aes(fill = boolean_spoke, colour = speaker), colour = "grey", show.legend = FALSE) + 
    geom_text(aes(label = "X")) +
    labs(
      title = paste(my_title, my_year, my_file),
      subtitle = "Who speaks when"
    ) +
    scale_x_discrete(position = "top") +
    xlab("Act \nScene \nNumber of characters speaking in the scene") +
    ylab("Speaker") + 
    theme(axis.text.x=element_blank(), line = element_blank(), rect = element_blank()) + 
    facet_grid(cols = vars("act_number" = act_number, "scene_number" = scene_number, "total" = total))
    #facet_grid(cols = vars("act_number" = act_number, "scene_number" = scene_number, "total" = total), switch="x")
  
  ggsave(here("graphs/plots/hvem-taler-hvornaar", paste0(my_file, ".hvem_taler_hvornaar.pdf")), width=16, height=9)
  
  ## Plot showing who is present
  source(here("src", "present_without_speech.R")) # Added by student developer
  
  # Let's read in the play again
  my_play <- read_play_jsonl(here("test-data", my_file))
  
  # Present, but does not speak
  present_without_speech_numbers(my_play) %>%
    # Add a scene index for the x-axis
    rowwise() %>% 
    mutate(scene_index = calc_scene_index(act_number, scene_number, act_length)) %>%
    # Add a boolean for "til stede"
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
    geom_tile(aes(fill = boolean_spoke, colour = speaker), colour = "grey", show.legend = TRUE) +

    scale_fill_manual(name = "", labels = c("Mute (S)", "Speaking (X)"), values = c(rgb(230/255,159/255,0), rgb(240/255,228/255,66/255))) +
    scale_x_discrete(position = "top") +
    geom_text(aes(label = boolean_spoke)) +
    labs(
      title = paste(my_title, my_year, my_file),
      subtitle = "Who is present"
    ) +
    xlab("Act \nScene \nNumber of characters in the scene") +
    ylab("Speaker") + 
    theme(
      axis.text.x=element_blank(),
      line = element_blank(),
      rect = element_blank(),
      legend.position = "bottom") + 
    
    facet_grid(cols = vars("act_number" = act_number, "scene_number" = scene_number, "total" = total))
  
  ggsave(here("graphs/plots/hvem-til-stede", paste0(my_file, ".hvem_til_stede.pdf")), width=16, height=9)
  
  ## Plotting mentions
  source(here("src", "omtale.R"))
  (spoken_about(my_play) %>%
      # Add a scene index for the x-axis
      rowwise() %>% 
      mutate(scene_index = calc_scene_index(act_number, scene_number, act_length)) %>%
      # Add a boolean for "mentioned"
      mutate(boolean_spoke = "O") %>%
      mutate(total = 0) %>%
      select(-index) -> spoken_about_summary) 
  
  new_summary %>%
    #select(-total) %>%
    full_join(spoken_about_summary, by = c("speaker"="word", "act_number", "scene_number", "scene_index", "boolean_spoke")) %>% 
    ggplot(aes(y = speaker, x = scene_index, width = 100)) +
    geom_tile(aes(fill = boolean_spoke, colour = speaker), colour = "grey", show.legend = TRUE) + 

    scale_fill_manual(
       name = "",
       labels = c("Mentioned (O)", "Mute (S)", "Speaking (X)"),
       values = c(
          rgb(86/255,180/255,233/255),
          rgb(230/255,159/255,0),
          rgb(240/255,228/255,66/255)
       )
    ) +
    scale_x_discrete(position = "top") +

    geom_text(aes(label = boolean_spoke)) +
    labs(
      title = paste(my_title, my_year, my_file),
      subtitle = "Who is present and who is mentioned"
    ) +
    xlab("Act \nScene") +
    ylab("Speaker") + 
    theme(
      axis.text.x=element_blank(),
      line = element_blank(),
      rect = element_blank(),
      legend.position="bottom"
    ) + 
    facet_grid(cols = vars("act_number" = act_number, "scene_number" = scene_number))
  
  ggsave(here("graphs/plots/hvem-til-stede-hvem-omtalt", paste0(my_file, ".hvem_til_stede_hvem_omtalt.pdf")), width=16, height=9)
  
}
