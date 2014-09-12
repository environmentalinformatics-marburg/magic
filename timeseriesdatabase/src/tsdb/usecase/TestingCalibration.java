package tsdb.usecase;

import java.util.ArrayList;
import java.util.List;

import org.apache.logging.log4j.Logger;

import tsdb.TsDBFactory;
import tsdb.QueryProcessor;
import tsdb.StationProperties;
import tsdb.TsDB;
import tsdb.VirtualPlot;
import tsdb.raw.TimeSeriesEntry;
import tsdb.util.TimeSeriesSchema;
import tsdb.util.TimestampInterval;
import tsdb.util.TsSchema;
import tsdb.util.Util;
import tsdb.util.iterator.InputProcessingIterator;
import tsdb.util.iterator.TsIterator;

public class TestingCalibration {

	private static final String CSV_OUTPUT_PATH = "C:/timeseriesdatabase_output/";

	private static final Logger log = Util.log;

	public static void main(String[] args) {
		System.out.println("start...");
		TsDB timeSeriesDatabase = TsDBFactory.createDefault();
		QueryProcessor qp = new QueryProcessor(timeSeriesDatabase);

		/*String plotID = "gra1";
		String[] querySchema = new String[]{"P_container_RT"};
		Long queryStart = null;
		Long queryEnd = null;
		DataQuality dataQuality = DataQuality.NO;
		AggregationInterval aggregationInterval = AggregationInterval.HOUR;
		boolean interpolated = false;
		TimeSeriesIterator it = qp.virtualquery_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality, aggregationInterval, interpolated);
		TestingRainIterator it2 = new TestingRainIterator(it);
		it2.writeCSV(CSV_OUTPUT_PATH+"TestingCalibration.csv");*/



		String plotID = "gra1";
		String[] querySchema = null;

		VirtualPlot virtualPlot = timeSeriesDatabase.getVirtualPlot(plotID);
		for(TimestampInterval<StationProperties> interval:virtualPlot.intervalList) {			
			String stationName = interval.value.get_serial();
			TsIterator temp_raw_iterator = qp.query_raw(stationName, querySchema, interval.start, interval.end);
			if(temp_raw_iterator!=null&&temp_raw_iterator.hasNext()) {
				System.out.println("get: "+stationName);
				String loggerTypeName = interval.value.get_logger_type_name();
				switch(loggerTypeName) {
				case "wxt":
					TestingCalibration_wxt_Iterator temp_iterator = new TestingCalibration_wxt_Iterator(temp_raw_iterator, interval.value);
					break;
				default:
					log.warn("logger not found");
				}				
			}			
		}

		System.out.println("...end");
	}

	static class TestingRainIterator extends InputProcessingIterator {

		private static TsSchema createSchema() {
			String[] names = new String[]{"P_container_RT","P_RT_NRT"};
			return new TsSchema(names);
		}

		private float prev = Float.NaN;

		public TestingRainIterator(TsIterator input_iterator) {
			super(input_iterator, createSchema());
		}

		@Override
		protected TimeSeriesEntry getNext() {
			if(input_iterator.hasNext()) {
				TimeSeriesEntry curr = input_iterator.next();
				float value = curr.data[0];
				float result;
				if((!Float.isNaN(prev))&&(!Float.isNaN(value))&&(value<200)&&(value-prev)>=0) {
					result = value-prev;
				} else {
					result = Float.NaN;
				}
				prev = value;
				return new TimeSeriesEntry(curr.timestamp, new float[]{curr.data[0],result});
			} else
				return null;
		}
	}

	static class TestingCalibration_wxt_Iterator extends InputProcessingIterator{

		public static final String LOGGER_TYPE_NAME = "wxt";

		int pos_SWDR_300_U = -1;
		int pos_SWUR_300_U = -1;
		int pos_LWDR_300_U = -1;
		int pos_LWUR_300_U = -1;
		int pos_P_container_RT = -1;
		int pos_T_CNR = -1;

