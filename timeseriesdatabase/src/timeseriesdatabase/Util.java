package timeseriesdatabase;

import java.util.HashMap;
import java.util.Map;

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
	
	public static Map<String,Integer> StringArrayToMap(String[] entries) {
		Map<String,Integer> map = new HashMap<String,Integer>();
		if(entries==null) {
			throw new RuntimeException("StringArrayToMap: entries==null");
		}
		for(int i=0;i<entries.length;i++) {
			if(entries[i]==null) {
				log.warn("StringArrayToMap: entries["+i+"]==null ==> will not be included in map");
			} else {
				map.put(entries[i], i);
			}
		}
		return map;
	}
	
	public static int[] stringArrayToPositionIndexArray(String resultNames[], String[] sourcePosStringArray, boolean warn) {
		return stringArrayToPositionIndexArray(resultNames,StringArrayToMap(sourcePosStringArray),warn);
	}
	
	public static int[] stringArrayToPositionIndexArray(String resultNames[], Map<String,Integer> sourcePosStringMap, boolean warn) {
		int[] sourcePos = new int[resultNames.length];
		for(int i=0;i<resultNames.length;i++) {
			Integer pos = sourcePosStringMap.get(resultNames[i]);
			if(pos==null) {
				if(warn) {
					log.warn("stringArrayToPositionIndexArray: "+resultNames[i]+" not in "+sourcePosStringMap);
				}
				sourcePos[i] = -1;
			} else {
				sourcePos[i] = pos;
			}		
		}
		return sourcePos;
	}

}
