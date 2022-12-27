library(sparklyr)
library(dplyr)

# Script to parse and split the name column into paper, year, month, day, page

#install.packages("here")
library(here)
i_am("20.WithDates.R")


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
                             path = '/projects/p017/10.WithoutImages.parquet',
                             memory = FALSE,
                             repartition = 0)



sample <- FALSE
sample_path <- ""

# If sample = TRUE, only work on a 1% dataset. This is radically faster than the full dataset, and useful for developing.
if (sample){
  sample_path <- "sample/"
  aviser <- sdf_sample(aviser, fraction = 0.01, replacement = FALSE)
}
# aviser <- aviser %>% compute(name="aviser")

name_pattern <- "^([^_]+)_(\\\\d{4})(\\\\d{2})(\\\\d{2})_page_(\\\\d+)$"
with_dates <- aviser %>%
  mutate(
    paper=regexp_extract(name, !!name_pattern , 1),
    year=as.integer(regexp_extract(name,!!name_pattern, 2)),
    month=as.integer(regexp_extract(name, !!name_pattern, 3)),
    day=as.integer(regexp_extract(name, !!name_pattern, 4)),
    page=as.integer(regexp_extract(name, !!name_pattern, 5))
  )



spark_write_parquet(with_dates,
                    path=paste0('/projects/p017/',sample_path,'20.WithDates.parquet'),
                    mode='overwrite'
)

