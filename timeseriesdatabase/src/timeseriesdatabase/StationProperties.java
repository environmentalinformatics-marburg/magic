package timeseriesdatabase;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import util.TimestampInterval;
import util.Util;

public class StationProperties {
	
	private final static String PROPERTY_START = "DATE_START";
	private final static String PROPERTY_END = "DATE_END";
	private final static String PROPERTY_LOGGER = "LOGGER";
	private final static String PROPERTY_PLOTID = "PLOTID";
	
	private Map<String,String> propertyMap;
	
	public StationProperties(Map<String,String> propertyMap) {
		this.propertyMap = propertyMap;		
	}
	
	public String getProperty(String key) {
		return propertyMap.get(key);
	}
	
	private static Long parseConfigDateStart(String startText) {
		Long timestampStart = null;					
		if(!startText.equals("1999-01-01")) {
			LocalDate startDate = LocalDate.parse(startText,DateTimeFormatter.ISO_DATE);
			LocalDateTime startDateTime = LocalDateTime.of(startDate, LocalTime.of(00, 00));
			timestampStart = TimeConverter.DateTimeToOleMinutes(startDateTime);
		}
		return timestampStart;
	}
		
	private static Long parseConfigDateEnd(String endText) {
		Long timestampEnd = null;
		if(!endText.equals("2099-12-31")) {
			LocalDate endDate = LocalDate.parse(endText,DateTimeFormatter.ISO_DATE);
			LocalDateTime endDateTime = LocalDateTime.of(endDate, LocalTime.of(23, 59));
			timestampEnd = TimeConverter.DateTimeToOleMinutes(endDateTime);
		}	
		return timestampEnd;
	}
	
	public Long get_date_start() {
		return parseConfigDateStart(propertyMap.get(PROPERTY_START));
	}
	
	public Long get_date_end() {
		return parseConfigDateEnd(propertyMap.get(PROPERTY_END));
	}
	
	public String get_logger_type_name() {
		return propertyMap.get(PROPERTY_LOGGER);
	}
	
	public TimestampInterval<StationProperties> createTimestampInterval() {
		return new TimestampInterval<StationProperties>(this,get_date_start(),get_date_end());
	}
	
	public static List<TimestampInterval<StationProperties>> createIntervalList(List<StationProperties> list) {
		ArrayList<TimestampInterval<StationProperties>> resultList = new ArrayList<TimestampInterval<StationProperties>>(list.size());		
		for(StationProperties properties:list) {
			resultList.add(properties.createTimestampInterval());
		}		
		return resultList;
	}
	
	public String get_plotid() {
		return propertyMap.get(PROPERTY_PLOTID);
	}

}
