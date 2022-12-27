## Visualisering-ord-sagt-funktioner
#source(here("visalisering_ord_sagt_functions.R"))

# Function to create and save a visualization
# Input: text string with name of json file
create_visual <- function(my_file) {
  #read play
  (my_play <- read_play_jsonl(here("test-data", my_file)))
  
  #calculate act length
  my_play %>% 
    group_by(act_number)  %>% 
    summarise(scenes = max(scene_number)) %>% 
    pull(scenes) %>% cumsum() -> act_length
  
  # Indlæs Excelarket
  variants <- read_excel(here("Rolleliste.xlsx")) %>% 
    unnest_tokens(variant, Alias, token = "regex", pattern = ", ") %>% 
    mutate(
      Karakter = tolower(Karakter),
      variant = tolower(variant)
    )
  
  # Anvend Excelarket
  my_play %>% 
    mutate(speaker = tolower(speaker)) %>% 
    left_join(variants, by = c("filename"="Filnavn", "speaker"="variant")) %>% 
    mutate(speaker = if_else(!is.na(Karakter), Karakter, speaker)) %>%
    distinct -> my_play
  
  #klargøring af data
  my_play %>% 
    select(docTitle) %>% 
    distinct() %>%
    pull(1,1) -> my_title
  
  my_play %>% 
    select(year) %>% 
    distinct() %>%
    pull(1,1) -> my_year
  
  (my_play %>% 
      # add a scene index for the x-axis
      rowwise() %>% 
      mutate(scene_index = calc_scene_index(act_number, scene_number, act_length)) %>% 
      # remove rows that are not dialogue
      filter(act != "", scene != "", !is.na(spoke)) -> tmp) 
  
  tmp %>%
    
    # select only the columns, that we are interested in
    select(scene_index, act_number, scene_number, speaker, spoke) %>% 
    
    # add the number of spoken words
    mutate(n_spoken_words = str_count(spoke, '\\w+')) %>% 
    # remove the spoken words
    select(-spoke) %>%
    
    # group the play in scene_index and speaker, ignoring the test
    group_by(scene_index, act_number, scene_number, speaker) %>% 
    
    # Ensure that each speaker only appears once in each scene, i.e. sum the words spoken by each speaker
    # Lastly store the new data frame in a new reference for later use
    summarise(words = sum(n_spoken_words), act_number, scene_number) %>%
    distinct() -> my_summary
  
  #visualiser
  (new_act <- my_summary %>%
      ungroup %>%
      arrange(scene_index) %>%
      select(act_number, scene_number, scene_index) %>%
      distinct() %>%
      filter(scene_number==1) %>%
      mutate(line = scene_index + 0.5) %>%
      select(line) %>%
      tibble())
  
  my_summary %>% 
    ggplot(aes(fill = speaker, y = words, x = scene_index)) +
    geom_bar(stat="identity", width = 100) +
    theme(legend.position="bottom") +
    labs(
      title = paste(my_title, my_year, my_file),
      subtitle = "Hvor meget siger hvem",
      caption = "Kilde: DSL",
      fill = "Rolle"
    ) +
    xlab("Akt og scene") +
    ylab("Antal sagte ord") + 
    facet_wrap(act_number~scene_number, ncol=number_of_scenes, switch="x")+
    theme(axis.text.x=element_blank())
  
  #og gem
  ggsave(here("graphs/visualisering-ord-sagt", paste(my_file, ".hvor_meget_siger_hvem.pdf")), width=16, height=9)
  
}  


# funktion, som givet et aktnummer og scenenummer kan beregne den givne scenes nummer i sekvensen af alle scener
calc_scene_index <- function(act_number, scene_number, act_length) {
  ifelse(is.numeric(scene_number),
         scene_number + ifelse(act_number==1, 0, act_length[act_number-1]),
         NA
  )
}