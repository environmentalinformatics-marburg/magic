package tsdb.util;

import static tsdb.util.Util.log;

import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.io.PrintStream;
import java.rmi.RemoteException;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.Formatter;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.function.Consumer;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import tsdb.DataQuality;
import tsdb.Region;
import tsdb.Sensor;
import tsdb.TimeConverter;
import tsdb.aggregated.AggregationInterval;
import tsdb.raw.TsEntry;
import tsdb.raw.TimestampSeries;
import tsdb.remote.PlotInfo;
import tsdb.remote.RemoteTsDB;
import static tsdb.util.AssumptionCheck.throwNull;;

public class ZipExport {

	private final RemoteTsDB tsdb;

	private Consumer<String> cbPrintLine = null;

	private final Region region;
	private final String[] sensorNames;
	private final String[] plotIDs;
	private final AggregationInterval aggregationInterval;
	private final DataQuality dataQuality;
	private final boolean interpolated;
	private final boolean allInOne;
	private final boolean desc_sensor;
	private final boolean desc_plot;
	private final boolean desc_settings;
	private final boolean col_plotid;
	private final boolean col_timestamp;
	private final boolean col_datetime;
	private final boolean write_header;

	public ZipExport(RemoteTsDB tsdb, Region region, String[] sensorNames, String[] plotIDs,AggregationInterval aggregationInterval,DataQuality dataQuality,boolean interpolated, boolean allinone, boolean desc_sensor, boolean desc_plot, boolean desc_settings, boolean col_plotid, boolean col_timestamp, boolean col_datetime, boolean write_header) {
		throwNull(tsdb);
		this.tsdb = tsdb;

		this.region = region;
		this.sensorNames = sensorNames;
		this.plotIDs = plotIDs;
		this.aggregationInterval = aggregationInterval;
		this.dataQuality = dataQuality;
		this.interpolated = interpolated;
		this.allInOne = allinone;
		this.desc_sensor = desc_sensor;
		this.desc_plot = desc_plot;
		this.desc_settings = desc_settings;
		this.col_plotid = col_plotid;
		this.col_timestamp = col_timestamp;
		this.col_datetime = col_datetime;
		this.write_header = write_header;
	}

	public boolean createZipFile(String filename) {
		FileOutputStream fileOutputStream;
		try {
			printLine("create file: "+filename);
			fileOutputStream = new FileOutputStream(filename);
			boolean ret = writeToStream(fileOutputStream);
			fileOutputStream.close();
			printLine("...finished");
			return ret;
		} catch (IOException e) {
			log.error(e);
			return false;
		}

	}


	public boolean writeToStream(OutputStream outputstream) {
		printLine("start export...");
		printLine("sensorNames: "+Util.arrayToString(sensorNames));
		if(Util.empty(sensorNames)) {
			return false;
		}
		if(Util.empty(plotIDs)) {
			return false;
		}
		System.out.println("plots: "+plotIDs.length);

		try {
			ZipOutputStream zipOutputStream = new ZipOutputStream(outputstream);
			zipOutputStream.setComment("time series archive file");
			zipOutputStream.setLevel(9);

			if(desc_settings) {
				zipOutputStream.putNextEntry(new ZipEntry("settings.txt"));
				PrintStream printStream = new PrintStream(zipOutputStream, false);
				write_settings(printStream);
				printStream.flush();
			}

			if(desc_sensor) {
				zipOutputStream.putNextEntry(new ZipEntry("sensor_description.txt"));
				PrintStream printStream = new PrintStream(zipOutputStream, false);
				write_sensor_description(printStream);
				printStream.flush();
			}

			if(desc_plot) {
				zipOutputStream.putNextEntry(new ZipEntry("plot_description.txt"));
				PrintStream printStream = new PrintStream(zipOutputStream, false);
				write_plot_description(printStream);
				printStream.flush();
			}

			if(allInOne) {				
				zipOutputStream.putNextEntry(new ZipEntry("plots.csv"));
				PrintStream csvOut = new PrintStream(zipOutputStream,false);
				if(write_header) {
					writeCSVHeader(csvOut);
				}
				for(String plotID:plotIDs) {
					printLine("process plotID: "+plotID);
					try {
						String[] schema = tsdb.getValidSchema(plotID, sensorNames);
						if(!Util.empty(schema)) {
							TimestampSeries timeseries = tsdb.plot(null,plotID, schema, aggregationInterval, dataQuality, interpolated);
							if(timeseries!=null) {								
								writeTimeseries(timeseries,plotID,csvOut);								
							} else {
								printLine("not processed: "+plotID);
							}
						}
					} catch (Exception e) {
						log.error(e);
					}
				}
				csvOut.flush();				
			} else {				
				for(String plotID:plotIDs) {
					printLine("process plotID: "+plotID);
					try {
						String[] schema = tsdb.getValidSchema(plotID, sensorNames);
						if(!Util.empty(schema)) {
							TimestampSeries timeseries = tsdb.plot(null,plotID, schema, aggregationInterval, dataQuality, interpolated);
							if(timeseries!=null) {
								zipOutputStream.putNextEntry(new ZipEntry(plotID+".csv"));
								PrintStream csvOut = new PrintStream(zipOutputStream,false);
								if(write_header) {
									writeCSVHeader(csvOut);
								}
								writeTimeseries(timeseries,plotID,csvOut);
								csvOut.flush();
							} else {
								printLine("not processed: "+plotID);
							}
						}
					} catch (Exception e) {
						e.printStackTrace();
						log.error(e);
					}
				}				
			}
			zipOutputStream.finish();
			printLine("...finished");
			return true;
		} catch (IOException e) {
			log.warn(e);
			return false;
		}		
	}	

