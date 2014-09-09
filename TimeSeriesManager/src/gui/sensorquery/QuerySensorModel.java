package gui.sensorquery;

import gui.util.AbstractModel;
import tsdb.Region;
import tsdb.remote.GeneralStationInfo;

public class QuerySensorModel extends AbstractModel {

	private Region[] regions;
	private GeneralStationInfo[] generalStationInfos;
	private String[] sensorNames;
	private String[] aggregationNames;

	private Region region;
	private GeneralStationInfo generalStationInfo;
	private String sensorName;
	private String aggregationName;
	
	

	public void setRegions(Region[] regions) {
		changeSupport.firePropertyChange("regions", this.regions, this.regions=regions);
	}
	public void setGeneralStationInfos(GeneralStationInfo[] generalStationInfos) {
		changeSupport.firePropertyChange("generalStationInfos", this.generalStationInfos, this.generalStationInfos=generalStationInfos);
	}
	public void setSensorNames(String[] sensorNames) {
		changeSupport.firePropertyChange("sensorNames", this.sensorNames, this.sensorNames=sensorNames);
	}
	public void setAggregationNames(String[] aggregationNames) {
		changeSupport.firePropertyChange("aggregationNames", this.aggregationNames, this.aggregationNames=aggregationNames);
	}


	public void setRegion(Region region) {
		changeSupport.firePropertyChange("region", this.region, this.region=region);
	}
	public void setGeneralStationInfo(GeneralStationInfo generalStationInfo) {
		changeSupport.firePropertyChange("generalStationInfo", this.generalStationInfo, this.generalStationInfo=generalStationInfo);
	}
	public void setSensorName(String sensorName) {		
		if(this.sensorName==null&&sensorName==null) {
			return;
		}		
		changeSupport.firePropertyChange("sensorName", this.sensorName, this.sensorName=sensorName);
	}
	public void setAggregationName(String aggregationName) {			
		changeSupport.firePropertyChange("aggregationName", this.aggregationName, this.aggregationName=aggregationName);
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
	public String[] getAggregationNames() {
		return aggregationNames;
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
	public String getAggregationName() {
		return aggregationName;
	}	
}