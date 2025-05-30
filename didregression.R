library(did)
library(readr)
library(dplyr)
# didTable <- read_csv(r"(C:\Users\Owner\My Drive\RAP\data\finalDIDTable2.csv)")
# didTable <- read_csv(r"(C:\Users\Owner\My Drive\RAP\data\finalDIDTable3.csv)")
# didTable <- read_csv(r"(./test/testnewDidTable.csv)")
didTable <- read_csv("./formattedData/DidTable.csv")
didTable$TREATED <- as.numeric(didTable$TREATED)
as.data.frame(didTable) -> table

table$STATE <- table$GEO_ID %/% 1000

data(mpdta) -> test

time.periods <- 10 #10 years

out <- att_gt(yname = "HRTDISEASE",
              gname = "YEAR_TREATED",
              idname = "GEO_ID",
              tname = "YEAR",
              data = didTable,
              est_method = "reg",
              xformla = ~LOGPOP + LOGEMPLOY,
              control_group="notyettreated"
              )

# summary(out)
# ggdid(out)
agged <- aggte(out, type = "dynamic")
ggdid(agged)

# t <- aggte(formula = HRTDISEASE ~ TREATED | YEAR, id = GEO_ID, data = didTable)
library(did2s)
# first_stage = ~ 0 | region^time + group^time + group^region

#move the counties that expanded in 2019 & 2018 to not expanded
#this is because those counties in the -9 and -8 REL_YEAR made weird coefficient estimates
#and these weren't really representative of the counties as a whole because there are
#only 282 of them, so moving them out helps with that
table$REL_YEAR[table$YEAR_TREATED >= 2018] <- Inf
reg <- did2s(table, 
      yname = "HRTDISEASE",
      first_stage = ~ LOGPOP + LOGEMPLOY + OBESITY + MEDIANINCOME| GEO_ID + YEAR,
      # first_stage = ~ 0 | GEO_ID + YEAR,
      second_stage = ~i(REL_YEAR, ref= c(Inf)),
      treatment = "TREATED",
      cluster_var = "GEO_ID", verbose = TRUE)

# reg <- did2s(table, 
#              yname = "HRTDISEASE",
#              first_stage = ~ MEDIANINCOME | GEO_ID + YEAR,
#              # first_stage = ~ 0 | GEO_ID + YEAR,
#              second_stage = ~i(REL_YEAR, ref= c(Inf)),
#              treatment = "TREATED",
#              cluster_var = "GEO_ID", verbose = TRUE)

#     bootstrap = TRUE,
# n_bootstraps = 50
#       second_stage = ~i(TREATED),
#first_stage = ~ 0 | GEO_ID^YEAR + PERCELIGIBLE^YEAR + GEO_ID^PERCELIGIBLE + LOGPOP + LOGEMPLOY,

png(filename = 'figures/final paper/figure6.png', units = 'in', width = 8.5, height = 5, res=300, type = c('cairo'))

fixest::coefplot(
  reg,
  main = "Estimated effect of Medicaid on heart disease mortality",
  xlab = "Relative number of years from Medicaid expansion",
  col = "grey20", lwd = 2
)
dev.off()

esttable(reg)
# summary(reg)

###############################################
#splitting the did regression by low, medium, and high insurance rates in 2019
#based on "combining obesity and heart disease plots.R"
percentInsured <- read_csv("./formattedData/percentInsured.csv")

percentInsured <- filter(percentInsured, combinedfips %in% didTable$GEO_ID)

#split percentInsured into equally-sized groups based on  this    V and V (g is the number of groups)
# groups <- split(percentInsured, cut(dig.lab = 3, percentInsured$X19, 3)) #even length groups
groups <- split(percentInsured, Hmisc::cut2(percentInsured$X06, g=3)) #even sized groups
# groups <- split(percentInsured, cut(dig.lab = 3, percentInsured$X06, c(0,75,85,100))) #original groups

# names(groups) <- c("Low Insurance (64.2-86.8%)","Medium Insurance (86.8-91.2%)","High Insurance (91.2-97.6%)")
names(groups) <- paste(sep = "", c("Low", "Medium", "High"), " insurance (", substr(names(groups),2,5), "-", substr(names(groups), 7, 10), "%) in 2006")
names(groups) <- tolower(names(groups))
nameExtensions <- c('7','8','9a')

