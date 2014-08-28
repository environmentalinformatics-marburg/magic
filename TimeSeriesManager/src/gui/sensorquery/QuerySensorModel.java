package gui.sensorquery;

import gui.util.AbstractModel;
import tsdb.GeneralStation;
import tsdb.Region;
import tsdb.remote.GeneralStationInfo;

public class QuerySensorModel extends AbstractModel {

	private Region[] regions;
	private GeneralStationInfo[] generalStationInfos;
	private String[] sensorNames;

	private Region region;
	private GeneralStationInfo generalStationInfo;
	private String sensorName;

	public void setRegions(Region[] regions) {
		changeSupport.firePropertyChange("regions", this.regions, this.regions=regions);
	}
	public void setGeneralStationInfos(GeneralStationInfo[] generalStationInfos) {
		changeSupport.firePropertyChange("generalStationInfos", this.generalStationInfos, this.generalStationInfos=generalStationInfos);
	}
	public void setSensorNames(String[] sensorNames) {
		changeSupport.firePropertyChange("sensorNames", this.sensorNames, this.sensorNames=sensorNames);
	}


	public void setRegion(Region region) {
		changeSupport.firePropertyChange("region", this.region, this.region=region);
	}
	public void setGeneralStationInfo(GeneralStationInfo generalStationInfo) {
		changeSupport.firePropertyChange("generalStationInfo", this.generalStationInfo, this.generalStationInfo=generalStationInfo);
	}
	public void setSensorName(String sensorName) {
		changeSupport.firePropertyChange("sensorName", this.sensorName, this.sensorName=sensorName);
	}


	public Region[] getRegions() {
		return regions;
	}
	public GeneralStationInfo[] getGeneralStationInfos() {
		return generalStationInfos;
	}
	public String[] getSensorNames() {
		return sensorNames;
	}


	public Region getRegion() {
		return region;
	}
	public GeneralStationInfo getGeneralStationInfo() {
		return generalStationInfo;
	}
	public String getSensorName() {
		return sensorName;
	}		
}