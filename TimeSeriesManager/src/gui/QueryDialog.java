package gui;

import java.time.LocalDateTime;
import java.util.ArrayList;

import org.apache.logging.log4j.Logger;
import org.eclipse.swt.widgets.DateTime;
import org.eclipse.swt.widgets.Dialog;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.FileDialog;
import org.eclipse.swt.widgets.Shell;

import swing2swt.layout.BorderLayout;
import timeseriesdatabase.CSVTimeType;
import timeseriesdatabase.GeneralStation;
import timeseriesdatabase.LoggerType;
import timeseriesdatabase.QueryProcessor;
import timeseriesdatabase.Station;
import timeseriesdatabase.TimeConverter;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.aggregated.AggregationInterval;
import timeseriesdatabase.aggregated.TimeSeries;
import timeseriesdatabase.raw.TimestampSeries;
import util.CSV;
import util.Pair;
import util.Util;
import util.iterator.TimeSeriesIterator;

import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.layout.RowLayout;
import org.eclipse.swt.layout.FormLayout;
import org.eclipse.swt.layout.FormData;
import org.eclipse.swt.layout.FormAttachment;
import org.eclipse.swt.layout.RowData;

import swing2swt.layout.FlowLayout;

import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Canvas;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.events.PaintListener;
import org.eclipse.swt.events.PaintEvent;
import org.eclipse.wb.swt.SWTResourceManager;

public class QueryDialog extends Dialog {

	private static Logger log = Util.log;

	private TimeSeriesDatabase timeSeriesDatabase;
	private QueryProcessor qp;


	protected Shell shlAggregatedQuery;

	private Combo comboGeneralStation;
	private Combo comboPlotID;
	private Combo comboSensorName;
	private Combo comboAggregation;

	/*private Button CheckButtonPhysical;
	private Button CheckButtonEmpirical;
	private Button CheckButtonStep;
	private Button CheckButtonInterpolated;*/

	private Button buttonUpdate;

	//private Canvas canvasDataView;

	DataExplorer dataExplorer;

	private Group grpTestgroup;
	private Combo comboQuality;
	private Button checkButtonInterpolated2;
	private Button btnSaveInCsv;
	private Label label;
	private Button button;

