package tsdb;

import java.io.Serializable;

public class Region implements Serializable {
	private static final long serialVersionUID = -8897183157291637247L;
	
	public final String name;
	public final String longName;
	
	public Region(String name, String longName) {
		this.name = name;
		this.longName = longName;
	}

}