for(groupIndex in 1:length(groups)){
  groupedTable <- table %>% filter(GEO_ID %in% groups[[groupIndex]]$combinedfips)
  reg <- did2s(groupedTable, 
               yname = "HRTDISEASE",
               first_stage = ~ LOGPOP + LOGEMPLOY + OBESITY | GEO_ID + YEAR,
               # first_stage = ~ 0 | GEO_ID + YEAR,
               second_stage = ~i(REL_YEAR, ref= c(Inf)),
               treatment = "TREATED",
               cluster_var = "GEO_ID", verbose = TRUE)
  
  png(filename = paste0('figures/final paper/figure',nameExtensions[groupIndex],'.png'), units = 'in', width = 8.5, height = 5, res=300, type = c('cairo'))
  
  fixest::coefplot(
    reg,
    main = paste("Estimated effect of Medicaid on heart disease mortality\nfor", names(groups)[groupIndex]),
    xlab = "Relative number of years from Medicaid expansion",
    col = "grey20", lwd = 2
  )
  dev.off()
}
png(filename = 'figures/final paper/figure9b.png', units = 'in', width = 8.5, height = 5, res=300, type = c('cairo'))

fixest::coefplot(
  reg,
  main = paste("Estimated effect of Medicaid on heart disease mortality\nfor", names(groups)[groupIndex], "\n(modified Y-axis)"),
  xlab = "Relative number of years from Medicaid expansion",
  col = "grey20", lwd = 2, ylim.add = c(0.5,0)
)
dev.off()

for(x in 1:length(groups)){
  print(names(groups)[x])
  groupedTable <- table %>% filter(GEO_ID %in% groups[[x]]$combinedfips)
  print("number of non-expansion counties:")
  print(dim(groupedTable %>% filter(REL_YEAR == Inf))[1]/10)
  print("number of expansion counties:")
  print(dim(groupedTable %>% filter(REL_YEAR != Inf))[1]/10)
}


# looking at bacondecomp

library(bacondecomp)

#bacon decomp without controls

df_bacon <- bacon(HRTDISEASE ~ TREATED,
                  data = table,
                  id_var = "GEO_ID",
                  time_var = "YEAR")

ggplot(df_bacon) +
  aes(x = weight, y = estimate, shape = factor(type)) +
  labs(x = "Weight", y = "Estimate", shape = "Type") +
  geom_point()

write_csv(df_bacon, "./baconDecomp/baconDecompNoControls.csv")

#bacon decomp with pop and employ, no obesity

df_bacon_controls <- bacon(HRTDISEASE ~ TREATED + LOGPOP + LOGEMPLOY,
                  data = table,
                  id_var = "GEO_ID",
                  time_var = "YEAR")

ggplot(df_bacon_controls$two_by_twos) +
  aes(x = weight, y = estimate, shape = factor(type)) +
  labs(x = "Weight", y = "Estimate", shape = "Type") +
  geom_point()

write_csv(as.data.frame(df_bacon_controls[1:2]), "./baconDecomp/baconDecompControlsNoObesityotherTwo.csv")
write_csv(df_bacon_controls$two_by_twos, "./baconDecomp/baconDecompControlsNoObesity2x2.csv")

#bacon decomp with pop, employ, and obesity

df_bacon_controls <- bacon(HRTDISEASE ~ TREATED + LOGPOP + LOGEMPLOY + OBESITY,
                           data = table,
                           id_var = "GEO_ID",
                           time_var = "YEAR")

# using did2s event_study to compare all the estimators

table <- table %>% filter(YEAR_TREATED < 2020)

#without covariates

studies <- event_study(data = table,
                       yname = "HRTDISEASE",
                       idname = "GEO_ID",
                       gname = "YEAR_TREATED",
                        tname = "YEAR",
                       estimator = "all")

plot_event_study(studies)

#with covariates, no obesity



studiesCo <- event_study(data = table,
                       yname = "HRTDISEASE",
                       idname = "GEO_ID",
                       gname = "YEAR_TREATED",
                       tname = "YEAR",
                       estimator = "all",
                       xformla = ~ LOGPOP + LOGEMPLOY)

