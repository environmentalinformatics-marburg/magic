package timeseriesdatabase.loader;

import timeseriesdatabase.StationProperties;
import timeseriesdatabase.raw.ASCTimeSeries;

public class LoaderFactory {
	
	private LoaderFactory(){}
	
	public static AbstractLoader createLoader(String loggerTypeName, String[] input_schema, StationProperties properties, ASCTimeSeries csvtimeSeries) {
		switch(loggerTypeName) {
		case "wxt":
			return new Loader_wxt(input_schema, properties, csvtimeSeries);
		case "pu1":
			return new Loader_pu1(input_schema, properties, csvtimeSeries);
		case "pu2":
			return new Loader_pu2(input_schema, properties, csvtimeSeries);
		case "rad":
			return new Loader_rad(input_schema, properties, csvtimeSeries);
		case "tfi":
			return new Loader_tfi(input_schema, properties, csvtimeSeries);
		case "gp1":
			return new Loader_gp1(input_schema, properties, csvtimeSeries);
		case "rug":
			return new Loader_rug(input_schema, properties, csvtimeSeries);					
		default:
			return null;
		}
	}

}
