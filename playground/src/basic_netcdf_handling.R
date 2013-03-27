################################################################################
##  
##  Just a cheat slip for NetCDF handling.
##  
################################################################################
##
##  Copyright (C) 2012 Thomas Nauss
##
##  This program is free software: you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation, either version 3 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program.  If not, see <http://www.gnu.org/licenses/>.
##
##  Please send any comments, suggestions, criticism, or (for our sake) bug
##  reports to admin@environmentalinformatics-marburg.de
##
################################################################################

setwd("D:/temp/ncep_dendro/reanalysis")

#install.packages("RNetCDF")
library("RNetCDF")

# NetCDF-Dateien einlesen (Monatsmittelwerte bzw. Monatssummen)
ncf_t2m = open.nc("air.2m.mon.mean.nc")
ncf_sh2m = open.nc("shum.2m.mon.mean.nc")
ncf_cprat = open.nc("cprat.sfc.mon.mean.nc")
ncf_prate = open.nc("prate.sfc.mon.mean.nc")

# Zusammenfassung der Inhalte der NetCDF-Dateien ausgeben
print.nc(ncf_t2m)
print.nc(ncf_sh2m)
print.nc(ncf_cprat)
print.nc(ncf_prate)

# Variablen aus den NetCDF-Dateien auslesen
# Da das Grid immer identisch ist, kann immer der lat/lon-Wert bzw. die
# lat/lon-Position fuer die 2 m Lufttemperatur auch fuer die anderen Datensaetze
# verwendet werden. Gleiches gilt fuer die Zeitwerte.
lat = var.get.nc(ncf_t2m, "lat")
lon = var.get.nc(ncf_t2m, "lon")
time = var.get.nc(ncf_t2m, "time")
t2m = var.get.nc(ncf_t2m, "air")
sh2m = var.get.nc(ncf_sh2m,"shum")
prate = var.get.nc(ncf_prate,"prate")
cprat = var.get.nc(ncf_cprat,"cprat")

# Zeit von Stunden seit 01.01.01 in "lesbare" Zeit konvertieren
time_hr = utcal.nc("hours since 01-01-01 00:00:00 +01:0",time, type="s")

# cprat in kg/m^2/s konvertieren (Informationen aus NetCDF-Datei, siehe 
# scale_factor und add_offset Ausgabe von print.nc(ncf_cprat)
cprat <- cprat * 1e-07 + 0.0031765

# Array-Position festlegen, fuer die die Variablen ausgelesen werden sollen
# Da die ECSF-Station im noerdlichen Teil des Pixels 151/50 ist, koennte man
# ggf. auch mal die Position 49 auslesen (also ecsf_lat = 49). Hierfuer einfach
# die uebernaechste Zeile von 50 auf 49 aendern.
ecsf_lon = 151
ecsf_lat = 50

# Nur als Test - gibt die lat/lon-Werte der gerade definierten Array-Position
# aus Basis des Temeratur-Datensatzes aus. Falls man mehr ueberpruefen moechte,
# ist auch ein Beispiel fuer den Datensatz zur spezifischen Feuchte angegeben.
print(lon[ecsf_lon])
print(lat[ecsf_lat])
#print(var.get.nc(ncf_sh2m, "lon")[151])
#print(var.get.nc(ncf_sh2m, "lat")[50])

# Meteorologische Parameter fuer die angegebene Array-Position auslesen.
t2m_ecsf <- t2m[ecsf_lon,ecsf_lat,]
sh2m_ecsf <- sh2m[ecsf_lon,ecsf_lat,]
prate_ecsf <- prate[ecsf_lon,ecsf_lat,]
cprat_ecsf <- cprat[ecsf_lon,ecsf_lat,]

# Meteorologische Parameter in Ausgabe-Datenframe schreiben
output = data.frame(time=time_hr,t2m=t2m_ecsf, sh2m=sh2m_ecsf, 
                    prate=prate_ecsf, cprat=cprat_ecsf)
summary(output)

# Schreibe Ausgabe-Datenframe in Datei
write.table(output, file = "test.csv", sep = ",", col.names = NA,
            qmethod = "double")

