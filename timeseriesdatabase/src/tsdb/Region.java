package tsdb;

import java.io.Serializable;

import tsdb.util.Util;

public class Region implements Serializable {
	private static final long serialVersionUID = -8897183157291637247L;
	
	public final String name;
	public final String longName;
	
	public Region(String name, String longName) {
		Util.throwNull(name,longName);
		this.name = name;
		this.longName = longName;
	}

}