plots <- plot_event_study(studiesCo)

for(i in 1:length(x)){
  
}

studiesallCo <- event_study(data = table,
                         yname = "HRTDISEASE",
                         idname = "GEO_ID",
                         gname = "YEAR_TREATED",
                         tname = "YEAR",
                         estimator = "all",
                         xformla = ~ LOGPOP + LOGEMPLOY + OBESITY)

plot_event_study(studiesallCo)

print(studies$estimate - studiesCo$estimate)

studiesCo <- event_study(data = table,
                         yname = "HRTDISEASE",
                         idname = "GEO_ID",
                         gname = "YEAR_TREATED",
                         tname = "YEAR",
                         estimator = "all",
                         xformla = ~ LOGPOP + LOGEMPLOY)

plot_event_study(studiesCo)


########################
#synthetic control
library(synthdid)
#trying out a synth did to see what difference it makes
#https://synth-inference.github.io/synthdid/articles/synthdid.html
synthTable <- filter(table, YEAR_TREATED == 0 | YEAR_TREATED == 2014 | YEAR_TREATED > 2018)
synthTable[synthTable$YEAR_TREATED>2018,]$TREATED <- 0
setup <- synthdid::panel.matrices(as.data.frame(synthTable), unit = 1, time = 2, treatment = 3, outcome = 6)
tau.hat = synthdid_estimate(setup$Y, setup$N0, setup$T0)
print(x <- summary(tau.hat))
synthdid_plot(tau.hat)
synthdid_plot(tau.hat, overlay = 1)
y <- synthdid_controls(tau.hat)
synthdid_units_plot(tau.hat)

#attempt to add median income to the SDID regression

library(tidyr)
covariateTable <- select(table, c(`GEO_ID`, `YEAR`, `MEDIANINCOME`)) %>% pivot_wider(names_from= "YEAR", values_from = "MEDIANINCOME")
covariateTable <- as.data.frame(covariateTable)
filter(covariateTable, GEO_ID %in% rownames(setup$Y))
rownames(covariateTable) <- covariateTable$GEO_ID
covariateTable <- covariateTable[match(rownames(setup$Y), rownames(covariateTable)), ]
covariateTable$GEO_ID <- NULL
# covariateArray <- array(as.list(covariateTable, all.names = TRUE))
# View(array(covariateTable, dim = c(1, 10, 2807)))
mCT <- as.matrix(covariateTable)
mCT <- log(mCT)

tau.hat2 = synthdid_estimate(setup$Y, setup$N0, setup$T0, X = mCT)
print(x2 <- summary(tau.hat2))
synthdid_plot(tau.hat2)
y2 <- synthdid_controls(tau.hat2)

#############################################3333
#finding the estimated number of people that could've been saved if the states that never expanded medicaid expanded in 2014
library(dplyr)
library(readr)
nonExpandTable <- filter(didTable, YEAR_TREATED == 0 | YEAR_TREATED >= 2018)
nonExpandTable <- filter(nonExpandTable, YEAR >= 2014 & YEAR <= 2019)

nonExpandTable$DEATHS <- nonExpandTable$HRTDISEASE * (exp(nonExpandTable$LOGPOP) / 100000) #calculate estimated deaths based on the heart disease mortality per 100000 rate, and the ln population columns
didCoef <- parse_number(esttable(reg)[9:14,2]) #extract coefficients of did2s regression, would have to run lines 7-9 and 33-47 to get the reg object
noMedicaid <- sum(nonExpandTable$DEATHS)

#subtracts the didCoefficients from the HRTDISEASE rate of every year from 2014 to 2018
years <- 2014:2019
for(i in 1:6){
nonExpandTable$HRTDISEASE[nonExpandTable$YEAR == years[i]] <- nonExpandTable$HRTDISEASE[nonExpandTable$YEAR == years[i]] + didCoef[i]
}
nonExpandTable$DEATHS <- nonExpandTable$HRTDISEASE * (exp(nonExpandTable$LOGPOP) / 100000) #rerun death calculation
withMedicaid <- sum(nonExpandTable$DEATHS)
print(noMedicaid-withMedicaid)
