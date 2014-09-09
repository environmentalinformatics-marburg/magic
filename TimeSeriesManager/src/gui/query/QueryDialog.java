package gui.query;

import java.rmi.RemoteException;
import java.time.LocalDateTime;
import java.util.Arrays;

import org.apache.logging.log4j.Logger;
import org.eclipse.swt.SWT;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.layout.RowLayout;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Dialog;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.FileDialog;
import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.wb.swt.SWTResourceManager;

import swing2swt.layout.BorderLayout;
import tsdb.DataQuality;
import tsdb.Region;
import tsdb.Sensor;
import tsdb.TimeConverter;
import tsdb.aggregated.AggregationInterval;
import tsdb.aggregated.BaseAggregationTimeUtil;
import tsdb.graph.Node;
import tsdb.raw.TimestampSeries;
import tsdb.remote.RemoteTsDB;
import tsdb.util.CSV;
import tsdb.util.CSVTimeType;
import tsdb.util.Pair;
import tsdb.util.Util;

public class QueryDialog extends Dialog {

	private static Logger log = Util.log;

	private RemoteTsDB tsdb;

	protected Shell shlAggregatedQuery;

	private Combo comboRegion;
	private Combo comboGeneralStation;
	private Combo comboPlotID;
	private Combo comboSensorName;
	private Combo comboAggregation;

	private Button buttonUpdate;

	DataExplorer dataExplorer;

	private Group grpTestgroup;
	private Combo comboQuality;
	private Button checkButtonInterpolated2;
	private Button btnSaveInCsv;
	private Label label;
	private Button button;

	private LocalDateTime beginDateTime;
	private LocalDateTime endDateTime;
	private Group grpAction;
	private Group grpInfo;
	private Label lblSensorInfo;
	private Label lblSensorUnitInfo;
	
	private Composite composite;

	private QueryModel model;

	/**
	 * Create the dialog.
	 * @param parent
	 * @param timeSeriesDatabase
	 */
	public QueryDialog(Shell parent, RemoteTsDB timeSeriesDatabase) {
		super(parent, SWT.DIALOG_TRIM | SWT.APPLICATION_MODAL | SWT.MAX | SWT.RESIZE);
		beginDateTime = null;
		endDateTime = null;
		setText("SWT Dialog");
		this.tsdb = timeSeriesDatabase;
		this.model = new QueryModel();
	}

	/**
	 * Open the dialog.
	 * @return the result
	 */
	public Object open() {
		createContents();
		shlAggregatedQuery.open();
		shlAggregatedQuery.layout();
		Display display = getParent().getDisplay();

		bind();
		updateRegionLongNames();
		model.setAggregationNames(new String[]{"hour","day","week","month","year"});
		model.setAggregationName("day");

		while (!shlAggregatedQuery.isDisposed()) {
			if (!display.readAndDispatch()) {
				display.sleep();
			}
		}
		return null;
	}

