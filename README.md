﻿Welcome!

I'm Grady King, and this is my repository for my research project investigating the impact of public insurance policy on mortality from disease. 

The first project was investigating the impact of the expansion of Medicaid from the 2014 Affordable Care Act on heart disease mortality, which I did during the WVU Research Apprenticeship Program and WVU Summer Undergraduate Research Experience during the spring and summer of 2023. I worked under Dr. Srinivas Palanki during the spring and summer. Now we are seeking to expand the research, specifically investigating the change in eligibility requirements, as the primary qualification for Medicaid is the person's income relative to the federal poverty line (FPL). This eligibility was different across states before Medicaid expansion, and so the effect of the ACA was different between states. We'll be investigating this, and seeing if we can find the impact of this, in the near future. 

As a disclaimer, I am a beginner at R, only using it since January, so my code might be suboptimal, and I am also not a statistician or econometrician, so my methodology might be shaky. I think I got better as I went through the project though.

Check out my final SURE poster in `poster/` if you're interested! A research publication is in the works, and will hopefully be published soon.

The main two causal inference estimators I used were a staggered two-stage difference-in-difference (did2s) for nationwide analysis and synthetic difference-in-difference (synthdid) for the adjacent state analyses due to its robustness in smaller settings.

## Code Organization
The final figures in my paper, and where they were created is in `figures/final paper/README.md`. 

This project is not fantastically organized, but it is separated okay-ish. All of my R source files are in the main folder, along with my RStudio project file and associated files with that. The `figures/` folder has all of the plots and maps I generated during the project, and the `poster/` folder has all the files I used to make my poster for the summer undergrad symposium. `rawData/` has some raw files from certain sources, which should all have a link.txt file describing where I got the data. `formattedData/` is kind of a weird folder, because it has some imported data from my previous project during the spring, as well as some cleaned data that I created during the project. Most of my R code uses data from this folder, or formats data to be put into this folder. If you have any questions on where I obtained some of this data, feel free to email me!

`notes/` has personal notes that I wrote for each week, some of which are probably pretty whiny, I wouldn't recommend reading them. `renv/` is a folder that contains renv information, which essentially keeps track of all the libraries I used during the project so that other people can easily download them. `adjacentCountiesData/`, `baconDecomp/`, and `socialFactorData/` are all small subsections of the project or minor offshoots, adjacent counties results are in figures/comparing adjacent states, and social factor results are in figures/social factor plots. baconDecomp just has some results of a Bacon decomposition, which was just one of my side projects to understand two-way fixed effects (TWFE) more.

## Using the code
This code uses **R version 4.2.3**, make sure to use that version if you're trying to run code. The required R packages and their versions are stored in renv, so one just needs to run `renv::restore()` to install the correct versions of the libraries (it might take a while). Make sure you have [Rtools42 installed](https://cran.r-project.org/bin/windows/Rtools/rtools42/rtools.html) so that you have the `make` utility to compile some of the libraries that require building from their source.

# Contact
Check my [main GitHub page](https://github.com/gradyking) for updated contact info.

