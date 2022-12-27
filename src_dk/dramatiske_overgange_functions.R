# Dramatiske overgange

library(tidyverse)
library(ndjson)
library(here)

# Find første sætning i hver scene.
first_sentence_func <- function(play) {
  first_sentence <- play %>%
    #Group by så vi håndterer hver scene for sig
    group_by(act_number, scene_number) %>%
    #Filtrer alle linier som ikke er replikker fra
    filter(!is.na(spoke)) %>%
    # Sorter i hver gruppe, så linierne kommer i rækkefølge
    arrange(index, .by_group = TRUE) %>%
    # Lav et ny index i hver gruppe, startende med den første.
    # På den måde ved jeg at den første i hver gruppe er nr 1.
    mutate(group_row_num = row_number()) %>%
    # Kun behold den første i hver gruppe
    filter(group_row_num == 1) %>%
    # Fjern gruppe index for det er ikke relevant længere
    select(- group_row_num )
  
  return(first_sentence)
}

# Find sidste sætning i hver scene.
last_sentence_func <- function(play) {
  last_sentence <- play %>%
    #Group by så vi håndterer hver scene for sig
    group_by(act_number, scene_number) %>%
    #Filtrer alle linier som ikke er replikker fra
    filter(!is.na(spoke)) %>%
    # Sorter i hver gruppe, så linierne kommer i omvendt rækkefølge
    arrange(desc(index), .by_group = TRUE) %>%
    # Lav et ny index i hver gruppe, startende med den sidste.
    # På den måde ved jeg at den sidste i hver gruppe er nr 1.
    mutate(group_row_num = row_number()) %>%
    # Kun behold den sidste i hver gruppe
    filter(group_row_num == 1) %>%
    # Fjern gruppe index for det er ikke relevant længere
    select(- group_row_num )
  
  return(last_sentence)
}


