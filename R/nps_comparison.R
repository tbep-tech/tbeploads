library(tidyverse)

comp <- read.csv(file="./data/jei_tbep_load_comparison_2021.csv") %>%
        filter (month != "TOTAL") %>%
        mutate(mo = as.numeric(month)) %>%
        group_by(bay_segment)

check <- comp %>%
         ggplot(aes(x = mo)) +
                 geom_line(aes(y = jei_tn_load, color = "JEI")) +
                 geom_line(aes(y = tbep_tn_load, color = "TBEP")) +
                 scale_x_continuous(breaks=seq(1,12,by=1)) +
                 facet_wrap(~ bay_segment, scales = "free") +
                 labs(x = "Month", y = "TN Load (tons)")

check
