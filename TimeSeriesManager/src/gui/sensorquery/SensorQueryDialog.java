package gui.sensorquery;

import gui.query.TimeSeriesView;

import java.beans.PropertyChangeEvent;
import java.beans.PropertyChangeListenerProxy;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.TreeSet;
import java.util.stream.Collectors;
import java.util.stream.Stream;




























import javax.management.Query;

import org.apache.logging.log4j.Logger;
import org.eclipse.jface.dialogs.Dialog;
import org.eclipse.jface.dialogs.IDialogConstants;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Table;
import org.eclipse.jface.viewers.ArrayContentProvider;
import org.eclipse.jface.viewers.IBaseLabelProvider;
import org.eclipse.jface.viewers.IContentProvider;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.jface.viewers.LabelProvider;
import org.eclipse.jface.viewers.StructuredSelection;
import org.eclipse.jface.viewers.StructuredViewer;
import org.eclipse.jface.viewers.TableViewer;
import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.custom.CCombo;
import org.eclipse.swt.events.PaintEvent;
import org.eclipse.swt.events.PaintListener;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.widgets.Text;








































import timeseriesdatabase.DataQuality;
import timeseriesdatabase.GeneralStation;
import timeseriesdatabase.LoggerType;
import timeseriesdatabase.Region;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.aggregated.AggregationInterval;
import timeseriesdatabase.raw.TimestampSeries;
import util.Util;
import swing2swt.layout.BorderLayout;








































import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.jface.viewers.ComboViewer;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.layout.FormLayout;
import org.eclipse.swt.layout.FormData;
import org.eclipse.swt.layout.FormAttachment;







import org.eclipse.swt.layout.RowData;

import swing2swt.layout.FlowLayout;




























import org.eclipse.jface.viewers.ISelectionChangedListener;
import org.eclipse.jface.viewers.SelectionChangedEvent;
import org.eclipse.core.databinding.DataBindingContext;
import org.eclipse.core.databinding.observable.value.IObservableValue;
import org.eclipse.core.databinding.beans.IBeanValueProperty;
import org.eclipse.core.databinding.beans.PojoProperties;
import org.eclipse.core.databinding.Binding;
import org.eclipse.jface.databinding.swt.WidgetProperties;
import org.eclipse.jface.layout.RowDataFactory;
import org.eclipse.core.databinding.beans.BeanProperties;
import org.eclipse.core.databinding.UpdateValueStrategy;
import org.eclipse.swt.layout.RowLayout;
import org.eclipse.swt.custom.ScrolledComposite;
import org.eclipse.wb.swt.SWTResourceManager;
import org.eclipse.ui.forms.widgets.FormToolkit;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Canvas;

import processinggraph.Node;
import processinggraph.QueryPlan;

public class SensorQueryDialog extends Dialog {

	private static final Logger log = Util.log;	

	private TimeSeriesDatabase timeSeriesDatabase;

	private Composite container;
	private Group grpQuery;
	private ComboViewer comboViewerGeneralStation;
	private ComboViewer comboViewerRegion;
	private ComboViewer comboViewerSensor;

	MultiTimeSeriesExplorer multiTimeSeriesExplorer;

	public QuerySensorModel model = new QuerySensorModel();

	private DataBindingContext m_bindingContext;
	private final FormToolkit formToolkit = new FormToolkit(Display.getDefault());

	/**
	 * Create the dialog.
	 * @param parentShell
	 * @param timeSeriesDatabase 
	 */
	public SensorQueryDialog(Shell parentShell, TimeSeriesDatabase timeSeriesDatabase) {
		super(parentShell);
		setShellStyle(SWT.MAX | SWT.RESIZE);
		this.timeSeriesDatabase = timeSeriesDatabase;
	}

