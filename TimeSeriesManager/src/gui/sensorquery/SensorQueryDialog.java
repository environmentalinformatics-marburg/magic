package gui.sensorquery;

import gui.sensorquery.QuerySensorModel.ViewType;
import gui.util.ComboBridge;

import java.rmi.RemoteException;

import org.apache.logging.log4j.Logger;
import org.eclipse.core.databinding.DataBindingContext;
import org.eclipse.jface.dialogs.Dialog;
import org.eclipse.jface.viewers.ArrayContentProvider;
import org.eclipse.jface.viewers.ComboViewer;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.jface.viewers.LabelProvider;
import org.eclipse.jface.viewers.StructuredSelection;
import org.eclipse.swt.SWT;
import org.eclipse.swt.custom.CLabel;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.RowData;
import org.eclipse.swt.layout.RowLayout;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.ProgressBar;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.ui.forms.widgets.FormToolkit;

import tsdb.DataQuality;
import tsdb.Region;
import tsdb.Sensor;
import tsdb.aggregated.AggregationInterval;
import tsdb.raw.TimestampSeries;
import tsdb.remote.GeneralStationInfo;
import tsdb.remote.RemoteTsDB;
import tsdb.util.Util;

public class SensorQueryDialog extends Dialog {

	@Override
	protected void configureShell(Shell newShell) {
		super.configureShell(newShell);
		newShell.setText("Sensor Query");
	}

	@Override
	protected Control createButtonBar(Composite parent) {
		return null;

	}

	@Override
	protected void createButtonsForButtonBar(Composite parent) {

	}

	private static final Logger log = Util.log;	

	private RemoteTsDB tsdb;

	private Composite container;
	private Group grpQuery;
	private ComboViewer comboViewerGeneralStation;
	private ComboViewer comboViewerRegion;
	private ComboViewer comboViewerSensor;
	ProgressBar progressBar;
	Button btnUpdate;

	MultiTimeSeriesExplorer multiTimeSeriesExplorer;

	public QuerySensorModel model = new QuerySensorModel();

	private DataBindingContext m_bindingContext;
	private final FormToolkit formToolkit = new FormToolkit(Display.getDefault());
	private CLabel lblQueryStatus;
	private Group grpInfo;
	private Label lblInfoText;
	private Label lblUnitText;
	private Group grpAggregation;
	private ComboViewer comboViewerAggregation;
	private Group grpView;


	/**
	 * Create the dialog.
	 * @param parentShell
	 * @param timeSeriesDatabase 
	 */
	public SensorQueryDialog(Shell parentShell, RemoteTsDB timeSeriesDatabase) {
		super(parentShell);
		setShellStyle(SWT.MAX | SWT.RESIZE);
		this.tsdb = timeSeriesDatabase;
	}

