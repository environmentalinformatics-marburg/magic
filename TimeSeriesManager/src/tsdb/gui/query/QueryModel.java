package tsdb.gui.query;

import tsdb.gui.util.AbstractModel;
import tsdb.remote.PlotInfo;

public class QueryModel extends AbstractModel {
	
	private String[] regionLongNames = null;
	private String regionLongName = null;
	
	private String[] generalStationLongNames = null;
	private String generalStationLongName = null;
	
	private PlotInfo[] plotInfos = null;
	private PlotInfo plotInfo = null;
	
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
	
	public void setPlotInfos(PlotInfo[] plotInfos) {
		changeSupport.firePropertyChange("plotInfos", this.plotInfos, this.plotInfos=plotInfos);
	}
	
	public void setPlotInfo(PlotInfo plotInfo) {
		changeSupport.firePropertyChange("plotInfo", this.plotInfo, this.plotInfo=plotInfo);
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
	
	public PlotInfo[] getPlotInfos() {
		return plotInfos;
	}
	
	public PlotInfo getPlotInfo() {
		return plotInfo;
	}
	
	public String[] getSensorNames() {
		return sensorNames;
	}
	
	public String getSensorName() {
		return sensorName;
	}
}