	/**
	 * Create contents of the dialog.
	 * @param parent
	 */
	@Override
	protected Control createDialogArea(Composite parent) {
		container = (Composite) super.createDialogArea(parent);
		container.setLayout(new BorderLayout(0, 0));

		grpQuery = new Group(container, SWT.NONE);
		grpQuery.setText("query");
		grpQuery.setLayoutData(BorderLayout.NORTH);
		RowLayout rl_grpQuery = new RowLayout(SWT.HORIZONTAL);
		RowData row = new RowData();
		rl_grpQuery.fill = true;
		rl_grpQuery.center = true;
		grpQuery.setLayout(rl_grpQuery);

		//****************** Region *************************

		Group grpRegion = new Group(grpQuery, SWT.NONE);
		grpRegion.setText("Region");
		grpRegion.setLayout(new FillLayout(SWT.HORIZONTAL));

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
		grpGeneralStation.setLayout(new FillLayout(SWT.HORIZONTAL));

		comboViewerGeneralStation = new ComboViewer(grpGeneralStation, SWT.READ_ONLY);		
		comboViewerGeneralStation.setContentProvider(ArrayContentProvider.getInstance());
		comboViewerGeneralStation.setLabelProvider(new LabelProvider(){
			@Override
			public String getText(Object element) {
				GeneralStation gs = (GeneralStation) element;
				return gs.longName;
			}});
		comboViewerGeneralStation.addSelectionChangedListener(event->{			
			model.setGeneralStation((GeneralStation) ((IStructuredSelection)event.getSelection()).getFirstElement());
		});


		//****************** Sensor *************************

		Group grpSensor = new Group(grpQuery, SWT.NONE);
		grpSensor.setText("Sensor");
		grpSensor.setLayout(new FillLayout(SWT.HORIZONTAL));

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

		Group grpQuery_1 = new Group(grpQuery, SWT.NONE);
		grpQuery_1.setText("Query");
		grpQuery_1.setLayout(new FillLayout(SWT.HORIZONTAL));

		Button btnUpdate = new Button(grpQuery_1, SWT.NONE);
		btnUpdate.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				runQuery();				
			}
		});
		btnUpdate.setText("update");

		ScrolledComposite scrolledComposite = new ScrolledComposite(container, SWT.H_SCROLL | SWT.V_SCROLL);
		scrolledComposite.setBackground(SWTResourceManager.getColor(102, 205, 170));
		scrolledComposite.setLayoutData(BorderLayout.CENTER);
		scrolledComposite.setExpandHorizontal(true);
		scrolledComposite.setExpandVertical(true);

		multiTimeSeriesExplorer = new MultiTimeSeriesExplorer(scrolledComposite, SWT.NONE);
		formToolkit.adapt(multiTimeSeriesExplorer);
		formToolkit.paintBordersFor(multiTimeSeriesExplorer);
		scrolledComposite.setContent(multiTimeSeriesExplorer);
		scrolledComposite.setMinSize(multiTimeSeriesExplorer.computeSize(SWT.DEFAULT, SWT.DEFAULT));


		//***************************************************

		container.layout();

		m_bindingContext = initDataBindings();

		updateRegions();

		//updateFromRegionCombo((Region) ((IStructuredSelection)comboRegionViewer.getSelection()).getFirstElement());
		return container;
	}





	private void runQuery() {
		multiTimeSeriesExplorer.clearTimestampSeries();
		
		AggregationInterval aggregationInterval = AggregationInterval.DAY;

		GeneralStation generalStation = model.getGeneralStation();
		String sensorName = model.getSensorName();
		if(generalStation==null||sensorName==null) {			
			return;			
		}
		
		Thread worker = new Thread(()->runQueryAsync(generalStation, aggregationInterval));
		worker.start();
		
		
	}
	
	private void runQueryAsync(GeneralStation generalStation, AggregationInterval aggregationInterval) {
		ArrayList<String> names = Util.streamToList(generalStation.getStationAndVirtualPlotNames());
		for(String name:names) {			
			System.out.println(name+"  sensor name: "+model.getSensorName());
			TimestampSeries ts = null;
			try {

				Node x = QueryPlan.plot(timeSeriesDatabase, name, model.getSensorName(), aggregationInterval, DataQuality.EMPIRICAL, false);
				ts = x.get(null, null).toTimestampSeries();
			} catch(Exception e) {
				log.error(e.toString());
			}
			if(ts!=null) {
				final TimestampSeries ts_new = ts;
				getParentShell().getDisplay().asyncExec(()->multiTimeSeriesExplorer.addTimestampSeries(ts_new,aggregationInterval));				
			}
		}
	}

	/**
	 * Return the initial size of the dialog.
	 */
	@Override
	protected Point getInitialSize() {
		return new Point(497, 300);
	}

	private void updateRegions() {
		Region[] regions = timeSeriesDatabase.getRegions().toArray(new Region[0]);
		model.setRegions(regions);
		//comboViewerRegion.setInput(regions);
		//comboViewerRegion.getCombo().select(0);
		//model.setRegions(regions);
		//updateFromRegionCombo(regions[0]);
		//grpQuery.pack();
	}

	/*private void updateFromRegionCombo(Region region) {
		System.out.println("region: "+region);
		GeneralStation[] generalStations = timeSeriesDatabase.getGeneralStations(region).toArray(GeneralStation[]::new);
		comboViewerGeneralStation.setInput(generalStations);
		comboViewerGeneralStation.getCombo().select(0);
		grpQuery.pack();
	}

	private void updateFromGeneralStationCombo(GeneralStation generalStation) {

	}*/



	protected DataBindingContext initDataBindings() {
		DataBindingContext dbc = new DataBindingContext();

		model.addPropertyChangeListener("regions",event -> regionsChange((Region[])event.getNewValue()));
		model.addPropertyChangeListener("region", event -> regionChange((Region)event.getNewValue()));		
		model.addPropertyChangeListener("generalStations",event -> generalStationsChange((GeneralStation[])event.getNewValue()));
		model.addPropertyChangeListener("generalStation",event -> generalStationChange((GeneralStation)event.getNewValue()));
		model.addPropertyChangeListener("sensorNames",event -> sensorNamesChange((String[])event.getNewValue()));
		model.addPropertyChangeListener("sensorName", event -> sensorNameChange((String)event.getNewValue()));

		return dbc;
	}

	private void regionsChange(Region[] regions) {
		System.out.println("regions");
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
		System.out.println("region select change");
		if(region!=null) {
			comboViewerRegion.setSelection(new StructuredSelection(region));			
			model.setGeneralStations(timeSeriesDatabase.getGeneralStations(region).toArray(GeneralStation[]::new));
		} else {
			comboViewerRegion.setSelection(null);
			model.setGeneralStations(null);
		}		
	}

	private void generalStationsChange(GeneralStation[] generalStations) {
		System.out.println("generalStations");
		if(generalStations!=null&&generalStations.length>0) {
			comboViewerGeneralStation.setInput(generalStations);
			model.setGeneralStation(generalStations[0]);
		} else {
			comboViewerGeneralStation.setInput(null);
			model.setGeneralStation(null);
		}
		grpQuery.layout();
	}

	private void generalStationChange(GeneralStation generalStation) {
		System.out.println("generalStation select change");
		if(generalStation!=null) {
			comboViewerGeneralStation.setSelection(new StructuredSelection(generalStation));			
			Set<LoggerType> loggerTypes = new HashSet<LoggerType>();			
			generalStation.stationList.forEach(station->loggerTypes.add(station.loggerType));
			generalStation.virtualPlots.stream()
			.flatMap(virtualPlot->virtualPlot.intervalList.stream())
			.map(i->timeSeriesDatabase.getLoggerType(i.value.get_logger_type_name()))
			.forEach(lt->loggerTypes.add(lt));
			Set<String> sensorNames = new TreeSet<String>();
			loggerTypes.stream()
			.map(lt->timeSeriesDatabase.getBaseAggregationSchema(lt.sensorNames))
			.forEach(s->{for(String n:s){sensorNames.add(n);}});			
			model.setSensorNames(sensorNames.toArray(new String[0]));
		} else {
			comboViewerGeneralStation.setSelection(null);
			model.setSensorNames(null);
		}		
	}

	private void sensorNamesChange(String[] sensorNames) {
		System.out.println("sensorNames");
		if(sensorNames!=null&&sensorNames.length>0) {
			comboViewerSensor.setInput(sensorNames);
			model.setSensorName(sensorNames[0]);
		} else {
			comboViewerSensor.setInput(null);
			model.setSensorName(null);
		}
		grpQuery.layout();
	}

	private void sensorNameChange(String sensorName) {
		System.out.println("sensorName change: "+sensorName);
		if(sensorName!=null) {
			comboViewerSensor.setSelection(new StructuredSelection(sensorName));			
		} else {
			comboViewerSensor.setSelection(null);
		}		
	}
}
