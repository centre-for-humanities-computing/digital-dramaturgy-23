## Graph functions
#source(here("graph_functions.R"))

# This function finds distinct speakers in each scene in each act grouped by act and scene
find_speakers <- function(play) {
  play %>%
    filter(!is.na(speaker)) %>%
    filter(!(speaker == "")) %>%
    select(speaker, act_number, scene_number) %>% 
    group_by(act_number, scene_number)  %>%
    distinct()
}

# This function finds speakers and their weights in each scene in each act grouped by act and scene
find_weights <- function(play) {
  play %>%
    mutate(n_spoken_words = str_count(spoke, '\\w+')) %>% 
    select(n_spoken_words, everything()) %>%
    filter(!is.na(speaker)) %>%
    filter(!(speaker == "")) %>%
    filter(!is.na(n_spoken_words)) %>%
    select(n_spoken_words, speaker, act_number, scene_number, act, scene) %>% 
    group_by(act_number, scene_number)  %>%
    summarise(words = sum(n_spoken_words), act_number, scene_number, act, scene, speaker) %>%
    distinct()
}

# This function joins speakers spelled differently in Mascarade
join_speakers_mascarade <- function(speakers) {
  speakers %>%
  # count all versions of "Leander" as one
  mutate(
    speaker = if_else(speaker %in% c("Leander", "Leander på Knæ"), "Leander", speaker)) %>%
    
    # count all versions of "Barselskvinden" as one
    mutate(
      speaker = if_else(speaker %in% c("Barselskonen", "Barselskvinden", "Barselsqvinde"), "Barselskvinden", speaker)) %>% 
    
    # Count all versions of "kællingen" as one
    mutate(
      speaker = if_else(speaker %in% c("Kælling", "Kællingen"), "Kællingen", speaker))
  
  
}

# This function turns distinct speakers into nodes with an id
speakers2nodes <- function(speakers) {
  speakers %>%
    ungroup() %>%
    select(speaker) %>%
    distinct() %>% 
    rowid_to_column("id")# Add id column
}

# This function creates an edge for each pair of speakers in each scene in each act
# The input data must be grouped by act-number and scene-number
find_edges <- function(distinct_speakers) {
  # Create column 'speaker2' and make it equal to 'speaker' (duplicate).
  distinct_speakers$speaker2 = distinct_speakers$speaker 
  # All possible combinations (remember the data is still grouped by act-number and scene-number)
  distinct_speakers %>% 
    expand(speaker, speaker2) -> who_speaks_to_whom
  
  (who_speaks_to_whom  %>%
      ungroup() %>%
      select(from = speaker, to = speaker2) %>%
      distinct() -> edges_play)
}

