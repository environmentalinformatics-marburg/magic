package gui.query;


import gui.bridge.ComboBridge;

import java.rmi.RemoteException;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.HashSet;

import org.apache.logging.log4j.Logger;
import org.eclipse.jface.viewers.ComboViewer;
import org.eclipse.swt.SWT;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
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

import tsdb.DataQuality;
import tsdb.Region;
import tsdb.Sensor;
import tsdb.TimeConverter;
import tsdb.aggregated.AggregationInterval;
import tsdb.aggregated.BaseAggregationTimeUtil;
import tsdb.graph.Node;
import tsdb.raw.TimestampSeries;
import tsdb.remote.PlotInfo;
import tsdb.remote.RemoteTsDB;
import tsdb.util.CSV;
import tsdb.util.CSVTimeType;
import tsdb.util.Pair;
import tsdb.util.Util;
import org.eclipse.swt.layout.RowData;
import org.eclipse.swt.events.ControlAdapter;
import org.eclipse.swt.events.ControlEvent;

public class QueryDialog extends Dialog {

	private static Logger log = Util.log;

	private RemoteTsDB tsdb;

	protected Shell shlAggregatedQuery;

	private Combo comboRegion;
	private Combo comboGeneralStation;
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

	ComboBridge<PlotInfo> comboBridgePlotInfo;

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
		shlAggregatedQuery.addControlListener(new ControlAdapter() {
			@Override
			public void controlResized(ControlEvent e) {
				if(composite!=null) {
					composite.layout();
				}
			}
		});
		shlAggregatedQuery.setSize(1000, 600);
		shlAggregatedQuery.setText("Aggregated Query");
		GridLayout gl_shlAggregatedQuery = new GridLayout(1, true);
		gl_shlAggregatedQuery.horizontalSpacing = 0;
		gl_shlAggregatedQuery.verticalSpacing = 0;
		gl_shlAggregatedQuery.marginWidth = 0;
		gl_shlAggregatedQuery.marginHeight = 0;
		shlAggregatedQuery.setLayout(gl_shlAggregatedQuery);

		composite = new Composite(shlAggregatedQuery, SWT.NONE);
		composite.setLayoutData(new GridData(SWT.FILL, SWT.TOP, true, false, 1, 1));
		RowLayout rl_composite = new RowLayout(SWT.HORIZONTAL);
		rl_composite.spacing = 0;
		rl_composite.marginTop = 0;
		rl_composite.marginRight = 0;
		rl_composite.marginLeft = 0;
		rl_composite.marginBottom = 0;
		rl_composite.fill = true;
		composite.setLayout(rl_composite);

		Group grpRegion = new Group(composite, SWT.NONE);
		grpRegion.setText("Region");
		grpRegion.setLayout(new RowLayout(SWT.HORIZONTAL));

