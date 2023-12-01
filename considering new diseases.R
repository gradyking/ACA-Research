library(readr)

mortalityList <- lapply(
                      list.files(full.names=TRUE, 
                      path = "./rawData/Considering New Diseases/By 113 Cause List", 
                      pattern = "*.txt"), 
                      read_delim,
                      delim = "\t", escape_double = FALSE, 
                      trim_ws = TRUE)

#remove all the comments at the bottom of the file, by removing all rows below "---" in the Notes column
for(i in 1:length(mortalityList)){
  mortalityList[[i]] <- mortalityList[[i]][1:(which(mortalityList[[i]]$Notes == "---")[1] - 1),]
}

library(dplyr)
library(tidyr)
mortalityTable <- bind_rows(mortalityList)

#create complete table with all possible combinations
counties <- read_delim("./rawData/Considering New Diseases/By 113 Cause List/unique county and 113 cause list indicators/split only by county.txt", delim = "\t", trim_ws = TRUE)
causelist <- read_delim("./rawData/Considering New Diseases/By 113 Cause List/unique county and 113 cause list indicators/split only by 113 cause list.txt", delim = "\t", trim_ws = TRUE)

complete_table <- expand_grid(
  county = unique(counties$`County Code`),
  year = 2010:2019,
  cause = unique(causelist$`ICD-10 113 Cause List`)
)

fixedMortalityTable <- rename(mortalityTable, 'county' = "County Code", 'cause' = "ICD-10 113 Cause List", 'year' = "Year")

# Join the complete tibble with the original tibble
joined_tibble <- left_join(complete_table, fixedMortalityTable, by = c("county", "year", "cause"))

# Group by ICD-10 113 causes
grouped_tibble <- group_by(joined_tibble, cause)

# Summarize the percentage of missing datapoints for each cause
summary_tibble <- summarize(grouped_tibble, missing_percent = round(mean(is.na(Deaths)) * 100, 2))

# View the summary tibble
write_csv(summary_tibble, "./formattedData/newDiseasesMissingPercent.csv")
