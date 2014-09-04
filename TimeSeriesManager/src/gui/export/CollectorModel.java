package gui.export;

import gui.util.AbstractModel;

public class CollectorModel extends AbstractModel {
	
	private String regionLongName = null;
	
	public void setRegionLongName(String regionLongName) {
		changeSupport.firePropertyChange("regionLongName", this.regionLongName, this.regionLongName=regionLongName);
	}
	
	public String getRegionLongName() {
		return regionLongName;
	}

}
