package tsdb.util;

import static tsdb.util.Util.log;

import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.io.PrintStream;
import java.rmi.RemoteException;
import java.util.Formatter;
import java.util.Locale;
import java.util.function.Consumer;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import tsdb.DataQuality;
import tsdb.Sensor;
import tsdb.TimeConverter;
import tsdb.aggregated.AggregationInterval;
import tsdb.raw.TimeSeriesEntry;
import tsdb.raw.TimestampSeries;
import tsdb.remote.RemoteTsDB;

public class ZipExport {
	
	private final RemoteTsDB tsdb;

	private Consumer<String> cbPrintLine = null;
	
	private String[] sensorNames;
	private String[] plotIDs;
	private AggregationInterval aggregationInterval;
	private DataQuality dataQuality;
	private boolean interpolated;
	
	public ZipExport(RemoteTsDB tsdb, String[] sensorNames, String[] plotIDs,AggregationInterval aggregationInterval,DataQuality dataQuality,boolean interpolated) {
		this.tsdb = tsdb;
		
		this.sensorNames = sensorNames;
		this.plotIDs = plotIDs;
		this.aggregationInterval = aggregationInterval;
		this.dataQuality = dataQuality;
		this.interpolated = interpolated;
	}
	
	public void createZipFile(String filename) {
		FileOutputStream fileOutputStream;
		try {
			printLine("create file: "+filename);
			fileOutputStream = new FileOutputStream(filename);
			writeToStream(fileOutputStream);
			fileOutputStream.close();
		} catch (IOException e1) {
		}
		printLine("...finished");			
	}
	
	
	public void writeToStream(OutputStream outputstream) {	
		printLine("start export...");
		printLine("sensorNames: "+Util.arrayToString(sensorNames));
		if(Util.empty(sensorNames)) {
			return;
		}
		if(Util.empty(plotIDs)) {
			return;
		}
		System.out.println("plots: "+plotIDs.length);

		try {
			ZipOutputStream zipOutputStream = new ZipOutputStream(outputstream);
			zipOutputStream.setComment("new comment");
			zipOutputStream.setLevel(9);
			
			zipOutputStream.putNextEntry(new ZipEntry("sensor_description.txt"));
			PrintStream printStream = new PrintStream(zipOutputStream, true);
			printStream.println("sensors:\t"+sensorNames.length);
			printStream.println();
			for(int i=0;i<sensorNames.length;i++) {
				printStream.println((i+1)+". sensor:\t"+sensorNames[i]);
				try {
					Sensor sensor = tsdb.getSensor(sensorNames[i]);
					printStream.println("description:\t"+sensor.description);
					printStream.println("unit:\t\t"+sensor.unitDescription);
				} catch (RemoteException e) {
					log.error(e);
				}
				printStream.println();
			}



			for(String plotID:plotIDs) {
				printLine("process plotID: "+plotID);
				try {
					System.out.println(Util.arrayToString(sensorNames));
					String[] schema = tsdb.getValidSchema(plotID, sensorNames);
					System.out.println(Util.arrayToString(schema));
					if(!Util.empty(schema)) {
						TimestampSeries timeseries = tsdb.plot(null,plotID, schema, aggregationInterval, dataQuality, interpolated);
						if(timeseries!=null) {
							ZipEntry zipEntry = new ZipEntry(plotID+".csv");
							zipOutputStream.putNextEntry(zipEntry);
							System.out.println(timeseries);
							
							PrintStream csvOut = new PrintStream(zipOutputStream);
							StringBuilder stringbuilder = new StringBuilder();
							stringbuilder.append("plotID");
							stringbuilder.append(',');
							stringbuilder.append("timestamp");
							stringbuilder.append(',');
							stringbuilder.append("datetime");
							for(String name:timeseries.parameterNames) {
								stringbuilder.append(',');
								stringbuilder.append(name);
							}
							csvOut.println(stringbuilder);
							
							for(TimeSeriesEntry entry:timeseries.entryList) {
								StringBuilder s = new StringBuilder();
								s.append(plotID);
								s.append(',');
								s.append(entry.timestamp);								
								s.append(',');
								s.append(TimeConverter.oleMinutesToText(entry.timestamp));
								
								Formatter formater = new Formatter(s,Locale.ENGLISH);								
								for(float v:entry.data) {									
									formater.format(",%3.3f", v);

								}
								csvOut.println(s);
								formater.close();															
							}
							csvOut.flush();
							
							//CSV.write(timeseries.tsIterator(), true, zipOutputStream, ",", "Na", CSVTimeType.TIMESTAMP_AND_DATETIME, false, false);
						} else {
							printLine("not processed: "+plotID);
						}
					}
				} catch (RemoteException e) {
					log.error(e);
				}
			}

			zipOutputStream.finish();

		} catch (IOException e1) {
		}
		printLine("...finished");
	}
	
	public void setPrintCallback(Consumer<String> callback) {
		this.cbPrintLine = callback;
	}

	private void printLine(String s) {
		if(cbPrintLine!=null) {
			cbPrintLine.accept(s);
		}
	}	

}
