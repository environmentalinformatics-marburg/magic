dat_prcp_kia_mos

oni_mlt$ONI

lapply(c(2, 3, 6), function(i) {
  Find_Max_CCF(oni_mlt$ONI, dat_prcp_kia_mos[, i], lag.max = 6)
})

lapply(c(2, 3, 6), function(i) {
  Find_Max_CCF(dat_dmi$DMI, dat_prcp_kia_mos[, i], lag.max = 4)
})

head(oni_mlt)
head(dat_dmi)

ggplot() + 
  geom_line(aes(x = Date, y = ONI), data = oni_mlt, colour = "black") + 
  geom_line(aes(x = Date, y = DMI), data = dat_dmi, colour = "grey50") + 
  theme_bw()

ccf(dat_dmi$DMI, oni_mlt$ONI, na.action = na.omit)

Find_Max_CCF(dat_dmi$DMI, oni_mlt$ONI)
cor(lag(oni_mlt$ONI[1:length(dat_dmi$DMI)], 2), dat_dmi$DMI, 
    use = "complete.obs")
cor(lag(dat_dmi$DMI, 2), oni_mlt$ONI[1:length(dat_dmi$DMI)], 
    use = "complete.obs")
mod <- lm(oni_mlt$ONI[1:length(dat_dmi$DMI)] ~ lag(dat_dmi$DMI, 2))
summary(mod)$coefficients[2, 4]
