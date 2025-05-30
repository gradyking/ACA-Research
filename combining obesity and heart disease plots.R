#cfs
library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(Hmisc)
hrtDisease <- read_csv("./formattedData/formattedAtlasDatawStateSorted.csv")
percentInsured <- read_csv("./formattedData/percentInsured.csv")
obesity <- read_csv(r"(.\formattedData\obesity % 2004-2019.csv)")

#data already has missing values removed, i.e. hrtDisease <- hrtDisease %>% filter_at(vars(X05.07:X18.20), all_vars(.>0))
# percentInsured <- percentInsured %>% filter_at(vars(-combinedfips), all_vars(.>0))

percentInsured <- filter(percentInsured, combinedfips %in% hrtDisease$cnty_fips)
hrtDisease <- filter(hrtDisease, cnty_fips %in% percentInsured$combinedfips)
percentInsured <- filter(percentInsured, combinedfips %in% obesity$cntyfip)
obesity <- filter(obesity, cntyfip %in% percentInsured$combinedfips)
hrtDisease <- filter(hrtDisease, cnty_fips %in% obesity$cntyfip)
obesity <- filter(obesity, cntyfip %in% hrtDisease$cnty_fips)

obesity[2:5] <- NULL #remove county, state, and 2004 and 2005 data
obesity["X20"] <- NULL #remove 2020
hrtDisease[2:3] <- NULL #remove display_name and state
percentInsured["X20"] <- NULL #remove 2020

#standardize names
names(hrtDisease) <- names(percentInsured)
names(obesity) <- names(percentInsured)

#split percentInsured into equally-sized groups based on  this            V and V (g is the number of groups)
# groups <- split(percentInsured, cut(dig.lab = 3, percentInsured$X19, 3)) #even length groups
groups <- split(percentInsured, Hmisc::cut2(percentInsured$X19, g=3)) #even sized groups
# groups <- split(percentInsured, cut(dig.lab = 3, percentInsured$X06, c(0,75,85,100))) #original groups

names(groups) <- c("Low Insurance (64-86.5%)","Medium Insurance (86.5-91.3%)","High Insurance (91.3-97.6%)")

plotSeries = data.frame(year=character(), mean=numeric(), groups=character())
years <- names(hrtDisease)[2:14]
yearsNormal <- as.character((2006:2019))
countYear <- 1
for(x in 1:length(groups)){
  countYear <- 1
  for(year in years){
    mean <- mean(filter(hrtDisease, combinedfips %in% groups[[x]]$combinedfips)[[year]])[1]
    plotSeries <- rbind(plotSeries, data.frame(year=yearsNormal[countYear], mean=mean, group=names(groups)[[x]]))
    countYear <- countYear + 1
  }
}

plotSeries$group <- factor(plotSeries$group,ordered=TRUE, levels=c("Low Insurance (64-86.5%)","Medium Insurance (86.5-91.3%)","High Insurance (91.3-97.6%)"))

cbPalette <- c("#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7", "#999999")

png(filename = 'figures/final paper/figure4.png', units = 'in', width = 8.5, height = 5, res=300, type = c('cairo'))

ggplot(plotSeries, aes(x = year, y = mean, group = group, linetype = group)) + geom_line(linewidth = 1) + geom_vline(xintercept=9.5, linetype='longdash', color='black', size=1) + geom_point(
  size = 3, 
  aes(shape = group), # Type of point that allows us to have both color (border) and fill.
  colour = "black", 
  stroke = 1 # The width of the border, i.e. stroke.
) + scale_shape_manual(values=c(15, 16, 17)) + labs(title = "Average heart disease mortality of county-cohort groups, 2006-2018", 
         x = "Year", 
         y = "Age-standardized mortality rate per 100,000") + theme(plot.title = element_text(size=12)
)

dev.off()

write_csv(plotSeries, 'figures/final paper/figure4data.csv')

plotSeries = data.frame(year=character(), mean=numeric(), groups=character())
years <- names(obesity)[2:14]
yearsNormal <- as.character((2006:2019))
countYear <- 1
for(x in 1:length(groups)){
  countYear <- 1
  for(year in years){
    mean <- mean(filter(obesity, combinedfips %in% groups[[x]]$combinedfips)[[year]])[1]
    plotSeries <- rbind(plotSeries, data.frame(year=yearsNormal[countYear], mean=mean, group=names(groups)[[x]]))
    countYear <- countYear + 1
  }
}

plotSeries$group <- factor(plotSeries$group,ordered=TRUE, levels=c("Low Insurance (64-86.5%)","Medium Insurance (86.5-91.3%)","High Insurance (91.3-97.6%)"))

ggplot(plotSeries, aes(x = year, y = mean, group = group, color = group)) + geom_line(linewidth = 2.4) + geom_point(
  aes(fill = group),
  size = 5,
  pch = 21, # Type of point that allows us to have both color (border) and fill.
  colour = "#FFFFFF",
  stroke = 1 # The width of the border, i.e. stroke.
) + labs(title = "Average Obesity Percentage of County-Cohort Groups, 2006-2018",
         x = "Year",
         y = "% People Who Are Obese") + theme(plot.title = element_text(size=9)
) + scale_fill_manual(values=cbPalette) + scale_colour_manual(values=cbPalette)

#creating plots for the average HDM rate

avgAll <- data.frame(lapply(hrtDisease[,2:15], mean))
avgAll <- pivot_longer(avgAll, 1:14, names_to = "year", values_to = "avgHrt")
avgAll$year <- paste(sep = "", "20",substr(avgAll$year, 2, 4))

png(filename = 'figures/final paper/figure2.png', units = 'in', width = 8.5, height = 5, res=300, type = c('cairo'))

ggplot(avgAll, aes(x = year, y = avgHrt, group=1)) + geom_line(linewidth = 1) + geom_point(
  size = 3,
  pch = 16, # Type of point that allows us to have both color (border) and fill.
  colour = "black",
  stroke = 1 # The width of the border, i.e. stroke.
) + labs(title = "Average heart disease mortality of US counties, 2006-2019",
         x = "Year",
         y = "Age-standardized mortality rate per 100,000") + theme(plot.title = element_text(size=14)
         ) + coord_cartesian(ylim = c(65,80))

dev.off()
write_csv(avgAll, 'figures/final paper/figure2data.csv')

ggplot(avgAll, aes(x = year, y = avgHrt, group=1, color="red")) + geom_line(linewidth = 2.4) + geom_point(
  aes(fill="red"),
  size = 5,
  pch = 21, # Type of point that allows us to have both color (border) and fill.
  colour = "#FFFFFF",
  stroke = 1 # The width of the border, i.e. stroke.
) + labs(title = paste(sep="", "Average Heart Disease Mortality of US Counties, 2006-2019"),
         x = "Year",
         y = "Age-standardized Mortality Rate per 100,000") + theme(plot.title = element_text(size=9)
         ) + scale_fill_manual(values=cbPalette) + scale_colour_manual(values=cbPalette)  + coord_cartesian(ylim = c(0,85))