	/**
	 * Create contents of the dialog.
	 */
	private void createContents() {
		shlAggregatedQuery = new Shell(getParent(), getStyle());
		shlAggregatedQuery.setSize(781, 454);
		shlAggregatedQuery.setText("Aggregated Query");
		shlAggregatedQuery.setLayout(new BorderLayout(0, 0));

		composite = new Composite(shlAggregatedQuery, SWT.NONE);
		composite.setLayoutData(BorderLayout.NORTH);
		RowLayout rl_composite = new RowLayout(SWT.HORIZONTAL);
		rl_composite.center = true;
		composite.setLayout(rl_composite);

		Group grpRegion = new Group(composite, SWT.NONE);
		grpRegion.setText("Region");
		grpRegion.setLayout(new RowLayout(SWT.HORIZONTAL));

		comboRegion = new Combo(grpRegion, SWT.READ_ONLY);
		comboRegion.setItems(new String[]{"----------------"});		
		comboRegion.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				/*updateGUIgeneralstations();
				updateGUIplotID();
				updateGUISensorName();*/
				model.setRegionLongName(comboRegion.getText());
			}
		});

		Group grpGeneral = new Group(composite, SWT.NONE);
		grpGeneral.setText("General");
		grpGeneral.setLayout(new RowLayout(SWT.HORIZONTAL));

		comboGeneralStation = new Combo(grpGeneral, SWT.READ_ONLY);
		comboGeneralStation.setItems(new String[]{"-------------------------------"});
		comboGeneralStation.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				/*updateGUIplotID();
				updateGUISensorName();*/
				model.setGeneralStationLongName(comboGeneralStation.getText());
			}
		});

		Group grpPlot = new Group(composite, SWT.NONE);
		grpPlot.setText("Plot");
		grpPlot.setLayout(new RowLayout(SWT.HORIZONTAL));

		comboPlotID = new Combo(grpPlot, SWT.READ_ONLY);
		comboPlotID.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				//updateGUISensorName();
				model.setPlotID(comboPlotID.getText());
			}
		});

		Group grpSensor = new Group(composite, SWT.NONE);
		grpSensor.setText("Sensor");
		grpSensor.setLayout(new RowLayout(SWT.HORIZONTAL));

		comboSensorName = new Combo(grpSensor, SWT.READ_ONLY);
		comboSensorName.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				//updateGUIinterpolated();
				model.setSensorName(comboSensorName.getText());
			}
		});

		Group grpTime = new Group(composite, SWT.NONE);
		grpTime.setText("Time");
		grpTime.setLayout(new RowLayout(SWT.HORIZONTAL));

		label = new Label(grpTime, SWT.NONE);
		label.setText("________________________________________");

		button = new Button(grpTime, SWT.NONE);
		button.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				BeginEndDateTimeDialog dialog = new BeginEndDateTimeDialog(shlAggregatedQuery);
				Pair<LocalDateTime, LocalDateTime> result = dialog.open();
				if(result!=null) {
					beginDateTime = result.a;
					endDateTime = result.b;
					String begin = beginDateTime==null?"---":beginDateTime.toString();
					String end = endDateTime==null?"---":endDateTime.toString();
					label.setText(begin+" - "+end);
				}
			}
		});
		button.setText("...");

		Group grpAggregation = new Group(composite, SWT.NONE);
		grpAggregation.setText("Aggregation");
		grpAggregation.setLayout(new RowLayout(SWT.HORIZONTAL));

		comboAggregation = new Combo(grpAggregation, SWT.READ_ONLY);
		comboAggregation.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				model.setAggregationName(comboAggregation.getText());				
			}
		});

		//**************************
		grpTestgroup = new Group(composite, SWT.NONE);
		grpTestgroup.setText("Quality");
		grpTestgroup.setLayout(new RowLayout(SWT.HORIZONTAL));

		comboQuality = new Combo(grpTestgroup, SWT.READ_ONLY);
		comboQuality.setItems(new String[] {"no check", "physical range", "physical range + step range", "physical range + step range + empirical range"});
		comboQuality.setBounds(0, 10, 91, 23);
		comboQuality.select(3);

		checkButtonInterpolated2 = new Button(grpTestgroup, SWT.CHECK);
		checkButtonInterpolated2.setText("Interpolated");
		//checkButtonInterpolated2.setSelection(true);
		checkButtonInterpolated2.setBounds(0, 33, 85, 16);

		//******************************
		/*
		Group grpQuality = new Group(composite, SWT.NONE);
		grpQuality.setText("Quality");
		grpQuality.setLayout(new FlowLayout(FlowLayout.CENTER, 5, 5));



		CheckButtonPhysical = new Button(grpQuality, SWT.CHECK);
		CheckButtonPhysical.setSelection(true);
		CheckButtonPhysical.setText("Physical Check");

		CheckButtonEmpirical = new Button(grpQuality, SWT.CHECK);
		CheckButtonEmpirical.setSelection(true);
		CheckButtonEmpirical.setText("Empirical Check");

		CheckButtonStep = new Button(grpQuality, SWT.CHECK);
		CheckButtonStep.setSelection(true);
		CheckButtonStep.setText("Step Check");

		CheckButtonInterpolated = new Button(grpQuality, SWT.CHECK);
		CheckButtonInterpolated.setSelection(true);
		CheckButtonInterpolated.setText("Interpolated");
		 */

		grpAction = new Group(composite, SWT.NONE);
		grpAction.setText("Action");
		grpAction.setLayout(new RowLayout(SWT.HORIZONTAL));
		//***************************************************

		buttonUpdate = new Button(grpAction, SWT.NONE);
		buttonUpdate.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				runQuery();
			}
		});
		buttonUpdate.setText("update");

		btnSaveInCsv = new Button(grpAction, SWT.NONE);
		btnSaveInCsv.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				saveInCSV();
			}
		});
		btnSaveInCsv.setText("export to CSV file");

		grpInfo = new Group(composite, SWT.NONE);
		grpInfo.setText("Info");
		RowLayout rl_grpInfo = new RowLayout(SWT.VERTICAL);
		rl_grpInfo.marginTop = 0;
		rl_grpInfo.marginBottom = 0;
		grpInfo.setLayout(rl_grpInfo);

		lblSensorInfo = new Label(grpInfo, SWT.NONE);
		lblSensorInfo.setText("New Label");

		lblSensorUnitInfo = new Label(grpInfo, SWT.NONE);
		lblSensorUnitInfo.setText("New Label");

		Label labelStatus = new Label(shlAggregatedQuery, SWT.NONE);
		labelStatus.setLayoutData(BorderLayout.SOUTH);
		labelStatus.setText("status");

		/**canvasDataView = new Canvas(shell, SWT.NONE);
		canvasDataView.addPaintListener(new PaintListener() {
			public void paintControl(PaintEvent e) {
				dataView.updateViewData();
				dataView.paintCanvas(e.gc);
			}
		});
		canvasDataView.setLayoutData(BorderLayout.CENTER);*/

		dataExplorer = new DataExplorer(shlAggregatedQuery, SWT.NONE);
		dataExplorer.setBackground(SWTResourceManager.getColor(SWT.COLOR_WHITE));
		//grpQuality.setLayoutData(BorderLayout.CENTER);


	}

	private void runQuery() {

		String plotID = comboPlotID.getText();

		String sensorName = comboSensorName.getText();
		String[] querySchema;
		if(sensorName.equals("WD")) {
			querySchema = new String[]{sensorName,"WV"};
		} else {
			querySchema = new String[]{sensorName};
		}


		Long queryStart = Util.ifnull(beginDateTime, x->(Long) BaseAggregationTimeUtil.alignQueryTimestampToBaseAggregationTime(TimeConverter.DateTimeToOleMinutes(x)));
		Long queryEnd = Util.ifnull(endDateTime, x->(Long) BaseAggregationTimeUtil.alignQueryTimestampToBaseAggregationTime(TimeConverter.DateTimeToOleMinutes(x)));
		AggregationInterval aggregationInterval = AggregationInterval.HOUR;
		//{"hour","day","week","month","year"};
		String aggText = comboAggregation.getText();
		if(aggText.equals("hour")) {
			aggregationInterval = AggregationInterval.HOUR;
		} else if(aggText.equals("day")) {
			aggregationInterval = AggregationInterval.DAY;
		} else if(aggText.equals("week")) {
			aggregationInterval = AggregationInterval.WEEK;
		} else if(aggText.equals("month")) {
			aggregationInterval = AggregationInterval.MONTH;
		} else if(aggText.equals("year")) {
			aggregationInterval = AggregationInterval.YEAR;
		} else {
			log.warn("GUI AggregationInterval not found");
		}		

		boolean checkPhysicalRange = false;
		boolean checkStepRange = false;
		boolean checkEmpiricalRange = false;
		boolean useInterpolation;
		if(checkButtonInterpolated2.isEnabled()) {
			useInterpolation = checkButtonInterpolated2.getSelection();
		} else {
			useInterpolation = false;
		}

		//0:"no check", 1:"physical range", 2:"physical range + step range", 3:"physical range + step range + empirical range"
		DataQuality dq = DataQuality.NO;
		int qualitySelectionIndex = comboQuality.getSelectionIndex();
		switch(qualitySelectionIndex) {
		case 0:
			dq = DataQuality.NO;
			break;
		case 1:
			dq = DataQuality.PHYSICAL;
			checkPhysicalRange = true;
			break;
		case 2:
			dq = DataQuality.STEP;
			checkPhysicalRange = true;
			checkStepRange = true;
			break;
		case 3:
			dq = DataQuality.EMPIRICAL;
			checkPhysicalRange = true;
			checkStepRange = true;
			checkEmpiricalRange = true;
			break;
		default:
			log.warn("comboQuality error");
		}



		final AggregationInterval agg = aggregationInterval;
		final boolean cPhysicalRange = checkPhysicalRange;
		final boolean cStepRange = checkStepRange;
		final boolean cEmpiricalRange = checkEmpiricalRange;		
		final DataQuality dataQuality = dq;

		buttonUpdate.setEnabled(false);

		final boolean useCache = comboRegion.getText().equals("cache");


		Thread worker = new Thread() {
			@Override
			public void run(){

				TimestampSeries resultTimeSeries = null;
				try{				
					/*System.out.println("query dataQuality: "+dataQuality);
					TimeSeriesIterator result = qp.virtualquery_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality, agg, useInterpolation);
					//TimeSeriesIterator result = qp.query_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality, agg, useInterpolation);
					//TimeSeriesIterator result = qp.query_base_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality, agg, useInterpolation);

					resultTimeSeries = Util.ifnull(result, x->TimestampSeries.create(x));*/
					Node node;

					if(useCache) {
						resultTimeSeries = tsdb.cache(plotID, querySchema, agg);
					} else {
						resultTimeSeries = tsdb.plot(plotID, querySchema, agg, dataQuality, useInterpolation);
					}

					/*if(useCache) {
						String streamName = plotID;
						node = Aggregated.createFromBase(timeSeriesDatabase, CacheBase.create(timeSeriesDatabase, streamName, querySchema), agg);
					} else if(useInterpolation) {
						node = Aggregated.createInterpolated(timeSeriesDatabase, plotID, querySchema, agg, dataQuality);
					} else {
						node = Aggregated.create(timeSeriesDatabase, plotID, querySchema, agg, dataQuality);
					}*/
				} catch (Exception e) {

					e.printStackTrace();

				}

				final TimestampSeries finalResultTimeSeries = resultTimeSeries;


				getParent().getDisplay().asyncExec(new Runnable() {

					@Override
					public void run() {
						//if(finalResultTimeSeries!=null) {
						dataExplorer.setData(finalResultTimeSeries,agg);
						//}
						buttonUpdate.setEnabled(true);

					}
				});



			}
		};

		worker.start();




	}


	void updateGUI() {
		updateGUIregions();
		updateGUIgeneralstations();
		updateGUIplotID();
		updateGUISensorName();
		updateGUIAggregation();
		updateGUIInfo();
	}

	void updateGUIregions() {
		try {
			String[] longNames = tsdb.getRegionLongNames();
			String[] items = Arrays.copyOf(longNames, longNames.length+1);
			items[longNames.length] = "cache";

			//String[] generalStations = new String[]{"AEG","AEW","HEG","HEW","SEG","SEW"};
			comboRegion.setItems(items);
			comboRegion.setText(items[0]);
		} catch(RemoteException e) {
			log.error(e);
		}
	}

	void updateGUIgeneralstations() {
		try {
			String regionLongName = comboRegion.getText();		
			Region region = tsdb.getRegionByLongName(regionLongName);
			if(region!=null) {
				String[] generalStationNames = tsdb.getGeneralStationLongNames(region.name);
				comboGeneralStation.setItems(generalStationNames);
				if(generalStationNames.length>0) {
					comboGeneralStation.setText(generalStationNames[0]);
				} else {
					comboGeneralStation.setText("");	
				}
			} else if(regionLongName.equals("cache")) {
				System.out.println(regionLongName);
				comboGeneralStation.setItems(new String[]{"cache"});
				comboGeneralStation.setText("cache");			
				String[] streams = tsdb.cacheStorageGetStreamNames();
				comboPlotID.setItems(streams);
				comboPlotID.setText(streams.length>0?streams[0]:"");
			} else {
				comboPlotID.setItems(new String[0]);
			}

			/*String[] generalStations = timeSeriesDatabase.generalStationMap.keySet().toArray(new String[0]);
		//String[] generalStations = new String[]{"AEG","AEW","HEG","HEW","SEG","SEW"};
		comboGeneralStation.setItems(generalStations);
		comboGeneralStation.setText(generalStations[0]);*/
		} catch(RemoteException e) {
			log.error(e);
		}
	}

	void updateGUIplotID() {
		try {
			String generalStationName = comboGeneralStation.getText();
			if(!generalStationName.equals("cache")) {				
				String[] plotIDs = tsdb.getPlotIDsByGeneralStationByLongName(generalStationName);
				if(plotIDs!=null) {
					comboPlotID.setItems(plotIDs);
					comboPlotID.setText(plotIDs[0]);
				} else {
					comboPlotID.setItems(new String[0]);
				}

			} else {

			}




			/*
		if(generalStation!=null) {
			java.util.List<Station> list = generalStation.stationList;
			if(list.size()>0) {
			String[] plotIDs = new String[list.size()];
			for(int i=0;i<list.size();i++) {
				plotIDs[i] = list.get(i).plotID;
			}
			comboPlotID.setItems(plotIDs);
			comboPlotID.setText(plotIDs[0]);
			} else {
				comboPlotID.setItems(new String[0]);
			}
		} else {
			comboPlotID.setItems(new String[0]);
		}*/
		} catch(RemoteException e) {
			log.error(e);
		}

	}

	void updateGUISensorName() {

		try {

			String stationName = comboPlotID.getText();


			System.out.println("updateGUISensorName "+stationName);
			String[] schema = null;
			/*VirtualPlotInfo virtualplotInfo = timeSeriesDatabase.getVirtualPlotInfo(stationName);
			if(virtualplotInfo!=null) {
				//schema = virtualplotInfo.getSchema();
			} else {*/
			schema = tsdb.getPlotSchema(stationName);
			//} 

			if(comboGeneralStation.getText().equals("cache")) {
				schema = tsdb.getCacheSchemaNames(stationName);
			}
			if(schema!=null) {

				String[] sensorNames = tsdb.getBaseSchema(schema);
				if(sensorNames.length>0) {
					String oldName = comboSensorName.getText();
					comboSensorName.setItems(sensorNames);
					int indexPos = Util.getIndexInArray(oldName, sensorNames);				
					if(indexPos<0) {
						indexPos = 0;					
					}
					comboSensorName.setText(sensorNames[indexPos]);
				} else {
					comboSensorName.setItems(new String[0]);
					comboSensorName.setText("");
				}
			} else {
				comboSensorName.setItems(new String[0]);
				comboSensorName.setText("");
			}

			updateGUIinterpolated();

		} catch(RemoteException e) {
			log.error(e);
		}
	}

	protected void updateGUIinterpolated() {
		try {
			String sensorName = comboSensorName.getText();
			if(sensorName!=null && !sensorName.isEmpty()) {
				Sensor sensor = tsdb.getSensor(sensorName);
				if(sensor != null) {
					checkButtonInterpolated2.setEnabled(sensor.useInterpolation);
					return;
				}
			}
			checkButtonInterpolated2.setEnabled(false);
		} catch(RemoteException e) {
			log.error(e);
		}
	}

	void updateGUIAggregation() {
		//String[] generalStations = timeSeriesDatabase.generalStationMap.keySet().toArray(new String[0]);
		//TODO: just for testing!
		String[] aggregationNames = new String[]{"hour","day","week","month","year"};
		comboAggregation.setItems(aggregationNames);
		comboAggregation.setText("day");
	}



	void updateGUIInfo() {
		/*if(queryResult!=null) {
			long starttimestamp = queryResult.getFirstTimestamp();
			long endtimestamp = queryResult.getLastTimestamp();
			LocalDateTime start = TimeConverter.oleMinutesToLocalDateTime(starttimestamp);
			LocalDateTime end = TimeConverter.oleMinutesToLocalDateTime(endtimestamp);
			String s = queryResult.data[0].length+" entries \t\t time: "+start+" - "+end+"\t\t value range: "+minValue+" - "+maxValue+"\t\tquery time: "+(queryTimer.getTime("query")/1000f)+"s";
			labelInfo.setText(s);
		} else {
			labelInfo.setText("no result");
		}*/
	}

	protected void saveInCSV() {
		TimestampSeries result = dataExplorer.getTimeSeries();
		if(result!=null) {

			System.out.println("save in CSV file");

			FileDialog filedialog = new FileDialog(shlAggregatedQuery, SWT.SAVE);
			filedialog.setFilterNames(new String[] { "CSV Files", "All Files (*.*)" });
			filedialog.setFilterExtensions(new String[] { "*.csv", "*.*" });
			filedialog.setFilterPath("c:/timeseriesdatabase_output/");
			filedialog.setFileName("result.csv");
			String filename = filedialog.open();
			if(filename!=null) {
				System.out.println("Save to: " + filename);
				CSV.write(result, filename, ",", "NaN", CSVTimeType.TIMESTAMP_AND_DATETIME);
			}
		}

	}

	private void bind() {
		model.addPropertyChangeCallback("regionLongNames", this::onChangeRegionLongNames);
		model.addPropertyChangeCallback("regionLongName", this::onChangeRegionLongName);
		model.addPropertyChangeCallback("generalStationLongNames", this::onChangeGeneralStationLongNames);
		model.addPropertyChangeCallback("generalStationLongName", this::onChangeGeneralStationLongName);
		model.addPropertyChangeCallback("plotIDs", this::onChangePlotIDs);
		model.addPropertyChangeCallback("plotID", this::onChangePlotID);
		model.addPropertyChangeCallback("sensorNames", this::onChangeSensorNames);
		model.addPropertyChangeCallback("sensorName", this::onChangeSensorName);
		model.addPropertyChangeCallback("aggregationNames", this::onChangeAggregationNames);
		model.addPropertyChangeCallback("aggregationName", this::onChangeAggregationName);
	}

	void updateRegionLongNames() {
		String[] regionLongNames = null;
		try {
			String[] longNames = tsdb.getRegionLongNames();
			regionLongNames = Arrays.copyOf(longNames, longNames.length+1);
			regionLongNames[longNames.length] = "cache";
		} catch(RemoteException e) {
			log.error(e);
		}
		model.setRegionLongNames(regionLongNames);
	}

	private void onChangeRegionLongNames(String[] regionLongNames) {
		if(regionLongNames!=null&&regionLongNames.length>0) {
			comboRegion.setItems(regionLongNames);
			model.setRegionLongName(regionLongNames[0]);
		} else {
			comboRegion.setItems(new String[0]);
			model.setRegionLongName(null);
		}
	}

	private void onChangeRegionLongName(String regionLongName) {
		System.out.println("onChangeRegionLongName: "+regionLongName);
		String[] generalStationLongNames = null;
		if(regionLongName!=null) {
			comboRegion.setText(regionLongName);
			Region region = null;
			try {
				region = tsdb.getRegionByLongName(regionLongName);
			} catch (RemoteException e) {
				log.error(e);
			}
			if(region!=null) {
				try {
					generalStationLongNames = tsdb.getGeneralStationLongNames(region.name);
				} catch (RemoteException e) {
					log.error(e);
				}
			} else if(regionLongName.equals("cache")) {
				generalStationLongNames = new String[]{"cache"};
			}
		} else {
			comboRegion.setText("");
		}
		model.setGeneralStationLongNames(generalStationLongNames);
	}

	private void onChangeGeneralStationLongNames(String[] generalStationLongNames) {
		if(generalStationLongNames!=null&&generalStationLongNames.length>0) {
			comboGeneralStation.setItems(generalStationLongNames);
			model.setGeneralStationLongName(generalStationLongNames[0]);
		} else {
			comboGeneralStation.setItems(new String[0]);
			model.setGeneralStationLongName(null);
		}		
	}

	private void onChangeGeneralStationLongName(String generalStationLongName) {
		String[] plotIDs = null;
		if(generalStationLongName!=null) {
			comboGeneralStation.setText(generalStationLongName);
			if(generalStationLongName.equals("cache")) {
				try {
					plotIDs = tsdb.cacheStorageGetStreamNames();
				} catch (RemoteException e) {
					log.error(e);
				}				
			} else {
				try {
					plotIDs = tsdb.getPlotIDsByGeneralStationByLongName(generalStationLongName);
				} catch (RemoteException e) {
					log.error(e);
				}
			}
		} else {
			comboGeneralStation.setText("");
		}
		model.setPlotIDs(plotIDs);
	}

	private void onChangePlotIDs(String[] plotIDs) {
		if(plotIDs!=null&&plotIDs.length>0) {
			comboPlotID.setItems(plotIDs);
			model.setPlotID(plotIDs[0]);
		} else {
			comboPlotID.setItems(new String[0]);
			model.setPlotID(null);
		}

	}

	private void onChangePlotID(String plotID) {
		String[] sensorNames = null;
		if(plotID!=null) {
			comboPlotID.setText(plotID);			
			if("cache".equals(model.getGeneralStationLongName())) {
				try {
					sensorNames = tsdb.getCacheSchemaNames(plotID);
				} catch (RemoteException e) {
					log.error(e);
				}
			} else {
				try {
					sensorNames = tsdb.getPlotSchema(plotID);
				} catch (RemoteException e) {
					log.error(e);
				}
			}

		} else {
			comboPlotID.setText("");
		}
		if(sensorNames!=null) {
			try {
				sensorNames = tsdb.getBaseSchema(sensorNames);
			} catch (RemoteException e) {
				log.error(e);
				sensorNames = null;
			}
		}
		model.setSensorNames(sensorNames);
	}

	private void onChangeSensorNames(String[] sensorNames) {
		System.out.println("onChangeSensorNames: "+sensorNames.length);
		String sensorName = null;
		if(sensorNames!=null&&sensorNames.length>0) {
			comboSensorName.setItems(sensorNames);
			sensorName = model.getSensorName();
			if(sensorName==null||!Util.containsString(sensorNames, sensorName)) {
				sensorName = sensorNames[0];
			}			
		} else {
			comboSensorName.setItems(new String[0]);
		}
		System.out.println("onChangeSensorNames sensorName: "+sensorName);
		model.setSensorName(null);
		model.setSensorName(sensorName);
	}

	private void onChangeSensorName(String sensorName) {
		String sensorInfoText = "";
		String sensorUnitText = "";
		System.out.println("onChangeSensorName: "+sensorName);
		if(sensorName!=null) {
			comboSensorName.setText(sensorName);
			Sensor sensor = null;
			try {
				sensor = tsdb.getSensor(sensorName);
			} catch (RemoteException e) {
				log.error(e);
			}
			if(sensor!=null) {
				sensorInfoText = Util.ifnull(sensor.description,"---");
				sensorUnitText = Util.ifnull(sensor.unitDescription,"---");
			}
		} else {
			comboSensorName.setText("");
		}
		lblSensorInfo.setText(sensorInfoText);
		lblSensorUnitInfo.setText(sensorUnitText);
		composite.layout();
	}

	private void onChangeAggregationNames(String[] aggregationNames) {
		String aggregationName=null;
		if(aggregationNames!=null&&aggregationNames.length>0) {
			comboAggregation.setItems(aggregationNames);
			aggregationName = aggregationNames[0];
		} else {
			comboAggregation.setItems(new String[0]);
		}
		model.setAggregationName(aggregationName);
	}

	private void onChangeAggregationName(String aggregationName) {
		if(aggregationName!=null) {
			comboAggregation.setText(aggregationName);
		} else {
			comboAggregation.setText("");
		}
	}
}
