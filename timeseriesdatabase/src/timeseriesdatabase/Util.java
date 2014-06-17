package timeseriesdatabase;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * Some utilities
 * @author Stephan Wöllauer
 *
 */
public class Util {
	
	/**
	 * Default logger
	 */
	public static final Logger log = LogManager.getLogger("general");
	
	public static String floatToString(float value) {
		if(Float.isNaN(value)) {
			return " --- ";
		}
		return String.format("%.2f", value);
	}

}
