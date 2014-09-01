package gui.query;

import gui.util.AbstractModel;

public class QueryModel extends AbstractModel {
	
	private String[] regionLongNames = null;
	private String regionLongName = null;
	
	private String[] generalStationLongNames = null;
	private String generalStationLongName = null;
	
	private String[] plotIDs = null;
	private String plotID = null;
	
	private String[] sensorNames = null;
	private String sensorName = null;
	
	private String[] aggregationNames = null;
	private String aggregationName = null;
	
	public QueryModel() {
		
	}
	
	
	public void setRegionLongNames(String[] regionLongNames) {
		changeSupport.firePropertyChange("regionLongNames", this.regionLongNames, this.regionLongNames=regionLongNames);
	}
	
	public void setRegionLongName(String regionLongName) {
		changeSupport.firePropertyChange("regionLongName", this.regionLongName, this.regionLongName=regionLongName);
	}
	
	public void setGeneralStationLongNames(String[] generalStationLongNames) {
		changeSupport.firePropertyChange("generalStationLongNames", this.generalStationLongNames, this.generalStationLongNames=generalStationLongNames);
	}
	
	public void setGeneralStationLongName(String generalStationLongName) {
		changeSupport.firePropertyChange("generalStationLongName", this.generalStationLongName, this.generalStationLongName=generalStationLongName);
	}
	
	public void setPlotIDs(String[] plotIDs) {
		changeSupport.firePropertyChange("plotIDs", this.plotIDs, this.plotIDs=plotIDs);
	}
	
	public void setPlotID(String plotID) {
		changeSupport.firePropertyChange("plotID", this.plotID, this.plotID=plotID);
	}
	
	public void setSensorNames(String[] sensorNames) {
		changeSupport.firePropertyChange("sensorNames", this.sensorNames, this.sensorNames=sensorNames);
	}
	
	public void setSensorName(String sensorName) {
		changeSupport.firePropertyChange("sensorName", this.sensorName, this.sensorName=sensorName);
	}
	
	public void setAggregationNames(String[] aggregationNames) {
		changeSupport.firePropertyChange("aggregationNames", this.aggregationNames, this.aggregationNames=aggregationNames);
	}
	
	public void setAggregationName(String aggregationName) {
		changeSupport.firePropertyChange("aggregationName", this.aggregationName, this.aggregationName=aggregationName);
	}
	
	
	
	public String[] getRegionLongNames() {
		return regionLongNames;
	}
	
	public String getRegionLongName() {
		return regionLongName;
	}
	
	public String[] getGeneralStationLongNames() {
		return generalStationLongNames;
	}
	
	public String getGeneralStationLongName() {
		return generalStationLongName;
	}
	
	public String[] getPlotIDs() {
		return plotIDs;
	}
	
	public String getPlotID() {
		return plotID;
	}
	
	public String[] getSensorNames() {
		return sensorNames;
	}
	
	public String getSensorName() {
		return sensorName;
	}
	
	
	
	
	
	
	


}
