package gui.sensorquery;

import gui.util.AbstractModel;
import timeseriesdatabase.GeneralStation;
import timeseriesdatabase.Region;

public class QuerySensorModel extends AbstractModel {

	private Region[] regions;
	private GeneralStation[] generalStations;
	private String[] sensorNames;

	private Region region;
	private GeneralStation generalStation;
	private String sensorName;

	public void setRegions(Region[] regions) {
		changeSupport.firePropertyChange("regions", this.regions, this.regions=regions);
	}
	public void setGeneralStations(GeneralStation[] generalStations) {
		changeSupport.firePropertyChange("generalStations", this.generalStations, this.generalStations=generalStations);
	}
	public void setSensorNames(String[] sensorNames) {
		changeSupport.firePropertyChange("sensorNames", this.sensorNames, this.sensorNames=sensorNames);
	}


	public void setRegion(Region region) {
		changeSupport.firePropertyChange("region", this.region, this.region=region);
	}
	public void setGeneralStation(GeneralStation generalStation) {
		changeSupport.firePropertyChange("generalStation", this.generalStation, this.generalStation=generalStation);
	}
	public void setSensorName(String sensorName) {
		changeSupport.firePropertyChange("sensorName", this.sensorName, this.sensorName=sensorName);
	}


	public Region[] getRegions() {
		return regions;
	}
	public GeneralStation[] getGeneralStations() {
		return generalStations;
	}
	public String[] getSensorNames() {
		return sensorNames;
	}


	public Region getRegion() {
		return region;
	}
	public GeneralStation getGeneralStation() {
		return generalStation;
	}
	public String getSensorName() {
		return sensorName;
	}		
}