		float calib_coefficient_SWDR_300_U = Float.NaN;
		float calib_coefficient_SWUR_300_U = Float.NaN;
		float calib_coefficient_LWDR_300_U = Float.NaN;
		float calib_coefficient_LWUR_300_U = Float.NaN;

		private static TsSchema createSchema(TsIterator input_iterator, StationProperties properties) {

			if(!properties.get_logger_type_name().equals(LOGGER_TYPE_NAME)) {
				throw new RuntimeException("wrong logger type: "+properties.get_logger_type_name());
			}

			String[] input_sensorNames = input_iterator.getNames();

			//SWDR_300_U, SWUR_300_U, LWDR_300_U, LWUR_300_U			

			System.out.println("input schema: "+Util.arrayToString(input_sensorNames));

			List<String> outputSensorNameList = new ArrayList<String>();

			for(int i=0;i<input_sensorNames.length;i++) {
				String sensorName = input_sensorNames[i];
				//System.out.println("sensor name i: "+sensorName);
				switch(sensorName) {
				case "SWDR_300_U":
					outputSensorNameList.add("SWDR_300");
					break;
				case "SWUR_300_U":
					outputSensorNameList.add("SWUR_300");
					break;
				case "LWDR_300_U":
					outputSensorNameList.add("LWDR_300");
					break;
				case "LWUR_300_U":
					outputSensorNameList.add("LWUR_300");
					break;
				case "P_container_RT":
					outputSensorNameList.add("LWUR_300");
					break;
				case "T_CNR":
					break;
				default:
					outputSensorNameList.add(sensorName);
				}
			}

			System.out.println("output schema: "+outputSensorNameList);
			return null;
			/*String[] schema = new String[]{"P_container_RT","P_RT_NRT"};
			return TimeSeriesSchema.createJustSchema(schema );*/
		}

		private final StationProperties properties;

		public TestingCalibration_wxt_Iterator(TsIterator input_iterator, StationProperties properties) {
			super(input_iterator, createSchema(input_iterator, properties));
			this.properties = properties;
		}

		private void init(StationProperties properties) {


			if(!properties.get_logger_type_name().equals(LOGGER_TYPE_NAME)) {
				throw new RuntimeException("wrong logger type: "+properties.get_logger_type_name());
			}

			String[] input_sensorNames = input_iterator.getNames();

			//SWDR_300_U, SWUR_300_U, LWDR_300_U, LWUR_300_U			

			System.out.println("input schema: "+Util.arrayToString(input_sensorNames));

			List<String> outputSensorNameList = new ArrayList<String>();

			for(int i=0;i<input_sensorNames.length;i++) {
				String sensorName = input_sensorNames[i];
				//System.out.println("sensor name i: "+sensorName);
				switch(sensorName) {
				case "SWDR_300_U":
					pos_SWDR_300_U = i;
					outputSensorNameList.add("SWDR_300");
					calib_coefficient_SWDR_300_U = properties.getFloatProperty("wxt_SWDR_300");
					break;
				case "SWUR_300_U":
					pos_SWUR_300_U = i;
					outputSensorNameList.add("SWUR_300");
					calib_coefficient_SWUR_300_U = properties.getFloatProperty("wxt_SWUR_300");
					break;
				case "LWDR_300_U":
					pos_LWDR_300_U = i;
					outputSensorNameList.add("LWDR_300");
					calib_coefficient_LWDR_300_U = properties.getFloatProperty("wxt_LWDR_300");
					break;
				case "LWUR_300_U":
					pos_LWUR_300_U = i;
					outputSensorNameList.add("LWUR_300");
					calib_coefficient_LWUR_300_U = properties.getFloatProperty("wxt_LWUR_300");
					break;
				case "P_container_RT":
					pos_P_container_RT = i;
					break;
				case "T_CNR":
					pos_T_CNR = i;
					break;
				default:
					outputSensorNameList.add(sensorName);
				}
			}
		}

		@Override
		protected TimeSeriesEntry getNext() {
			return null;
		}

	}



}