	private void write_settings(PrintStream printStream) {
		printStream.println("Settings that were used to create this time series archive file:");
		printStream.println();
		printStream.println("creation date: "+LocalDateTime.now());
		printStream.println();
		printStream.println("sensor names ("+sensorNames.length+") : "+Util.arrayToString(sensorNames));
		printStream.println();
		printStream.println("plot names ("+plotIDs.length+") : "+Util.arrayToString(plotIDs));
		printStream.println();
		printStream.println("time steps : "+aggregationInterval.getText());
		printStream.println();
		printStream.println("quality checks : "+dataQuality.getText());
		printStream.println();
		if(interpolated) {
			printStream.println("interpolate missing data");
			printStream.println();
		} else {
			printStream.println("no interpolation used");
			printStream.println();
		}
		if(allInOne) {
			printStream.println("write all plots into one CSV-File");
			printStream.println();
		} else {
			printStream.println("for each plot write into separate CSV-File");
			printStream.println();			
		}

	}

	public void setPrintCallback(Consumer<String> callback) {
		this.cbPrintLine = callback;
	}

	private void printLine(String s) {
		if(cbPrintLine!=null) {
			cbPrintLine.accept(s);
		}
	}

	private void writeCSVHeader(PrintStream csvOut) {
		StringBuilder stringbuilder = new StringBuilder();
		boolean isFirst = true;
		if(col_plotid) {
			stringbuilder.append("plotID");
			isFirst = false;
		}

		if(col_timestamp) {
			if(!isFirst) {
				stringbuilder.append(',');				
			}
			stringbuilder.append("timestamp");
			isFirst = false;
		}

		if(col_datetime) {
			if(!isFirst) {
				stringbuilder.append(',');				
			}
			stringbuilder.append("datetime");
			isFirst = false;
		}
		for(String name:sensorNames) {
			if(!isFirst) {
				stringbuilder.append(',');
			}
			stringbuilder.append(name);
			isFirst = false;
		}
		csvOut.println(stringbuilder);
	}

	private void write_sensor_description(PrintStream printStream) {
		printStream.println("sensors:\t"+sensorNames.length);
		printStream.println();
		for(int i=0;i<sensorNames.length;i++) {
			printStream.println((i+1)+". sensor:\t"+sensorNames[i]);
			try {
				Sensor sensor = tsdb.getSensor(sensorNames[i]);
				if(sensor!=null) {
					printStream.println("description:\t"+sensor.description);
					printStream.println("unit:\t\t"+sensor.unitDescription);
				}
			} catch (RemoteException e) {
				log.error(e);
			}
			printStream.println();
		}		
	}

	private void write_plot_description(PrintStream printStream) {
		printStream.println("plots:\t"+plotIDs.length);
		printStream.println("in region:\t"+region.longName);
		printStream.println();

		try {
			PlotInfo[] plotInfos = tsdb.getPlotInfos();
			Map<String,PlotInfo> map = new HashMap<String,PlotInfo>();
			for(PlotInfo plotInfo:plotInfos) {
				map.put(plotInfo.name, plotInfo);
			}

			for(int i=0;i<plotIDs.length;i++) {
				printStream.println((i+1)+". plot:\t"+plotIDs[i]);

				PlotInfo plotInfo = map.get(plotIDs[i]);
				if(plotInfo!=null) {
					printStream.println("category:\t"+plotInfo.generalStationInfo.longName);
					printStream.println("position:\t"+Util.arrayToString(plotInfo.geoPos));
				}

				printStream.println();
			}
		} catch (RemoteException e) {
			log.error(e);
		}
	}

	private void writeTimeseries(TimestampSeries timeseries, String plotID, PrintStream csvOut) {		
		System.out.println(timeseries);

		int[] pos = Util.stringArrayToPositionIndexArray(sensorNames, timeseries.parameterNames, false, false);
		System.out.println("sensorNames "+Arrays.asList(sensorNames));
		System.out.println("schema "+Arrays.asList(timeseries.parameterNames));							
		System.out.println(Util.arrayToString(pos));		



		for(TsEntry entry:timeseries.entryList) {
			boolean isFirst = true;
			StringBuilder s = new StringBuilder();
			if(col_plotid) {
				s.append(plotID);
				isFirst = false;
			}
			if(col_timestamp) {
				if(!isFirst) {
					s.append(',');
				}
				s.append(entry.timestamp);
				isFirst = false;
			}
			if(col_datetime) {
				if(!isFirst) {
					s.append(',');
				}
				s.append(TimeConverter.oleMinutesToText(entry.timestamp));
				isFirst = false;
			}

			Formatter formater = new Formatter(s,Locale.ENGLISH);

			float[] data = entry.data;
			for(int targetIndex=0;targetIndex<sensorNames.length;targetIndex++) {
				int sourceIndex = pos[targetIndex];
				if(sourceIndex<0) {
					if(isFirst) {
						formater.format("NA");
						isFirst = false;
					} else {
						formater.format(",NA");
					}
				} else {
					float v = data[sourceIndex];
					if(Float.isNaN(v)) {
						if(isFirst) {
							formater.format("NA");
							isFirst = false;
						} else {
							formater.format(",NA");
						}	
					} else {
						if(isFirst) {
							//formater.format("%3.3f", v);
							formater.format("%.2f", v);
							isFirst = false;
						} else {
							//formater.format(",%3.3f", v);
							formater.format(",%.2f", v);
						}
					}
				}
			}

			csvOut.println(s);
			formater.close();															
		}		
	}

}
