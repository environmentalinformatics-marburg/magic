package tsdb.gui.export;

import tsdb.DataQuality;
import tsdb.aggregated.AggregationInterval;
import tsdb.gui.util.AbstractModel;
import tsdb.remote.PlotInfo;

public class CollectorModel extends AbstractModel {
	
	private String[] allRegionLongNames = null;
	private String regionLongName = null;
	
	private String[] allSensorNames = null;
	private String[] querySensorNames = null;
	
	private PlotInfo[] allPlotInfos = null;
	private PlotInfo[] queryPlotInfos = null;
	
	private boolean useInterpolation = false;	
	private DataQuality dataQuality = DataQuality.NO;
	private AggregationInterval aggregationInterval = AggregationInterval.HOUR;
	private boolean writeDescription;
	private boolean writeAllInOne;
	
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
	
	public void setUseInterpolation(boolean useInterpolation) {
		changeSupport.firePropertyChange("useInterpolation", this.useInterpolation, this.useInterpolation=useInterpolation);
	}
	
	public boolean getUseInterpolation() {
		return useInterpolation;
	}
	
	public void setDataQuality(DataQuality dataQuality) {
		changeSupport.firePropertyChange("dataQuality", this.dataQuality, this.dataQuality=dataQuality);
	}
	
	public DataQuality getDataQuality() {
		return dataQuality;
	}
	
	public void setAggregationInterval(AggregationInterval aggregationInterval) {
		changeSupport.firePropertyChange("aggregationInterval", this.aggregationInterval, this.aggregationInterval=aggregationInterval);
	}
	
	public AggregationInterval getAggregationInterval() {
		return aggregationInterval;
	}
	
	public void setWriteDescription(boolean writeDescription) {
		changeSupport.firePropertyChange("writeDescription", this.writeDescription, this.writeDescription=writeDescription);
	}
	
	public boolean getWriteDescription() {
		return writeDescription;
	}
	
	public void setWriteAllInOne(boolean writeAllInOne) {
		changeSupport.firePropertyChange("writeAllInOne", this.writeAllInOne, this.writeAllInOne=writeAllInOne);
	}
	
	public boolean getWriteAllInOne() {
		return writeAllInOne;
	}	

}
