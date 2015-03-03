package tsdb.gui;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.rmi.NotBoundException;
import java.rmi.RemoteException;
import java.rmi.registry.LocateRegistry;
import java.rmi.registry.Registry;

import org.eclipse.core.databinding.observable.Realm;
import org.eclipse.jface.databinding.swt.SWTObservables;
import org.eclipse.swt.SWT;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Text;

import tsdb.TsDB;
import tsdb.TsDBFactory;
import tsdb.gui.export.CollectorDialog;
import tsdb.gui.info.LoggerTypeInfoDialog;
import tsdb.gui.info.NewSensorInfoDialog;
import tsdb.gui.info.NewSourceCatalogInfoDialog;
import tsdb.gui.info.StationsInfoDialog;
import tsdb.gui.info.VirtualPlotInfoDialog;
import tsdb.gui.query.QueryDialog;
import tsdb.gui.sensorquery.SensorQueryDialog;
import tsdb.remote.RemoteTsDB;
import tsdb.remote.ServerTsDB;
import tsdb.util.Util;

public class TimeSeriesManager {

	//private static final Logger log = LogManager.getLogger();

	public RemoteTsDB remoteTsDB;

	public Shell shell;
	public Text textBox;

	public PrintBox printbox;

	public static void main(String[] args) {		
		TimeSeriesManager timeSeriesManager = new TimeSeriesManager();
		timeSeriesManager.run();
	}	

	public void run() {
		Display display = new Display();
		Realm.runWithDefault(SWTObservables.getRealm(display), new Runnable() {
			public void run() {
				shell = new Shell(display);
				try {
					init();
				} catch (RemoteException | NotBoundException e) {
					e.printStackTrace();
				}
				//shell.pack();
				shell.open();
				while (!shell.isDisposed()) {
					if (!display.readAndDispatch())
						display.sleep();
				}
				display.dispose();
				System.out.println("...end");
			}
		});
		display.dispose();	
	}	

	private void init() throws RemoteException, NotBoundException {
		boolean useRemote = false;
		//boolean useRemote = true;

		System.out.println("start...");

		if(!useRemote) {
			TsDB tsdb = TsDBFactory.createDefault();
			this.remoteTsDB =  new ServerTsDB(tsdb);
		} else {

			System.out.println("start RemoteTsDB...");
			//Registry registry = LocateRegistry.getRegistry("localhost",StartServerTsDB.REGISTRY_PORT);
			Registry registry = LocateRegistry.getRegistry(TsDBFactory.RMI_DEFAULT_SERVER_IP,TsDBFactory.RMI_REGISTRY_PORT);
			System.out.println("list: "+Util.arrayToString(registry.list()));


			String hostname = null;
			try {
				hostname = InetAddress.getLocalHost().getHostAddress();
			} catch (UnknownHostException e) {
				e.printStackTrace();
			}
			System.out.println("this host IP is " + hostname);



			remoteTsDB = (RemoteTsDB) registry.lookup(TsDBFactory.get_rmi_server_url());

			System.out.println("remoteTsDB: "+remoteTsDB.toString()+"  "+remoteTsDB.getClass());

		}

		String connectionText="";
		if(remoteTsDB.getClass().equals(ServerTsDB.class)) {
			connectionText = "internal local connection";
		} else {
			connectionText = "remote connection "+TsDBFactory.get_rmi_server_url();
		}

		shell.setText("Time Series Database Manager ["+connectionText+"]");
		shell.setSize(300, 400);
		shell.setLayout(new FillLayout());

		Menu menuBar = new Menu(shell, SWT.BAR);

		Menu infoMenu = addMenuColumn(menuBar,"Info");

		addMenuItem(infoMenu,"sensors",x->(new NewSensorInfoDialog(shell,remoteTsDB)).open());
		addMenuItem(infoMenu,"stations",x->(new StationsInfoDialog(shell,remoteTsDB)).open());
		addMenuItem(infoMenu,"virtual plots",x->(new VirtualPlotInfoDialog(shell,remoteTsDB)).open());
		addMenuItem(infoMenu,"general stations",x->(new tsdb.gui.info.GeneralStationInfoDialog(shell, remoteTsDB)).open());
		addMenuItem(infoMenu,"logger types",x->(new LoggerTypeInfoDialog(shell, remoteTsDB)).open());
		addMenuItem(infoMenu,"source catalog",x->(new NewSourceCatalogInfoDialog(shell, remoteTsDB)).open());

		Menu queryMenu = addMenuColumn(menuBar,"Query");
		addMenuItem(queryMenu,"query", x->(new QueryDialog(shell,remoteTsDB)).open());
		addMenuItem(queryMenu,"query sensors", x->(new SensorQueryDialog(shell,remoteTsDB)).open());
		addMenuItem(queryMenu,"export", x->(new CollectorDialog(shell,remoteTsDB)).open());

		Menu statisticsMenu = addMenuColumn(menuBar,"Statistics");
		addMenuItem(statisticsMenu, "statistics", x->(new StatisticsDialog(shell, remoteTsDB)).open());


		textBox = new Text(shell, SWT.MULTI | SWT.BORDER | SWT.WRAP | SWT.V_SCROLL);
		textBox.append("start");
		textBox.setEditable(false);		
		printbox = new PrintBox(this);

		shell.setMenuBar(menuBar); 

	}

	private void addMenuItem(Menu menu,String title,Listener listener) {
		MenuItem dataGenerationItem = new MenuItem(menu, SWT.PUSH);
		dataGenerationItem.setText(title);
		dataGenerationItem.addListener(SWT.Selection, listener);	
	}

	private Menu addMenuColumn(Menu menuBar, String title) {
		MenuItem menuHeader = new MenuItem(menuBar, SWT.CASCADE);
		menuHeader.setText(title);
		Menu menuEntry = new Menu(shell, SWT.DROP_DOWN);
		menuHeader.setMenu(menuEntry);
		return menuEntry; 
	}
}
