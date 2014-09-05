package gui.export;

import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.rmi.RemoteException;
import java.util.Arrays;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import tsdb.DataQuality;
import tsdb.aggregated.AggregationInterval;
import tsdb.raw.TimestampSeries;
import tsdb.remote.GeneralStationInfo;
import tsdb.remote.PlotInfo;
import tsdb.remote.RemoteTsDB;
import tsdb.util.CSV;
import tsdb.util.CSVTimeType;
import tsdb.util.TsDBLogger;
import tsdb.util.Util;

public class CollectorController implements TsDBLogger {

	private CollectorModel model;

	private RemoteTsDB tsdb;

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

	public void createZipFile() {
		System.out.println("start createZipFile ...");

		String[] sensorNames = model.getQuerySensorNames();
		System.out.println("sensorNames: "+Util.arrayToString(sensorNames));
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
			fileOutputStream = new FileOutputStream("c:/testing/file.zip");


			ZipOutputStream zipOutputStream = new ZipOutputStream(fileOutputStream);
			zipOutputStream.setComment("new comment");
			zipOutputStream.setLevel(9);

			
			
			

			for(PlotInfo plotInfo:plotInfos) {
				String plotID = plotInfo.name;
				AggregationInterval aggregationInterval = AggregationInterval.DAY;
				DataQuality dataQuality = DataQuality.NO;
				boolean interpolated = false;
				try {
					System.out.println(Util.arrayToString(sensorNames));
					String[] schema = tsdb.getValidSchema(plotID, sensorNames);
					System.out.println(Util.arrayToString(schema));
					if(!Util.empty(schema)) {
						TimestampSeries timeseries = tsdb.plot(plotID, schema, aggregationInterval, dataQuality, interpolated);
						if(timeseries!=null) {
							ZipEntry zipEntry = new ZipEntry(plotID+".csv");
							zipOutputStream.putNextEntry(zipEntry);
							System.out.println(timeseries);
							CSV.write(timeseries.timeSeriesIterator(), true, zipOutputStream, ",", "Na", CSVTimeType.TIMESTAMP_AND_DATETIME, false, false);
						}
					}
				} catch (RemoteException e) {
					log.error(e);
				}
			}
			
			zipOutputStream.close();
			
		} catch (IOException e1) {
		}
		System.out.println("... end");
	}



}
