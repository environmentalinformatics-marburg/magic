package util;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.ini4j.Wini;
import org.ini4j.Profile.Section;

import timeseriesdatabase.Sensor;

/**
 * Some utilities
 * @author woellauer
 *
 */
public class Util {

	/**
	 * Default logger
	 */
	public static final Logger log = LogManager.getLogger("general");

	/**
	 * convert float to String with two fractional digits
	 * @param value
	 * @return
	 */
	public static String floatToString(float value) {
		if(Float.isNaN(value)) {
			return " --- ";
		}
		return String.format("%.2f", value);
	}

	public static String doubleToString(double value) {
		if(Double.isNaN(value)) {
			return " --- ";
		}
		return String.format("%.2f", value);
	}

	/**
	 * create position map of array of Strings:
	 * name -> array position
	 * @param entries
	 * @return
	 */
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

	/**
	 * create an array of positions of entries in resultNames with positions of sourcePosStringArray
	 * @param resultNames
	 * @param sourcePosStringArray
	 * @param warn warn if entry was not found in sourcePosStringArray
	 * @return
	 */
	public static int[] stringArrayToPositionIndexArray(String resultNames[], String[] sourcePosStringArray, boolean warn) {
		return stringArrayToPositionIndexArray(resultNames,StringArrayToMap(sourcePosStringArray),warn);
	}

	/**
	 * create an array of positions of entries in resultNames with positions of sourcePosStringMap
	 * @param resultNames
	 * @param sourcePosStringMap
	 * @param warn warn if entry was not found in sourcePosStringMap
	 * @return
	 */
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

	/**
	 * print array of values in one line
	 * @param a
	 */
	public static void printArray(double[] a) {
		for(int i=0;i<a.length;i++) {
			System.out.format("%.2f  ",a[i]);
		}
		System.out.println();
	}

	public static void printArray(float[] a) {
		for(int i=0;i<a.length;i++) {
			System.out.format("%.2f  ",a[i]);
		}
		System.out.println();
	}

	public static String arrayToString(float[] a) {
		String result="";
		for(int i=0;i<a.length;i++) {
			result+=floatToString(a[i])+" ";
		}
		return result;
	}

	/**
	 * print array of values in one line
	 * @param a
	 */
	public static void printArray(String[] a) {
		for(int i=0;i<a.length;i++) {
			System.out.print(a[i]+" ");
		}
		System.out.println();
	}

	/**
	 * named range of float values
	 * @author woellauer
	 *
	 */
	public static class FloatRange {
		public final String name;
		public final float min;
		public final float max;
		public FloatRange(String name, float min, float max) {
			this.name = name;
			this.min = min;
			this.max = max;
		}
	}

	/**
	 * Reads a list of range float values from ini-file section
	 * @param fileName
	 * @param sectionName
	 * @return
	 */
	public static List<FloatRange> readIniSectionFloatRange(String fileName, String sectionName) {
		try {
			Wini ini = new Wini(new File(fileName));
			Section section = ini.get(sectionName);
			if(section!=null) {
				ArrayList<FloatRange> resultList = new ArrayList<FloatRange>();
				for(Entry<String, String> entry:section.entrySet()) {
					String name = entry.getKey();
					String range = entry.getValue();
					try {
						String minString = range.substring(range.indexOf('[')+1, range.indexOf(','));
						String maxString = range.substring(range.indexOf(',')+2, range.indexOf(']'));
						float min=Float.parseFloat(minString);
						float max=Float.parseFloat(maxString);
						resultList.add(new FloatRange(name, min, max));
					} catch (Exception e) {
						log.warn("error in read: "+name+"\t"+range+"\t"+e);
					}
				}
				return resultList;
			} else {
				log.error("ini section not found: "+sectionName);
				return null;
			}
		} catch (Exception e) {
			log.error("ini file not read "+fileName+"\t"+sectionName+"\t"+e);
			return null;
		}
	}

	public static <T> ArrayList<T> iteratorToList(Iterator<T> it) {
		ArrayList<T> resultList = new ArrayList<T>();
		while(it.hasNext()) {
			resultList.add(it.next());
		}
		return resultList;
	}

	public static <T> List<T> createList(List<T> list, T e) {
		ArrayList<T> result = new ArrayList<T>(list.size()+1);
		result.addAll(list);
		result.add(e);
		return result;
	}

}
