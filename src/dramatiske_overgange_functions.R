# Dramatic transitions

library(tidyverse)
library(ndjson)
library(here)

# Find the first line in each scene
first_sentence_func <- function(play) {
  first_sentence <- play %>%
    # Group by so that we deal with each scene on its own
    group_by(act_number, scene_number) %>%
    # Filter out all lines that are not character-lines
    filter(!is.na(spoke)) %>%
    # Sort each group so that lines are shown in order
    arrange(index, .by_group = TRUE) %>%
    # Make a new index for each group, starting with the first
    # That way we will know that the first in each group is number 1
    mutate(group_row_num = row_number()) %>%
    # Keep only the first in each group
    filter(group_row_num == 1) %>%
    # Remove the group index since it is no longer needed
    select(- group_row_num )
  
  return(first_sentence)
}

# Find the last line in each scene
last_sentence_func <- function(play) {
  last_sentence <- play %>%
    # Group by so that we deal with each scene on its own
    group_by(act_number, scene_number) %>%
    # Filter out all lines that are not character-lines
    filter(!is.na(spoke)) %>%
    # Sort each group so that lines are shown in the reversed order
    arrange(desc(index), .by_group = TRUE) %>%
    # Make a new index for each group, starting with the last
    # That way we will know that the last in each group is number 1
    mutate(group_row_num = row_number()) %>%
    # Keep only the last in each group
    filter(group_row_num == 1) %>%
    # Remove the group index since it is no longer needed
    select(- group_row_num )
  
  return(last_sentence)
}