	/**
	 * Create contents of the dialog.
	 * @param parent
	 */
	@Override
	protected Control createDialogArea(Composite parent) {
		container = (Composite) super.createDialogArea(parent);
		GridLayout gl_container = new GridLayout(1, false);
		gl_container.marginWidth = 0;
		gl_container.marginHeight = 0;
		container.setLayout(gl_container);

		grpQuery = new Group(container, SWT.NONE);
		GridData gd_grpQuery = new GridData(SWT.FILL, SWT.FILL, true, false, 1, 1);
		gd_grpQuery.widthHint = 1069;
		grpQuery.setLayoutData(gd_grpQuery);
		grpQuery.setText("query");
		RowLayout rl_grpQuery = new RowLayout(SWT.HORIZONTAL);
		RowData row = new RowData();
		rl_grpQuery.fill = true;
		rl_grpQuery.center = true;
		grpQuery.setLayout(rl_grpQuery);

		//****************** Region *************************

		Group grpRegion = new Group(grpQuery, SWT.NONE);
		grpRegion.setText("Region");
		RowLayout rl_grpRegion = new RowLayout(SWT.HORIZONTAL);
		grpRegion.setLayout(rl_grpRegion);

		comboViewerRegion = new ComboViewer(new Combo(grpRegion, SWT.READ_ONLY));

		comboViewerRegion.setContentProvider(ArrayContentProvider.getInstance());
		comboViewerRegion.setLabelProvider(new LabelProvider(){
			@Override
			public String getText(Object element) {
				Region region = (Region) element;
				return region.longName;
			}});
		comboViewerRegion.addSelectionChangedListener(event->{			
			model.setRegion((Region) ((IStructuredSelection)event.getSelection()).getFirstElement());
		});

		//****************** GeneralStation *************************

		Group grpGeneralStation = new Group(grpQuery, SWT.NONE);
		grpGeneralStation.setText("General Station");
		grpGeneralStation.setLayout(new RowLayout(SWT.HORIZONTAL));

		comboViewerGeneralStation = new ComboViewer(grpGeneralStation, SWT.READ_ONLY);		
		comboViewerGeneralStation.setContentProvider(ArrayContentProvider.getInstance());
		comboViewerGeneralStation.setLabelProvider(new LabelProvider(){
			@Override
			public String getText(Object element) {
				GeneralStationInfo gs = (GeneralStationInfo) element;
				return gs.longName;
			}});
		comboViewerGeneralStation.addSelectionChangedListener(event->{			
			model.setGeneralStationInfo((GeneralStationInfo) ((IStructuredSelection)event.getSelection()).getFirstElement());
		});


		//****************** Sensor *************************

		Group grpSensor = new Group(grpQuery, SWT.NONE);
		grpSensor.setText("Sensor");
		grpSensor.setLayout(new RowLayout(SWT.HORIZONTAL));

		comboViewerSensor = new ComboViewer(grpSensor, SWT.READ_ONLY);		
		comboViewerSensor.setContentProvider(ArrayContentProvider.getInstance());
		comboViewerSensor.setLabelProvider(new LabelProvider(){
			@Override
			public String getText(Object element) {
				return (String) element;
			}});
		comboViewerSensor.addSelectionChangedListener(event->{
			model.setSensorName((String) ((IStructuredSelection)event.getSelection()).getFirstElement());
		});

		grpAggregation = new Group(grpQuery, SWT.NONE);
		grpAggregation.setText("Aggregation");
		grpAggregation.setLayout(new RowLayout(SWT.HORIZONTAL));

		comboViewerAggregation = new ComboViewer(grpAggregation, SWT.READ_ONLY);
		comboViewerAggregation.setContentProvider(ArrayContentProvider.getInstance());
		comboViewerAggregation.setLabelProvider(new LabelProvider(){
			@Override
			public String getText(Object element) {
				return (String)element;
			}});
		comboViewerAggregation.addSelectionChangedListener(event->{
			model.setAggregationName((String) ((IStructuredSelection)event.getSelection()).getFirstElement());
		});

		grpView = new Group(grpQuery, SWT.NONE);
		grpView.setText("View");
		grpView.setLayout(new RowLayout(SWT.HORIZONTAL));

		ComboViewer comboViewerView = new ComboViewer(grpView, SWT.READ_ONLY);
		ComboBridge<ViewType> viewBridge = new ComboBridge<ViewType>(comboViewerView);
		ViewType[] viewTypes = new ViewType[]{ViewType.COMPARE,ViewType.DIFF};
		viewBridge.setLabelMapper(v->{switch (v) {
		case COMPARE:
			return "standard";
		case DIFF:
			return "difference";
		default:
			return "[?]";
		}});
		viewBridge.setInput(viewTypes);
		viewBridge.setSelection(viewTypes[0]);
		viewBridge.addSelectionChangedCallback(v->model.setViewType(v));

		Group grpQuery_1 = new Group(grpQuery, SWT.NONE);
		grpQuery_1.setText("query");
		RowLayout rl_grpQuery_1 = new RowLayout(SWT.HORIZONTAL);
		rl_grpQuery_1.center = true;
		grpQuery_1.setLayout(rl_grpQuery_1);

		btnUpdate = new Button(grpQuery_1, SWT.NONE);
		btnUpdate.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				runQuery();				
			}
		});
		btnUpdate.setText("update");

		lblQueryStatus = new CLabel(grpQuery_1, SWT.NONE);
		//formToolkit.adapt(lblQueryStatus);
		//formToolkit.paintBordersFor(lblQueryStatus);
		lblQueryStatus.setText("---");

		progressBar = new ProgressBar(grpQuery_1, SWT.SMOOTH);
		progressBar.setVisible(false);

		grpInfo = new Group(grpQuery, SWT.NONE);
		grpInfo.setText("Info");
		RowLayout rl_grpInfo = new RowLayout(SWT.VERTICAL);
		rl_grpInfo.marginTop = 0;
		rl_grpInfo.marginBottom = 0;
		grpInfo.setLayout(rl_grpInfo);
		//formToolkit.adapt(grpInfo);
		//formToolkit.paintBordersFor(grpInfo);

		lblInfoText = new Label(grpInfo, SWT.CENTER);
		lblInfoText.setAlignment(SWT.CENTER);
		//formToolkit.adapt(lblNewLabel, true, true);
		lblInfoText.setText("New Label");

		lblUnitText = new Label(grpInfo, SWT.NONE);
		//formToolkit.adapt(lblUnitText, true, true);
		lblUnitText.setText("2New Label2");


		//***************************************************

		container.layout();

		m_bindingContext = initDataBindings();

		updateRegions();

		//updateFromRegionCombo((Region) ((IStructuredSelection)comboRegionViewer.getSelection()).getFirstElement());

		lblQueryStatus.setText("ready        ");

		multiTimeSeriesExplorer = new MultiTimeSeriesExplorer(container, SWT.NONE);
		GridData gd_multiTimeSeriesExplorer = new GridData(SWT.FILL, SWT.FILL, true, true, 1, 1);
		gd_multiTimeSeriesExplorer.heightHint = 440;
		multiTimeSeriesExplorer.setLayoutData(gd_multiTimeSeriesExplorer);

		String[] aggregationNames = new String[]{"hour","day","week","month","year"};
		model.setAggregationNames(aggregationNames);
		model.setAggregationName("day");


		return container;
	}





	private void runQuery() {
		multiTimeSeriesExplorer.clearTimestampSeries();

		AggregationInterval aggregationInterval = AggregationInterval.DAY;
		switch(model.getAggregationName()) {
		case "hour":
			aggregationInterval = AggregationInterval.HOUR;
			break;
		case "day":
			aggregationInterval = AggregationInterval.DAY;
			break;
		case "week":
			aggregationInterval = AggregationInterval.WEEK;
			break;
		case "month":
			aggregationInterval = AggregationInterval.MONTH;
			break;
		case "year":
			aggregationInterval = AggregationInterval.YEAR;
			break;
		default:
			log.warn("unknown aggregate: "+model.getAggregationName());
		}

		GeneralStationInfo generalStationInfo = model.getGeneralStationInfo();
		String sensorName = model.getSensorName();
		if(generalStationInfo==null||sensorName==null) {			
			return;			
		}

		final AggregationInterval agg = aggregationInterval;
		Thread worker = new Thread(()->runQueryAsync(generalStationInfo, agg));
		worker.start();


	}

	private void runQueryAsync(GeneralStationInfo generalStationInfo, AggregationInterval aggregationInterval) {

		try {

			//ArrayList<String> names = Util.streamToList(generalStation.getStationAndVirtualPlotNames());
			String[] names = tsdb.getPlotIDsByGeneralStationByLongName(generalStationInfo.longName);

			callAsync(()->{
				btnUpdate.setEnabled(false);
				lblQueryStatus.setText("running");
				progressBar.setVisible(true);
				progressBar.setMinimum(0);
				progressBar.setMaximum(names.length);
				this.container.layout();
			});			

			for(int i=0;i<names.length;i++) {
				String name = names[i];			
				System.out.println(name+"  sensor name: "+model.getSensorName());
				TimestampSeries ts = null;
				TimestampSeries ts_compare = null;
				String queryType = null;
				DataQuality dataQuality = DataQuality.EMPIRICAL;
				ViewType viewType = model.getViewType();
				if(viewType==ViewType.DIFF) {
					queryType = "difference";
					dataQuality = DataQuality.STEP;
				}
				String[] sensorNames = new String[]{model.getSensorName()};
				if(model.getSensorName().equals("WD")) {
					sensorNames = new String[]{sensorNames[0],"WV"};
				}

				try {
					if(!Util.empty(tsdb.getValidSchema(name, sensorNames))) {
						ts = tsdb.plot(queryType,name, sensorNames, aggregationInterval, dataQuality, false);
						ts_compare = tsdb.plot(queryType,name, sensorNames, aggregationInterval, DataQuality.NO, false);
					}
				} catch(Exception e) {
					e.printStackTrace();
					log.error(e.toString());
				}
				if(ts!=null) {
					final int progress=i;
					final TimestampSeries ts_new = ts;
					final TimestampSeries ts_compare_new = ts_compare;
					callAsync(()->multiTimeSeriesExplorer.addTimestampSeries(ts_new,aggregationInterval,name,ts_compare_new));
					callAsync(()->progressBar.setSelection(progress));
				}
			}

			callAsync(()->progressBar.setSelection(0));

		} catch (Exception e) {
			log.error(e);
		}

		callAsync(()->{
			btnUpdate.setEnabled(true);
			lblQueryStatus.setText("ready");
			progressBar.setVisible(false);
		});
	}

	private void callAsync(Runnable runnable) {
		getParentShell().getDisplay().asyncExec(runnable);	
	}



	/**
	 * Return the initial size of the dialog.
	 */
	@Override
	protected Point getInitialSize() {
		return new Point(1123, 723);
	}

	private void updateRegions() {
		try {
			Region[] regions = tsdb.getRegions();
			model.setRegions(regions);
		} catch(RemoteException e) {
			log.error(e);
		}
	}

	protected DataBindingContext initDataBindings() {
		DataBindingContext dbc = new DataBindingContext();

		model.addPropertyChangeListener("regions",event -> regionsChange((Region[])event.getNewValue()));
		model.addPropertyChangeListener("region", event -> regionChange((Region)event.getNewValue()));		
		model.addPropertyChangeListener("generalStationInfos",event -> generalStationsChange((GeneralStationInfo[])event.getNewValue()));
		model.addPropertyChangeListener("generalStationInfo",event -> generalStationChange((GeneralStationInfo)event.getNewValue()));
		model.addPropertyChangeListener("sensorNames",event -> sensorNamesChange((String[])event.getNewValue()));
		//model.addPropertyChangeListener("sensorName", event -> sensorNameChange((String)event.getNewValue()));
		//model.addPropertyChangeCallback("sensorName", (String x)->sensorNameChange(x));
		model.addPropertyChangeCallback("sensorName", this::sensorNameChange);
		model.addPropertyChangeCallback("aggregationNames", this::aggregationNamesChange);
		model.addPropertyChangeCallback("aggregationName", this::aggregationNameChange);

		return dbc;
	}

	private void regionsChange(Region[] regions) {
		System.out.println("regionsChange");
		if(regions!=null&&regions.length>0) {
			comboViewerRegion.setInput(regions);
			model.setRegion(regions[0]);
		} else {
			comboViewerRegion.setInput(null);
			model.setRegion(null);
		}
		grpQuery.layout();
	}	

	private void regionChange(Region region) {
		try {
			if(region!=null) {
				System.out.println("region select change: "+region.name);
				comboViewerRegion.setSelection(new StructuredSelection(region));
				GeneralStationInfo[] generalStationInfos = tsdb.getGeneralStationInfos(region.name);
				System.out.println(generalStationInfos.length);
				model.setGeneralStationInfos(generalStationInfos);
			} else {
				comboViewerRegion.setSelection(null);
				model.setGeneralStationInfos(null);
			}
		} catch(RemoteException e) {
			log.error(e);
		}
	}

	private void generalStationsChange(GeneralStationInfo[] generalStationInfos) {
		System.out.println("generalStations");
		if(generalStationInfos!=null&&generalStationInfos.length>0) {
			comboViewerGeneralStation.setInput(generalStationInfos);
			model.setGeneralStationInfo(generalStationInfos[0]);
		} else {
			comboViewerGeneralStation.setInput(null);
			model.setGeneralStationInfo(null);
		}
		grpQuery.layout();
	}

	private void generalStationChange(GeneralStationInfo generalStationInfo) {
		System.out.println("generalStation select change");
		try {
			if(generalStationInfo!=null) {
				comboViewerGeneralStation.setSelection(new StructuredSelection(generalStationInfo));			
				/*Set<LoggerType> loggerTypes = new HashSet<LoggerType>();			
				generalStationInfo.stationList.forEach(station->loggerTypes.add(station.loggerType));
				generalStationInfo.virtualPlots.stream()
				.flatMap(virtualPlot->virtualPlot.intervalList.stream())
				.map(i->{try{
					return timeSeriesDatabase.getLoggerType(i.value.get_logger_type_name());}
				catch(RemoteException e) {
					log.error(e);
					return null; //??
				}})
				.forEach(lt->loggerTypes.add(lt));
				Set<String> sensorNames = new TreeSet<String>();
				loggerTypes.stream()
				.map(lt->{					
					try {
						return timeSeriesDatabase.getBaseSchema(lt.sensorNames);
					} catch (Exception e) {
						log.error(e);
						return null;
					}})
					.forEach(s->{for(String n:s){sensorNames.add(n);}});			
				model.setSensorNames(sensorNames.toArray(new String[0]));*/
				String[] sensorNames = tsdb.getGeneralStationSensorNames(generalStationInfo.name);
				model.setSensorNames(sensorNames);
			} else {
				comboViewerGeneralStation.setSelection(null);
				model.setSensorNames(null);
			}
		} catch(RemoteException e) {
			log.error(e);
		}
	}

	private void sensorNamesChange(String[] sensorNames) {
		System.out.println("sensorNames");
		String sensorName = null;
		if(sensorNames!=null&&sensorNames.length>0) {
			comboViewerSensor.setInput(sensorNames);
			sensorName = model.getSensorName();
			if(sensorName==null||!Util.containsString(sensorNames, sensorName)) {
				sensorName = sensorNames[0];
			}	
		} else {
			comboViewerSensor.setInput(null);
		}
		model.setSensorName(null);
		model.setSensorName(sensorName);
		grpQuery.layout();
	}

	private void sensorNameChange(String sensorName) {
		System.out.println("sensorName change: "+sensorName);
		if(sensorName!=null) {
			comboViewerSensor.setSelection(new StructuredSelection(sensorName));
			String sensorInfoText = "";
			String sensorUnitText = "";
			try {
				Sensor sensor = tsdb.getSensor(sensorName);
				if(sensor!=null) {
					System.out.println("get sensor: "+sensorName+"  "+sensor.description);
					sensorInfoText = Util.ifnull(sensor.description,"---");
					sensorUnitText = Util.ifnull(sensor.unitDescription,"---");
				}
			} catch (RemoteException e) {
				log.error(e);
			}
			lblInfoText.setText(sensorInfoText);
			lblUnitText.setText(sensorUnitText);

		} else {
			comboViewerSensor.setSelection(null);
			lblInfoText.setText("");
			lblUnitText.setText("");
		}
		grpQuery.layout();
	}

	private void aggregationNamesChange(String[] aggregationNames) {
		if(aggregationNames!=null&&aggregationNames.length>0) {
			comboViewerAggregation.setInput(aggregationNames);
			model.setAggregationName(aggregationNames[0]);
		} else {
			comboViewerAggregation.setInput(null);
			model.setAggregationName(null);
		}
		grpQuery.layout();
	}

	private void aggregationNameChange(String aggregationName) {
		if(aggregationName!=null) {
			comboViewerAggregation.setSelection(new StructuredSelection(aggregationName));
		} else {
			comboViewerAggregation.setSelection(null);
		}
		grpQuery.layout();
	}
}
