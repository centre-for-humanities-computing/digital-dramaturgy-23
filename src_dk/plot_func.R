## Plot-funktion Alt i en
#source(here("plot_func.R"))

plot_all <- function(my_file) {
  my_play <- read_play_jsonl(here("test-data", my_file))
  
  ## Navnevarianter
  # Indlæs Excelarket
  variants <- read_excel(here("Rolleliste.xlsx")) %>% 
    unnest_tokens(variant, Alias, token = "regex", pattern = ", ") %>% 
    mutate(
      Karakter = tolower(Karakter),
      variant = tolower(variant)
    )
  # Benyt excelark til at samle varianter
  my_play %>%
    mutate(speaker = tolower(speaker)) %>% 
    left_join(variants, by = c("filename"="Filnavn", "speaker"="variant")) %>% 
    mutate(speaker = if_else(!is.na(Karakter), Karakter, speaker)) %>%
    filter(!is.na(speaker), !(speaker=="")) %>%
    distinct -> my_play
  
  ## Tilføj scene indeks
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
  
  ## Omstrukturer data
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
  
  (my_summary %>%
      # make a small scene_index, act_number, scene_number table
      select(scene_index, act_number, scene_number) %>% 
      distinct() -> my_acts_and_scenes)
  (my_acts_and_scenes %>% pull(act_number) -> my_acts)
  
  
  
  my_summary %>%
    # select only the columns, that we are interested in
    select(scene_index, speaker, boolean_spoke) %>% 
    distinct() %>%
    # now pivot speakers to rows
    pivot_wider(names_from = scene_index, values_from = boolean_spoke) -> my_speakers
  
  # now remove NA
  my_speakers[is.na(my_speakers)] <- ""
  my_speakers
  
  # #Skriv til csv
  # write.csv(my_speakers, file = here(paste("csv/","plot_who_speaks_", my_file, ".csv")))
  # 
  # # Pretty print my_speakers
  # # install.packages("DT")
  # library(DT)
  # datatable(my_speakers)
  
  ##Graf over hvem der taler
  my_play %>% 
    select(docTitle) %>% 
    distinct() %>%
    pull(1,1) -> my_title
  
  my_play %>% 
    select(year) %>% 
    distinct() %>%
    pull(1,1) -> my_year
  
  #Husk at tælle hvor mange der NU er på scenen
  (my_summary %>%
      group_by(act_number, scene_number) %>%
      mutate(total = sum(n_distinct(speaker))) -> my_summary) 
  
  #Plot
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
      subtitle = "Hvem taler hvornår"
    ) +
    scale_x_discrete(position = "top") +
    xlab("Akt \nScene \nAntal personer der taler i scenen") +
    ylab("Speaker") + 
    theme(axis.text.x=element_blank(), line = element_blank(), rect = element_blank()) + 
    facet_grid(cols = vars("act_number" = act_number, "scene_number" = scene_number, "total" = total))
    #facet_grid(cols = vars("act_number" = act_number, "scene_number" = scene_number, "total" = total), switch="x")
  
  #### Student developer: Bør man fjerne /hvem-taler-hvornaar da denne undermappe ikke findes og bør man i filnavnet indlede med _ i stedet for .?
  
  ggsave(here("graphs/plots/hvem-taler-hvornaar", paste0(my_file, ".hvem_taler_hvornaar.pdf")), width=16, height=9)
  
  ##Graf over hvem der er til stede
  source(here("src", "present_without_speech.R")) # Added by student developer
  
  # Vi genindlæser lige stykket!
  my_play <- read_play_jsonl(here("test-data", my_file))
  
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
    geom_tile(aes(fill = boolean_spoke, colour = speaker), colour = "grey", show.legend = TRUE) +

    scale_fill_manual(name = "", labels = c("Stum (S)", "Talende (X)"), values = c(rgb(230/255,159/255,0), rgb(240/255,228/255,66/255))) +
    scale_x_discrete(position = "top") +
    geom_text(aes(label = boolean_spoke)) +
    labs(
      title = paste(my_title, my_year, my_file),
      subtitle = "Hvem er til stede"
    ) +
    xlab("Akt \nScene \nAntal personer i scenen") +
    ylab("Speaker") + 
    theme(
      axis.text.x=element_blank(),
      line = element_blank(),
      rect = element_blank(),
      legend.position = "bottom") + 
    
    facet_grid(cols = vars("act_number" = act_number, "scene_number" = scene_number, "total" = total))
  
  ggsave(here("graphs/plots/hvem-til-stede", paste0(my_file, ".hvem_til_stede.pdf")), width=16, height=9)
  
  ##Graf over omtale
  source(here("src", "omtale.R"))
  (spoken_about(my_play) %>%
      # add a scene index for the x-axis
      rowwise() %>% 
      mutate(scene_index = calc_scene_index(act_number, scene_number, act_length)) %>%
      # add a boolean for "omtalt"
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
       labels = c("Omtalt (O)", "Stum (S)", "Talende (X)"),
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
      subtitle = "Hvem er til stede og hvem bliver omtalt"
    ) +
    xlab("Akt \nScene") +
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
