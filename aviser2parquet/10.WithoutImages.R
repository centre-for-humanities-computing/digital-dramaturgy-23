library(sparklyr)
library(dplyr)

#install.packages("here")
library(here)
i_am("10.WithoutImages.R")


# The jpg pages in the parquet file are not really useful, so create a parquet file without this column

# Init Spark Connection
conf <- spark_config()
conf$spark.dynamicAllocation.minExecutors <- 20

spark_disconnect_all()

sc <-
  spark_connect(
    master = 'yarn-client',
    app_name = paste("Repackage without images"),
    config = conf
  )

# Read the dataset as written by previous script
aviser <- spark_read_parquet(sc,
                             path = '/projects/p017/parquet/aviser.parquet',
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


without_images <- aviser %>% select(-jpg)


spark_write_parquet(without_images,
                    path=paste0('/projects/p017/',sample_path,'10.WithoutImages.parquet'),
                    mode='overwrite'
)


spark_disconnect(sc)