		comboRegion = new Combo(grpRegion, SWT.READ_ONLY);
		comboRegion.setItems(new String[]{"----------------"});		
		comboRegion.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				model.setRegionLongName(comboRegion.getText());
			}
		});

		Group grpGeneral = new Group(composite, SWT.NONE);
		grpGeneral.setText("General");
		RowLayout rl_grpGeneral = new RowLayout(SWT.HORIZONTAL);
		grpGeneral.setLayout(rl_grpGeneral);

		comboGeneralStation = new Combo(grpGeneral, SWT.READ_ONLY);
		comboGeneralStation.setItems(new String[]{"-------------------------------"});
		comboGeneralStation.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				model.setGeneralStationLongName(comboGeneralStation.getText());
			}
		});

		Group grpPlot = new Group(composite, SWT.NONE);
		grpPlot.setText("Plot");
		grpPlot.setLayout(new RowLayout(SWT.HORIZONTAL));

		ComboViewer comboViewerPlotInfo = new ComboViewer(grpPlot, SWT.READ_ONLY);
		comboBridgePlotInfo = new ComboBridge<PlotInfo>(comboViewerPlotInfo);
		comboBridgePlotInfo.setLabelMapper(p->{
			String s = p.name;
			if(p.isVIP) {
				s+=" (VIP)";
			}
			return s;
		});
		comboBridgePlotInfo.addSelectionChangedCallback(model::setPlotInfo);

		Group grpSensor = new Group(composite, SWT.NONE);
		grpSensor.setText("Sensor");
		grpSensor.setLayout(new RowLayout(SWT.HORIZONTAL));

		comboSensorName = new Combo(grpSensor, SWT.READ_ONLY);
		comboSensorName.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
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
		grpInfo.setLayoutData(new RowData(300, -1));
		grpInfo.setText("Info");
		grpInfo.setLayout(new GridLayout(1, false));

		lblSensorInfo = new Label(grpInfo, SWT.NONE);
		lblSensorInfo.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, true, 1, 1));
		lblSensorInfo.setText("New Label");

		lblSensorUnitInfo = new Label(grpInfo, SWT.NONE);
		lblSensorUnitInfo.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, true, 1, 1));
		lblSensorUnitInfo.setText("New Label");

		dataExplorer = new DataExplorer(shlAggregatedQuery, SWT.NONE);
		dataExplorer.setLayoutData(new GridData(SWT.FILL, SWT.FILL, false, true, 1, 1));
		dataExplorer.setBackground(SWTResourceManager.getColor(SWT.COLOR_WHITE));

		Label labelStatus = new Label(shlAggregatedQuery, SWT.NONE);
		labelStatus.setLayoutData(new GridData(SWT.LEFT, SWT.CENTER, true, false, 1, 1));
		labelStatus.setText("status");

		/*canvasDataView = new Canvas(shell, SWT.NONE);
		canvasDataView.addPaintListener(new PaintListener() {
			public void paintControl(PaintEvent e) {
				dataView.updateViewData();
				dataView.paintCanvas(e.gc);
			}
		});
		canvasDataView.setLayoutData(BorderLayout.CENTER);*/
		//grpQuality.setLayoutData(BorderLayout.CENTER);


	}

	private void runQuery() {

		String plotID = model.getPlotInfo().name;

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
						resultTimeSeries = tsdb.plot(null,plotID, querySchema, agg, dataQuality, useInterpolation);
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
		model.addPropertyChangeCallback("plotInfos", this::onChangePlotInfos);
		model.addPropertyChangeCallback("plotInfo", this::onChangePlotInfo);
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
		System.out.println("onChangeGeneralStationLongNames");
		if(generalStationLongNames!=null&&generalStationLongNames.length>0) {
			comboGeneralStation.setItems(generalStationLongNames);
			model.setGeneralStationLongName(generalStationLongNames[0]);
		} else {
			comboGeneralStation.setItems(new String[0]);
			model.setGeneralStationLongName(null);
		}		
	}

	private void onChangeGeneralStationLongName(String generalStationLongName) {
		System.out.println("onChangeGeneralStationLongName");
		PlotInfo[] plotInfos = null;
		if(generalStationLongName!=null) {
			comboGeneralStation.setText(generalStationLongName);
			if(generalStationLongName.equals("cache")) {
				try {
					String[] plotIDs = tsdb.cacheStorageGetStreamNames();
					plotInfos = Arrays.stream(plotIDs).map(p->new PlotInfo(p, "cache", "cache")).toArray(PlotInfo[]::new);
				} catch (RemoteException e) {
					log.error(e);
				}				
			} else {
				try {
					String[] plotIDs = tsdb.getPlotIDsByGeneralStationByLongName(generalStationLongName);
					System.out.println(Util.arrayToString(plotIDs));
					HashSet<String> set = new HashSet<String>();
					set.addAll(Arrays.asList(plotIDs));
					plotInfos = tsdb.getPlotInfos();
					System.out.println(set);
					System.out.println(Util.arrayToString(plotInfos));
					if(plotInfos!=null) {
						plotInfos = Arrays.stream(plotInfos).filter(p->set.contains(p.name)).toArray(PlotInfo[]::new);
						System.out.println(Util.arrayToString(plotInfos));
					}
				} catch (RemoteException e) {
					log.error(e);
				}
			}
		} else {
			comboGeneralStation.setText("");
		}
		model.setPlotInfos(plotInfos);
	}

	private void onChangePlotInfos(PlotInfo[] plotInfos) {
		System.out.println("onChangePlotInfos: "+Util.arrayToString(plotInfos));
		if(plotInfos!=null&&plotInfos.length>0) {
			comboBridgePlotInfo.setInput(plotInfos);
			model.setPlotInfo(plotInfos[0]);
		} else {
			comboBridgePlotInfo.setInput(null);
			model.setPlotInfo(null);
		}
	}

	private void onChangePlotInfo(PlotInfo plotInfo) {
		System.out.println("onChangePlotInfo: "+plotInfo);
		String[] sensorNames = null;
		if(plotInfo!=null) {
			comboBridgePlotInfo.setSelection(plotInfo);
			if("cache".equals(model.getGeneralStationLongName())) {
				try {
					sensorNames = tsdb.getCacheSchemaNames(plotInfo.name);
				} catch (RemoteException e) {
					log.error(e);
				}
			} else {
				try {
					sensorNames = tsdb.getPlotSchema(plotInfo.name);
				} catch (RemoteException e) {
					log.error(e);
				}
			}

		} else {
			comboBridgePlotInfo.clearSelection();
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
		System.out.println("onChangeSensorNames");
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
