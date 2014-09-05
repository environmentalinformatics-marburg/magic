package gui.export;

import tsdb.remote.PlotInfo;
import gui.util.AbstractModel;

public class CollectorModel extends AbstractModel {
	
	private String[] allRegionLongNames;
	private String regionLongName = null;
	
	private String[] allSensorNames;
	private String[] querySensorNames;
	
	private PlotInfo[] allPlotInfos;
	private PlotInfo[] queryPlotInfos;
	
	public void setRegionLongName(String regionLongName) {
		changeSupport.firePropertyChange("regionLongName", this.regionLongName, this.regionLongName=regionLongName);
	}
	
	public String getRegionLongName() {
		return regionLongName;
	}
	
	public void setAllRegionLongNames(String[] allRegionLongNames) {
		changeSupport.firePropertyChange("allRegionLongNames", this.allRegionLongNames, this.allRegionLongNames=allRegionLongNames);
	}
	
	public String[] getAllRegionLongNames() {
		return allRegionLongNames;
	}
	
	public void setAllSensorNames(String[] allSensorNames) {
		changeSupport.firePropertyChange("allSensorNames", this.allSensorNames, this.allSensorNames=allSensorNames);
	}
	
	public String[] getAllSensorNames() {
		return allSensorNames;
	}
	
	public void setQuerySensorNames(String[] querySensorNames) {
		changeSupport.firePropertyChange("querySensorNames", this.querySensorNames, this.querySensorNames=querySensorNames);
	}
	
	public String[] getQuerySensorNames() {
		return querySensorNames;
	}
	
	public void setAllPlotInfos(PlotInfo[] allPlotInfos) {
		changeSupport.firePropertyChange("allPlotInfos", this.allPlotInfos, this.allPlotInfos=allPlotInfos);
	}
	
	public PlotInfo[] getAllPlotInfos() {
		return allPlotInfos;
	}
	
	public void setQueryPlotInfos(PlotInfo[] queryPlotInfos) {
		changeSupport.firePropertyChange("queryPlotInfos", this.queryPlotInfos, this.queryPlotInfos=queryPlotInfos);
	}
	
	public PlotInfo[] getQueryPlotInfos() {
		return queryPlotInfos;
	}	

}
