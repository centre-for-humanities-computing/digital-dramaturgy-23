library(sparklyr)
library(dplyr)

# Script to parse and split the name column into paper, year, month, day, page

#install.packages("here")
library(here)
i_am("30.pagesize.R")


# Init Spark Connection
conf <- spark_config()
conf$spark.dynamicAllocation.minExecutors <- 20

spark_disconnect_all()

sc <-
  spark_connect(
    master = 'yarn-client',
    app_name = paste("Analyse_aviser"),
    config = conf
  )

# Read the dataset as written by previous script
aviser <- spark_read_parquet(sc,
                             path = '/projects/p017/20.WithDates.parquet',
                             memory = FALSE,
                             repartition = 0)



sample <- FALSE
sample_path <- ""

# If sample = TRUE, only work on a 1% dataset. This is radically faster than the full dataset, and useful for developing.
if (sample){
  sample_path <- "sample/"
  aviser <- sdf_sample(aviser, fraction = 0.01, replacement = FALSE)
}
aviser <- aviser %>% compute(name="aviser")
aviser %>% head() %>% collect() %>% View()

# PAGE sizes
aviser %>% mutate(
     page_alto = regexp_extract(xml, "(<Page[^>]*>)+", 1),
     page_height = as.integer(regexp_extract(page_alto, "HEIGHT=\"([^\"]+)\"", 1)),
     page_width = as.integer(regexp_extract(page_alto, "WIDTH=\"([^\"]+)\"", 1)),
   ) %>% 
   # PrintSpace Sizes
   mutate(
     printspace_alto = regexp_extract(xml, "(<PrintSpace[^>]*>)+", 1),
     printspace_height = as.integer(regexp_extract(printspace_alto, "HEIGHT=\"([^\"]+)\"", 1)),
     printspace_width = as.integer(regexp_extract(printspace_alto, "WIDTH=\"([^\"]+)\"", 1))
   ) %>%
   #Lowercasing
   mutate(
     txt_lower = lower(txt)
   ) -> aviser_with_pagesize

aviser_with_pagesize %>% head() %>% collect() %>% View()
spark_write_parquet(aviser_with_pagesize,
                    path=paste0('/projects/p017/',sample_path,'30.pagesize.parquet'),
                    mode='overwrite'
)





