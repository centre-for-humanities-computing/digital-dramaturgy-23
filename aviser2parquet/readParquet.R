library(sparklyr)
library(dplyr)

#Utility method to get a value from a column
parquet.column.value <- function(table, column, i) {
    unlist((table %>% select(column) %>% collect())[i,], use.names=FALSE)
}


#connect spark
spark_disconnect_all()
sc <-
spark_connect(master = 'yarn-client', app_name = paste("Parquet read"))


#Open Parquet archive, but do not cache it (but this might be a good idea...)
parquet <- spark_read_parquet(sc,
"main_parquet",
path = paste0("hdfs://KAC/projects/p017/parquet/aviser.parquet"),
memory = FALSE,
overwrite = TRUE)

#See the column names
colnames(parquet)

#See the schema
sdf_schema(parquet)
head_pages <- parquet %>% head() %>% collect()
#Count pages
parquet %>% tally()



#Get the name of the "first" page (random sorting)
first_name <- parquet.column.value(parquet %>% head(2), "name",2)
first_name



#Viewing images

#Install image magick to display pages
#install.packages("magick")
library(magick)

#download jpg data for a random entry
image_data <- parquet.column.value(parquet %>% head(2), "jpg",2)

#download jpg data for a specific entry
image_data <- parquet.column.value(parquet %>% filter(name==first_name), "jpg")
#Parse it
image <- image_read(image_data)
#Show it
image_info(image)
image_attributes(image)
image

#TODO I have not managed to get magick to work inside a spark_apply, so this cannot be used at scale.



# Regexp on text

# See https://cwiki.apache.org/confluence/display/Hive/LanguageManual+UDF#LanguageManualUDF-StringOperators
pages_with_tidende <- parquet %>% filter(txt %REGEXP% 'tidende')

#Count them
tally(pages_with_tidende)

#Get a few (without the jpg column as it breaks the view)
View(pages_with_tidende %>% head() %>% select(-jpg) %>% collect())
