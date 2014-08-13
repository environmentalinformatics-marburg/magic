package gui;

import gui.info.GeneralStationsInfoDialog;
import gui.info.LoggerTypeInfoDialog;
import gui.info.SensorsInfoDialog;
import gui.info.SourceCatalogInfoDialog;
import gui.info.StationsInfoDialog;
import gui.info.VirtualPlotInfoDialog;

import java.time.LocalDateTime;

import org.apache.logging.log4j.Logger;
import org.eclipse.swt.SWT;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.SelectionListener;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Text;

import timeseriesdatabase.Sensor;
import timeseriesdatabase.Station;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.TimeSeriesDatabaseFactory;
import timeseriesdatabase.aggregated.TimeSeries;
import timeseriesdatabase.raw.TimestampSeries;
import util.CSVTimeType;
import util.Util;

public class TimeSeriesManager {
	
	private static Logger log = Util.log;

	public TimeSeriesDatabase timeSeriesDatabase;
	
	public Shell shlTimeSeriesManager;
	public Text textBox;
	
	public PrintBox printbox;

	public static void main(String[] args) {		
		TimeSeriesManager timeSeriesManager = new TimeSeriesManager();
		timeSeriesManager.run();
	}	

	public void run() {
		System.out.println("start...");
		String databaseDirectory = "c:/timeseriesdatabase_database/";
		String configDirectory = "c:/git_magic/timeseriesdatabase/config/";
		String cacheDirectory = "c:/timeseriesdatabase_cache/";
		timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault(databaseDirectory, configDirectory, cacheDirectory);
		//timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();


		Display display = new Display();		

		shlTimeSeriesManager = new Shell(display);
		shlTimeSeriesManager.setText("time series database manager");
		shlTimeSeriesManager.setSize(300, 400);
		shlTimeSeriesManager.setLayout(new FillLayout());

		Menu menuBar = new Menu(shlTimeSeriesManager, SWT.BAR);
		MenuItem infoMenuHeader = new MenuItem(menuBar, SWT.CASCADE);
		infoMenuHeader.setText("Info");

		Menu infoMenu = new Menu(shlTimeSeriesManager, SWT.DROP_DOWN);
		infoMenuHeader.setMenu(infoMenu);

		MenuItem sensorsItem = new MenuItem(infoMenu, SWT.PUSH);
		sensorsItem.setText("sensors");
		sensorsItem.addSelectionListener(new sensorsItemListener());
		
		MenuItem stationsItem = new MenuItem(infoMenu, SWT.PUSH);
		stationsItem.setText("stations");
		stationsItem.addSelectionListener(new stationsItemListener());
		
		MenuItem virtualPlotItem = new MenuItem(infoMenu, SWT.PUSH);
		virtualPlotItem.setText("virtual plots");
		virtualPlotItem.addSelectionListener(new virtualPlotsItemListener());
		
		MenuItem generalstationsItem = new MenuItem(infoMenu, SWT.PUSH);
		generalstationsItem.setText("general stations");
		generalstationsItem.addSelectionListener(new generalstationsItemListener());
		
		MenuItem loggertypeItem = new MenuItem(infoMenu, SWT.PUSH);
		loggertypeItem.setText("logger types");
		loggertypeItem.addSelectionListener(new loggertypeItemListener());
		
		MenuItem sourcecatalogItem = new MenuItem(infoMenu, SWT.PUSH);
		sourcecatalogItem.setText("source catalog");
		sourcecatalogItem.addSelectionListener(new sourcecatalogItemListener());
		
		
		
		MenuItem queryMenuHeader = new MenuItem(menuBar, SWT.CASCADE);
		queryMenuHeader.setText("Query");
		Menu queryMenu = new Menu(shlTimeSeriesManager, SWT.DROP_DOWN);
		queryMenuHeader.setMenu(queryMenu);
		
		MenuItem queryItem = new MenuItem(queryMenu, SWT.PUSH);
		queryItem.setText("query");
		queryItem.addSelectionListener(new queryItemListener());
		
		MenuItem statisticsMenuHeader = new MenuItem(menuBar, SWT.CASCADE);
		statisticsMenuHeader.setText("Statistics");
		Menu statisticsMenu = new Menu(shlTimeSeriesManager, SWT.DROP_DOWN);
		statisticsMenuHeader.setMenu(statisticsMenu);
		
		MenuItem statisticsItem = new MenuItem(statisticsMenu, SWT.PUSH);
		statisticsItem.setText("statistics");
		statisticsItem.addSelectionListener(new statisticsItemListener());


		textBox = new Text(shlTimeSeriesManager, SWT.MULTI | SWT.BORDER | SWT.WRAP | SWT.V_SCROLL);

		textBox.append("start");

		textBox.setEditable(false);
		
		
		
		printbox = new PrintBox(this);


		shlTimeSeriesManager.setMenuBar(menuBar);        
		shlTimeSeriesManager.open();
		while (!shlTimeSeriesManager.isDisposed()) {
			if (!display.readAndDispatch())
				display.sleep();
		}
		display.dispose();		



		System.out.println("...end");		
	}	

	class sensorsItemListener extends SelectionAdapter {
		@Override
		public void widgetSelected(SelectionEvent event) {
			SensorsInfoDialog dialog = new SensorsInfoDialog(shlTimeSeriesManager,timeSeriesDatabase);
			dialog.open();
		}
	}
	
	class stationsItemListener extends SelectionAdapter {
		@Override
		public void widgetSelected(SelectionEvent event) {
			StationsInfoDialog dialog = new StationsInfoDialog(shlTimeSeriesManager,timeSeriesDatabase);
			dialog.open();

		}
	}
	
	class generalstationsItemListener extends SelectionAdapter {
		@Override
		public void widgetSelected(SelectionEvent event) {
			GeneralStationsInfoDialog dialog = new GeneralStationsInfoDialog(shlTimeSeriesManager,timeSeriesDatabase);
			dialog.open();
		}
	}
	
	class loggertypeItemListener extends SelectionAdapter {
		@Override
		public void widgetSelected(SelectionEvent event) {
			LoggerTypeInfoDialog dialog = new LoggerTypeInfoDialog(shlTimeSeriesManager,timeSeriesDatabase);
			dialog.open();
		}
	}

	class sourcecatalogItemListener extends SelectionAdapter {
		@Override
		public void widgetSelected(SelectionEvent event) {
			SourceCatalogInfoDialog dialog = new SourceCatalogInfoDialog(shlTimeSeriesManager, timeSeriesDatabase);
			dialog.open();
		}
	}
	
	class virtualPlotsItemListener extends SelectionAdapter {
		@Override
		public void widgetSelected(SelectionEvent event) {
			VirtualPlotInfoDialog dialog = new VirtualPlotInfoDialog(shlTimeSeriesManager, timeSeriesDatabase);
			dialog.open();
		}
	}
	
	class queryItemListener extends SelectionAdapter {
		@Override
		public void widgetSelected(SelectionEvent event) {
			QueryDialog dialog = new QueryDialog(shlTimeSeriesManager,timeSeriesDatabase);
			dialog.open();

		}
	}
	
	class statisticsItemListener extends SelectionAdapter {
		@Override
		public void widgetSelected(SelectionEvent event) {
			StatisticsDialog dialog = new StatisticsDialog(shlTimeSeriesManager,timeSeriesDatabase);
			dialog.open();

		}
	}

}
