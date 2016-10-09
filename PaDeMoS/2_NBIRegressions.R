##
library(hsdar)
load("/home/lehnert/Öffentlich/Dropbox/Paper_Hanna/datausw/TotalDataSet/Speclib20112012.RData")
Speclib_all<-speclib(spectra=Speclib_all$spectra,wavelength=Speclib_all$wavelength,attributes=Speclib_all$attributes)

##############################################################################
#####Preprocessing
##############################################################################
###resample to reduuce number of bands (otherise data set too large)
Speclib_all<-spectral.resampling(Speclib_all, sensor = data.frame(lb=seq(305,1700,5), ub = seq(310,1705,5)))



#mask:
#mask(Speclib_all) <- data.frame(lb=c(1040,1300),ub=c(1060,1450))
mask(Speclib_all) <- data.frame(lb=c(1001),ub=c(1705))
##############################################################################
###nri for all combinations
##############################################################################
nri_All <- nri(Speclib_all, recursive = TRUE)
save(nri_All ,file="/home/lehnert/Öffentlich/Dropbox/Paper_Hanna/datausw/NRIResults/nri_All.RData")
###correlate to env variables
lm_nri_Veg_All <- lm.nri( VegCover~nri_All , preddata = Speclib_all)
save(lm_nri_Veg_All ,file="/home/lehnert/Öffentlich/Dropbox/Paper_Hanna/datausw/NRIResults/LM_NRI_Veg_All.RData")

lm_nri_Bio_All <- lm.nri(biomass ~nri_All , preddata = Speclib_all)
save(lm_nri_Bio_All ,file="/home/lehnert/Öffentlich/Dropbox/Paper_Hanna/datausw/NRIResults/LM_NRI_Bio_All.RData")

##############################################################################
###nri for WV
##############################################################################
spec_WV <- spectral.resampling(Speclib_all, "WorldView2-8",
                               response_function = FALSE)
nri_WV <- nri(spec_WV, recursive = TRUE)
save(nri_WV ,file="/home/lehnert/Öffentlich/Dropbox/Paper_Hanna/datausw/NRIResults/nri_WV.RData")

###correlate to env variables
lm_nri_Veg_WV <- lm.nri(VegCover ~nri_WV , preddata = spec_WV)
save(lm_nri_Veg_WV ,file="/home/lehnert/Öffentlich/Dropbox/Paper_Hanna/datausw/NRIResults/LM_NRI_Veg_WV.RData")
lm_nri_Bio_WV <- lm.nri(biomass~nri_WV, preddata = spec_WV)
save(lm_nri_Bio_WV ,file="/home/lehnert/Öffentlich/Dropbox/Paper_Hanna/datausw/NRIResults/LM_NRI_Bio_WV.RData")

##############################################################################
###nri for QB
##############################################################################

spec_QB <- spectral.resampling(Speclib_all, "Quickbird",
                               response_function = FALSE)
nri_QB <- nri(spec_QB, recursive = TRUE)
save(nri_QB ,file="/home/lehnert/Öffentlich/Dropbox/Paper_Hanna/datausw/NRIResults/nri_QB.RData")
###correlate to env variables
lm_nri_Veg_QB <- lm.nri(VegCover ~ nri_QB, preddata = spec_QB)
save(lm_nri_Veg_QB ,file="/home/lehnert/Öffentlich/Dropbox/Paper_Hanna/datausw/NRIResults/LM_NRI_Veg_QB.RData")
lm_nri_Bio_QB <- lm.nri( biomass~nri_QB , preddata = spec_QB)
save(lm_nri_Bio_QB ,file="/home/lehnert/Öffentlich/Dropbox/Paper_Hanna/datausw/NRIResults/LM_NRI_Bio_QB.RData")

##############################################################################
###nri for RE
##############################################################################

spec_RE <- spectral.resampling(Speclib_all, "RapidEye",
                               response_function = FALSE)
nri_RE <- nri(spec_RE, recursive = TRUE)

save(nri_RE ,file="/home/lehnert/Öffentlich/Dropbox/Paper_Hanna/datausw/NRIResults/nri_RE.RData")

###correlate to env variables
lm_nri_Veg_RE <- lm.nri( VegCover~nri_RE , preddata = spec_RE)
save(lm_nri_Veg_RE ,file="/home/lehnert/Öffentlich/Dropbox/Paper_Hanna/datausw/NRIResults/LM_NRI_Veg_RE.RData")
lm_nri_Bio_RE <- lm.nri(biomass ~nri_RE , preddata = spec_RE)
save(lm_nri_Bio_RE ,file="/home/lehnert/Öffentlich/Dropbox/Paper_Hanna/datausw/NRIResults/LM_NRI_Bio_RE.RData")

##################################################################################################################

