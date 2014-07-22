package gui;

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
	
	public Shell shell;
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


		Display display = new Display();		

		shell = new Shell(display);
		shell.setSize(300, 400);
		shell.setLayout(new FillLayout());

		Menu menuBar = new Menu(shell, SWT.BAR);
		MenuItem infoMenuHeader = new MenuItem(menuBar, SWT.CASCADE);
		infoMenuHeader.setText("Info");

		Menu infoMenu = new Menu(shell, SWT.DROP_DOWN);
		infoMenuHeader.setMenu(infoMenu);

		MenuItem sensorsItem = new MenuItem(infoMenu, SWT.PUSH);
		sensorsItem.setText("sensors");
		sensorsItem.addSelectionListener(new sensorsItemListener());
		
		MenuItem stationsItem = new MenuItem(infoMenu, SWT.PUSH);
		stationsItem.setText("stations");
		stationsItem.addSelectionListener(new stationsItemListener());
		
		MenuItem generalstationsItem = new MenuItem(infoMenu, SWT.PUSH);
		generalstationsItem.setText("general stations");
		generalstationsItem.addSelectionListener(new generalstationsItemListener());
		
		
		
		MenuItem queryMenuHeader = new MenuItem(menuBar, SWT.CASCADE);
		queryMenuHeader.setText("Query");
		Menu queryMenu = new Menu(shell, SWT.DROP_DOWN);
		queryMenuHeader.setMenu(queryMenu);
		
		MenuItem queryItem = new MenuItem(queryMenu, SWT.PUSH);
		queryItem.setText("query");
		queryItem.addSelectionListener(new queryItemListener());
		
		MenuItem statisticsMenuHeader = new MenuItem(menuBar, SWT.CASCADE);
		statisticsMenuHeader.setText("Statistics");
		Menu statisticsMenu = new Menu(shell, SWT.DROP_DOWN);
		statisticsMenuHeader.setMenu(statisticsMenu);
		
		MenuItem statisticsItem = new MenuItem(statisticsMenu, SWT.PUSH);
		statisticsItem.setText("statistics");
		statisticsItem.addSelectionListener(new statisticsItemListener());


		textBox = new Text(shell, SWT.MULTI | SWT.BORDER | SWT.WRAP | SWT.V_SCROLL);

		textBox.append("start");

		textBox.setEditable(false);
		
		
		
		printbox = new PrintBox(this);


		shell.setMenuBar(menuBar);        
		shell.open();
		while (!shell.isDisposed()) {
			if (!display.readAndDispatch())
				display.sleep();
		}
		display.dispose();		



		System.out.println("...end");		
	}	

	class sensorsItemListener extends SelectionAdapter {
		@Override
		public void widgetSelected(SelectionEvent event) {
			SensorsInfoDialog dialog = new SensorsInfoDialog(shell,timeSeriesDatabase);
			dialog.open();
		}
	}
	
	class stationsItemListener extends SelectionAdapter {
		@Override
		public void widgetSelected(SelectionEvent event) {
			StationsInfoDialog dialog = new StationsInfoDialog(shell,timeSeriesDatabase);
			dialog.open();

		}
	}
	
	class generalstationsItemListener extends SelectionAdapter {
		@Override
		public void widgetSelected(SelectionEvent event) {
			GeneralStationsInfoDialog dialog = new GeneralStationsInfoDialog(shell,timeSeriesDatabase);
			dialog.open();

		}
	}
	
	class aggregatedQueryItemListener extends SelectionAdapter {
		@Override
		public void widgetSelected(SelectionEvent event) {
			AggregatedQueryDialog dialog = new AggregatedQueryDialog(shell,timeSeriesDatabase);
			dialog.open();

		}
	}
	
	class queryItemListener extends SelectionAdapter {
		@Override
		public void widgetSelected(SelectionEvent event) {
			QueryDialog dialog = new QueryDialog(shell,timeSeriesDatabase);
			dialog.open();

		}
	}
	
	class statisticsItemListener extends SelectionAdapter {
		@Override
		public void widgetSelected(SelectionEvent event) {
			StatisticsDialog dialog = new StatisticsDialog(shell,timeSeriesDatabase);
			dialog.open();

		}
	}

}
