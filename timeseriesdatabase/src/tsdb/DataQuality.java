package tsdb;

import static tsdb.util.Util.log;

/**
 * for data values: highest passed quality check
 * for queries: lowest quality of data values
 * @author woellauer
 *
 */
public enum DataQuality { 
	Na,			//quality unknown    for query: no check, no flag creation
	NO,			//no quality check passed    for query: no check, but flag creation
	PHYSICAL,	//physical range check passed and step and empirical not passed
	STEP,       //physical range check and step passed and empirical not passed
	EMPIRICAL;   //physical range check and step and empirical passed
	
	public String getText() {
		switch(this) {
		case NO:
			return "no";
		case PHYSICAL:
			return "physical";
		case STEP:
			return "step";
		case EMPIRICAL:
			return "empirical";
		case Na:
			return "na";
		default:
			log.warn("data quality unknown");
			return "unknown";
		}		
	}
	
	public String getTextGUI() {
		switch(this) {
		case NO:
			return "0: no";
		case PHYSICAL:
			return "1: physical";
		case STEP:
			return "2: physical + step";
		case EMPIRICAL:
			return "3: physical + step + empirical";
		case Na:
			return "na";
		default:
			return "unknown";
		}		
	}
}