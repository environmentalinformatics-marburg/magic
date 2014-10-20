package gui.export;

import java.io.FileOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.rmi.RemoteException;
import java.util.Arrays;
import java.util.Formatter;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.function.Consumer;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import tsdb.DataQuality;
import tsdb.Sensor;
import tsdb.TimeConverter;
import tsdb.aggregated.AggregationInterval;
import tsdb.raw.TsEntry;
import tsdb.raw.TimestampSeries;
import tsdb.remote.GeneralStationInfo;
import tsdb.remote.PlotInfo;
import tsdb.remote.RemoteTsDB;
import tsdb.util.TsDBLogger;
import tsdb.util.Util;

public class CollectorController implements TsDBLogger {

	private CollectorModel model;

	private RemoteTsDB tsdb;

	private Consumer<String> cbPrintLine = null;


	public CollectorController(RemoteTsDB tsdb) {
		this.tsdb = tsdb;
		this.model = new CollectorModel();
		bindModel();
	}

	public void initModel() {
		String[] regionLongNames = null;
		String regionLongName = null;
		try {
			regionLongNames = tsdb.getRegionLongNames();
		} catch (RemoteException e) {
			log.error(e);
		}
		if(regionLongNames!=null&&regionLongNames.length>0) {
			regionLongName = regionLongNames[0];
		}
		model.setAllRegionLongNames(regionLongNames);
		model.setRegionLongName(regionLongName);
	}

	public CollectorModel getModel() {
		return model;
	}

	private void bindModel() {
		model.addPropertyChangeCallback("regionLongName", this::onChangeRegionLongName);
	}

	private void onChangeRegionLongName(String regionLongName) {
		String[] sensorNames = null;
		try {
			Set<String> sensorNameSet = new TreeSet<String>();
			for(GeneralStationInfo generalStationInfo:tsdb.getGeneralStations()) {
				System.out.println(generalStationInfo.name);
				if(generalStationInfo.region.longName.equals(regionLongName)) {
					for(String sensorName:tsdb.getGeneralStationSensorNames(generalStationInfo.name)) {
						sensorNameSet.add(sensorName);
					}
				}
			}
			sensorNames = tsdb.getBaseSchema(sensorNameSet.toArray(new String[0]));
		} catch (RemoteException e) {
			log.error(e);
		}
		model.setAllSensorNames(sensorNames);
		validateQuerySensorNames();

		PlotInfo[] plotInfos=null;
		try {
			plotInfos = Arrays.stream(tsdb.getPlotInfos()).filter(p->p.generalStationInfo.region.longName.equals(regionLongName)).toArray(PlotInfo[]::new);
		} catch (RemoteException e) {
			log.error(e);
		}
		model.setAllPlotInfos(plotInfos);
		validateQueryPlotInfos();
	}

	private void validateQuerySensorNames() {
		String[] allNames = model.getAllSensorNames();
		if(allNames==null||allNames.length==0) {
			model.setQuerySensorNames(new String[0]);
			return;
		}
		Map<String, Integer> allNameMap = Util.stringArrayToMap(allNames);
		String[] names = model.getQuerySensorNames();
		if(names==null||names.length==0) {
			model.setQuerySensorNames(new String[0]);
			return;
		}
		names = Arrays.stream(names).filter(name->allNameMap.containsKey(name)).toArray(String[]::new);
		model.setQuerySensorNames(names);
	}

	private void validateQueryPlotInfos() {
		System.out.println("validateQueryPlotInfos");
		PlotInfo[] allPlotInfos = model.getAllPlotInfos();
		if(allPlotInfos==null||allPlotInfos.length==0) {
			model.setQueryPlotInfos(new PlotInfo[0]);
			return;
		}
		Map<String, Integer> allPlotMap = Util.stringArrayToMap(Arrays.stream(allPlotInfos).map(p->p.name).toArray(String[]::new));
		PlotInfo[] plotInfos = model.getQueryPlotInfos();
		if(plotInfos==null||plotInfos.length==0) {
			model.setQueryPlotInfos(new PlotInfo[0]);
			return;
		}
		System.out.println("+validateQueryPlotInfos");
		plotInfos = Arrays.stream(plotInfos).filter(p->allPlotMap.containsKey(p.name)).toArray(PlotInfo[]::new);
		model.setQueryPlotInfos(plotInfos);
	}

	public void createZipFile(String filename) {
		printLine("start export...");
		String[] sensorNames = model.getQuerySensorNames();
		printLine("sensorNames: "+Util.arrayToString(sensorNames));
		if(Util.empty(sensorNames)) {
			return;
		}
		PlotInfo[] plotInfos = model.getQueryPlotInfos();
		if(Util.empty(plotInfos)) {
			return;
		}
		System.out.println("plots: "+plotInfos.length);

		FileOutputStream fileOutputStream;
		try {
			printLine("create file: "+filename);
			fileOutputStream = new FileOutputStream(filename);


			ZipOutputStream zipOutputStream = new ZipOutputStream(fileOutputStream);
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



			for(PlotInfo plotInfo:plotInfos) {
				String plotID = plotInfo.name;
				printLine("process plotID: "+plotID);
				AggregationInterval aggregationInterval = model.getAggregationInterval();
				DataQuality dataQuality = model.getDataQuality();
				boolean interpolated = model.getUseInterpolation();
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
							
							@SuppressWarnings("resource")
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
							
							for(TsEntry entry:timeseries.entryList) {
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
							
							//CSV.write(timeseries.tsIterator(), true, zipOutputStream, ",", "Na", CSVTimeType.TIMESTAMP_AND_DATETIME, false, false);
						} else {
							printLine("not processed: "+plotID);
						}
					}
				} catch (RemoteException e) {
					log.error(e);
				}
			}

			zipOutputStream.close();

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