# Function to create and save a network graph
# Input: text string with name of json file
create_graph <- function(my_file) {
  # Load the excel sheet
  variants <- read_excel(here("Rolleliste.xlsx")) %>% 
      unnest_tokens(variant, Alias, token = "regex", pattern = ", ") %>% 
      mutate(
        Karakter = tolower(Karakter),
        variant = tolower(variant)
      )
  # Read the json file
  read_play_jsonl(here("test-data", my_file)) -> play
  # Find title and year
  my_play %>% 
    select(docTitle) %>% 
    distinct() %>%
    pull(1,1) -> my_title
  
  my_play %>% 
    select(year) %>% 
    distinct() %>%
    pull(1,1) -> my_year
  
  # Merge variations of character-names
  (play %>% 
      mutate(speaker = tolower(speaker)) %>% 
      left_join(variants, by = c("filename"="Filnavn", "speaker"="variant")) %>% 
      mutate(speaker = if_else(!is.na(Karakter), Karakter, speaker)) %>%
      filter(!is.na(speaker), !(speaker=="")) %>%
      distinct -> play)
  # Find speakers using function
  find_speakers(play) -> distinct_speakers
  # And find weights
  (find_weights(play) -> scene_weights)
  
  # Find Nodes and Edges and combine with weights 
  (speakers2nodes(distinct_speakers) -> nodes_play)
  # Create column 'speaker2' and make it equal to 'speaker' (duplicate).
  distinct_speakers$speaker2 = distinct_speakers$speaker 
  # All possible combinations (remember the data is still grouped by act-number and scene-number)
  distinct_speakers %>% 
    expand(speaker, speaker2) %>%
    # Remove instances where character refers to him/herself
    filter(speaker != speaker2) -> who_speaks_to_whom
  who_speaks_to_whom  %>%
      ungroup() %>%
      # Remove the edge in one of the directions so that we do not count it twice
      filter(speaker < speaker2) %>% 
      select(from = speaker, to = speaker2) %>%
      distinct() -> edges_play
  # Combine with weights
  who_speaks_to_whom %>% right_join(scene_weights) -> who_speaks_to_whom_with_weights
  # Sum the weights
  who_speaks_to_whom_with_weights  %>%
      ungroup() %>% 
      rename(from=speaker, to=speaker2) %>% 
      select(from,to,words) %>% 
      filter(!is.na(to)) %>% 
      group_by(from,to) %>% 
      arrange(from,to,words) %>% 
      mutate(weight=sum(words)) %>% 
      ungroup() %>% 
      select(from,to,weight) %>% 
      filter(from < to) %>% # Remove the edge in one of the directions
      distinct() -> edges_weights
  # Graph without silent characters and without arrows
  gr1 <- tbl_graph(nodes = nodes_play, edges = edges_weights, directed = FALSE, node_key = "speaker")
  
  (ggraph(gr1, layout = 'stress') + 
      geom_edge_link(aes(start_cap = label_rect(node1.speaker),
                         end_cap = label_rect(node2.speaker),
                         width = weight
      ),
      alpha = .25) + 
      geom_node_text(aes(label = speaker)) + 
      labs(caption = paste("Netværksgraf", my_title, my_year)))
  
  ggsave(here("graphs/netvaerksgraf3", paste(my_file, ".function.no-arrows.no-silent-characters.stress.png")))
  
  # Find the characters that are present but do not speak
  present_without_speech(play) -> present_but_silent
  # Here we also need to attach weights
  # We can do that on the basis of act_number and scene_number
  present_but_silent %>% left_join(scene_weights) %>%
      distinct() -> present_but_silent_with_weights
  # Combine with speakers by act and scene and rename
  present_but_silent_with_weights %>%
      rename(from=word, to=speaker) %>% 
      select(from,to,words) %>% 
      filter(!is.na(to)) %>% 
      group_by(from,to) %>% 
      arrange(from,to,words) %>% 
      distinct() %>%
      mutate(weight=sum(words)) -> tmp
  tmp %>% 
      ungroup() %>% 
      select(from,to,weight) %>% 
      distinct() -> silent_edges_with_weights
  
  # Add types to the edges
  edges_weights$type = "speaking"
  silent_edges_with_weights$type = "silent"
  silent_edges_with_weights %>% bind_rows(edges_weights) -> edges_combined
  # Graph without arrows
  gr1 <- tbl_graph(nodes = nodes_play, edges = edges_combined, directed = TRUE, node_key = "speaker")
  ggraph(gr1, layout = 'stress') + # Try out different layouts
    scale_edge_colour_manual(values = c("speaking" = "black", "silent" = "red")) + # Choose your colors manually
    geom_edge_fan(aes(start_cap = label_rect(node1.speaker),
                      end_cap = label_rect(node2.speaker),
                      width = weight,
                      colour = factor(type)),
                  # arrow = arrow(length = unit(2, 'mm'), type = "closed"), # Add arrows
                  alpha = .25) + 
    #    geom_node_point(aes(fill = speaker),shape = 21,size = 5) + # Consider adding knots
    geom_node_text(aes(label = speaker), check_overlap = TRUE) + # Try with and without 
    # check_overlap = TRUE, repel = TRUE
    labs(caption = paste("Netværksgraf", my_title, my_year))
  # Create a PNG file for the graph (`mypng.png`)
  ggsave(here("graphs/netvaerksgraf3", paste(my_file, ".function.no-arrows.stress.check_overlap.png")))

    # Create "third" graph
  gr2 <- tbl_graph(nodes = nodes_play, edges = edges_weights, directed = TRUE, node_key = "speaker")
  gr3 <- tbl_graph(nodes = nodes_play, edges = silent_edges_with_weights, directed = TRUE, node_key = "speaker")
  gr4 <- gr2 %>% 
    mutate(graph = 'reverse') %>% 
    activate(edges) %>% 
    reroute(from = to, to = from)
  gr4 %>% graph_join(gr3) %>% graph_join(gr2) %>%
    ggraph(layout = 'lgl') + # Try out differen layouts
    # There are various possibilities: 'stress' 'dh' 'drl' 'fr' 'gem' 'graphopt' 'kk' 'lgl'
    # 'mds''randomly' m.fl. ## 'mds', 'randomly', and others.
    scale_edge_colour_manual(values = c("speaking" = "black", "silent" = "red")) + # Choose your colors manually
    
    geom_edge_fan(aes(start_cap = label_rect(node1.speaker),
                      end_cap = label_rect(node2.speaker),
                      width = weight,
                      colour = factor(type)),
                  # arrow = arrow(length = unit(2, 'mm'), type = "closed"), # sæt pile på
                  alpha = .25) + 
    #    geom_node_point(aes(fill = speaker),shape = 21,size = 5) + # overvej knuder
    geom_node_text(aes(label = speaker), check_overlap = TRUE) + # prøv med og uden 
    # check_overlap = TRUE, repel = TRUE
    labs(caption = paste("Netværksgraf", my_title, my_year))
  
  # Create a PNG file for the graph (`mypng.png`)
  ggsave(here("graphs/netvaerksgraf3", paste(my_file, ".function.lgl.check_overlap.png")))
  
}