	/**
	 * Create the dialog.
	 * @param parent
	 * @param timeSeriesDatabase
	 */
	public QueryDialog(Shell parent, TimeSeriesDatabase timeSeriesDatabase) {
		super(parent, SWT.DIALOG_TRIM | SWT.APPLICATION_MODAL | SWT.MAX | SWT.RESIZE);
		setText("SWT Dialog");
		this.timeSeriesDatabase = timeSeriesDatabase;
		this.qp = new QueryProcessor(timeSeriesDatabase);
		//this.dataView = new DataView();		
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
		//dataView.canvas = canvasDataView;
		updateGUI();
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
		shlAggregatedQuery.setSize(1264, 300);
		shlAggregatedQuery.setText("Aggregated Query");
		shlAggregatedQuery.setLayout(new BorderLayout(0, 0));

		Composite composite = new Composite(shlAggregatedQuery, SWT.NONE);
		composite.setLayoutData(BorderLayout.NORTH);
		composite.setLayout(new FlowLayout(FlowLayout.LEFT, 5, 5));

		Group grpGeneral = new Group(composite, SWT.NONE);
		grpGeneral.setText("General");
		grpGeneral.setLayout(new FlowLayout(FlowLayout.CENTER, 5, 5));

		comboGeneralStation = new Combo(grpGeneral, SWT.NONE);
		comboGeneralStation.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				updateGUIplotID();
				updateGUISensorName();
			}
		});

		Group grpPlot = new Group(composite, SWT.NONE);
		grpPlot.setText("Plot");
		grpPlot.setLayout(new FlowLayout(FlowLayout.CENTER, 5, 5));

		comboPlotID = new Combo(grpPlot, SWT.NONE);
		comboPlotID.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				updateGUISensorName();
			}
		});

		Group grpSensor = new Group(composite, SWT.NONE);
		grpSensor.setText("Sensor");
		grpSensor.setLayout(new FlowLayout(FlowLayout.CENTER, 5, 5));

		comboSensorName = new Combo(grpSensor, SWT.NONE);

		Group grpTime = new Group(composite, SWT.NONE);
		grpTime.setText("Time");
		grpTime.setLayout(new FlowLayout(FlowLayout.CENTER, 5, 5));
		
		label = new Label(grpTime, SWT.NONE);
		label.setText("________________________________________");
		
		button = new Button(grpTime, SWT.NONE);
		button.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				BeginEndDateTimeDialog dialog = new BeginEndDateTimeDialog(shlAggregatedQuery);
				Pair<LocalDateTime, LocalDateTime> result = dialog.open();
				if(result!=null) {
					String begin = result.a.toString();
					String end = result.b.toString();
				label.setText(begin+" - "+end);
				}
			}
		});
		button.setText("...");

		Group grpAggregation = new Group(composite, SWT.NONE);
		grpAggregation.setText("Aggregation");
		grpAggregation.setLayout(new FlowLayout(FlowLayout.CENTER, 5, 5));

		comboAggregation = new Combo(grpAggregation, SWT.NONE);

		//**************************
		grpTestgroup = new Group(composite, SWT.NONE);
		grpTestgroup.setText("Quality");
		grpTestgroup.setLayout(new FlowLayout(FlowLayout.CENTER, 5, 5));

		comboQuality = new Combo(grpTestgroup, SWT.NONE);
		comboQuality.setItems(new String[] {"no check", "physical range", "physical range + step range", "physical range + step range + empirical range"});
		comboQuality.setBounds(0, 10, 91, 23);
		comboQuality.select(3);

		checkButtonInterpolated2 = new Button(grpTestgroup, SWT.CHECK);
		checkButtonInterpolated2.setText("Interpolated");
		checkButtonInterpolated2.setSelection(true);
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
		//***************************************************

		buttonUpdate = new Button(composite, SWT.NONE);
		buttonUpdate.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				runQuery();
			}
		});
		buttonUpdate.setText("update");

		btnSaveInCsv = new Button(composite, SWT.NONE);
		btnSaveInCsv.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				saveInCSV();
			}
		});
		btnSaveInCsv.setText("export to CSV file");

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
		String[] querySchema = new String[]{comboSensorName.getText()};
		Long queryStart = null;
		Long queryEnd = null;
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
		boolean useInterpolation = checkButtonInterpolated2.getSelection();

		//0:"no check", 1:"physical range", 2:"physical range + step range", 3:"physical range + step range + empirical range"
		int qualitySelectionIndex = comboQuality.getSelectionIndex();
		switch(qualitySelectionIndex) {
		case 0:
			break;
		case 1:
			checkPhysicalRange = true;
			break;
		case 2:
			checkPhysicalRange = true;
			checkStepRange = true;
			break;
		case 3:
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

		buttonUpdate.setEnabled(false);

		Thread worker = new Thread() {
			@Override
			public void run(){

				System.out.println(cPhysicalRange+" "+cEmpiricalRange+" "+cStepRange+" "+useInterpolation);
				
				TimestampSeries resultTimeSeries = null;
				try{				
					TimeSeriesIterator result = qp.queryAggregated(plotID, querySchema, queryStart, queryEnd, agg, cPhysicalRange, cEmpiricalRange, cStepRange, useInterpolation);
					if(result!=null) {
						resultTimeSeries = TimestampSeries.create(result);
					}
				} catch (Exception e) {

					e.printStackTrace();

				}
				
				final TimestampSeries finalResultTimeSeries = resultTimeSeries;

				
				getParent().getDisplay().asyncExec(new Runnable() {

					@Override
					public void run() {
						if(finalResultTimeSeries!=null) {
							dataExplorer.setData(finalResultTimeSeries,agg);
						}
						buttonUpdate.setEnabled(true);

					}
				});



			}
		};

		worker.start();




	}


	void updateGUI() {
		updateGUIgeneralstations();
		updateGUIplotID();
		updateGUISensorName();
		updateGUIAggregation();
		updateGUIInfo();
	}

	void updateGUIgeneralstations() {
		//String[] generalStations = timeSeriesDatabase.generalStationMap.keySet().toArray(new String[0]);
		//TODO: just for testing!
		String[] generalStations = new String[]{"HEG","HEW"};
		comboGeneralStation.setItems(generalStations);
		comboGeneralStation.setText(generalStations[0]);
	}

	void updateGUIplotID() {
		String generalStationName = comboGeneralStation.getText();
		GeneralStation generalStation = timeSeriesDatabase.generalStationMap.get(generalStationName);
		if(generalStation!=null) {
			java.util.List<Station> list = generalStation.stationList;
			String[] plotIDs = new String[list.size()];
			for(int i=0;i<list.size();i++) {
				plotIDs[i] = list.get(i).plotID;
			}
			comboPlotID.setItems(plotIDs);
			comboPlotID.setText(plotIDs[0]);
		} else {
			comboPlotID.setItems(new String[]{});
		}

	}

	void updateGUISensorName() {
		String stationName = comboPlotID.getText();
		System.out.println("updateGUISensorName "+stationName);
		Station station = timeSeriesDatabase.stationMap.get(stationName);
		if(station!=null) {
			LoggerType loggerType = station.getLoggerType();
			ArrayList<String> sensorNames = new ArrayList<String>();
			System.out.println(timeSeriesDatabase.baseAggregatonSensorNameSet);
			for(String name:loggerType.sensorNames) {
				System.out.println("loggerType.sensorNames: "+name);
				if(timeSeriesDatabase.baseAggregatonSensorNameSet.contains(name)) {
					System.out.println("add: "+name);
					sensorNames.add(name);
				}
			}
			comboSensorName.setItems(sensorNames.toArray(new String[0]));
			comboSensorName.setText(sensorNames.get(0));
		} else {
			comboSensorName.setItems(new String[]{});
		}

	}

	void updateGUIAggregation() {
		//String[] generalStations = timeSeriesDatabase.generalStationMap.keySet().toArray(new String[0]);
		//TODO: just for testing!
		String[] aggregationNames = new String[]{"hour","day","week","month","year"};
		comboAggregation.setItems(aggregationNames);
		comboAggregation.setText("day");
	}

	void updateViewData() {
		/*if(queryResult!=null) {
			float[] data = queryResult.data[0];

			minValue = Float.MAX_VALUE;
			maxValue = -Float.MAX_VALUE;

			for(int offset=0;offset<data.length;offset++) {
				float value = data[offset];
				if(!Float.isNaN(value)) {
					if(value<minValue) {
						minValue = value;						
					}
					if(value>maxValue) {
						maxValue = value;						
					}
				}
			}
		} else {
			minValue = Float.NaN;
			maxValue = -Float.NaN;
		}*/
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
}
