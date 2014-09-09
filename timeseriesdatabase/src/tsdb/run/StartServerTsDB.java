package tsdb.run;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.rmi.RemoteException;
import java.rmi.registry.LocateRegistry;
import java.rmi.registry.Registry;
import java.rmi.server.RemoteServer;
import java.rmi.server.UnicastRemoteObject;

import tsdb.FactoryTsDB;
import tsdb.TsDB;
import tsdb.remote.RemoteTsDB;
import tsdb.remote.ServerTsDB;

public class StartServerTsDB {	
	public static final String SERVERTSDB_NAME = "ServerTsDB";
	public static int REGISTRY_PORT = 16825;
	public static int SERVER_PORT = 16826;

	public static void main(String[] args) throws RemoteException {
		/*System.out.println("start...");
		TsDB tsdb = FactoryTsDB.createDefault();
		try {
			ServerTsDB servertsdb = new ServerTsDB(tsdb);
			RemoteTsDB stubTsDB = (RemoteTsDB) UnicastRemoteObject.exportObject((RemoteTsDB)servertsdb, 0);
			System.out.println("create registry..."+stubTsDB.getClass().getMethods().length);
			Registry registry = LocateRegistry.createRegistry(Registry.REGISTRY_PORT);
			System.out.println("bind tsdserver...");
			registry.rebind(SERVERTSDB_NAME, stubTsDB);
			System.out.println("...tsdserver bound");
		} catch (Exception e) {
			e.printStackTrace();
		}		
		System.out.println("...ready");
		Thread.setDefaultUncaughtExceptionHandler(new UncaughtExceptionHandler() {		
			@Override
			public void uncaughtException(Thread t, Throwable e) {
				System.out.println(e);				
			}
		});*/

		String hostname = null;
		try {
			hostname = InetAddress.getLocalHost().getHostAddress();
		} catch (UnknownHostException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		System.out.println("server IP is " + hostname);
		
		if(hostname.equals("127.0.1.1")) {
			hostname = "192.168.191.183";
			System.setProperty( "java.rmi.server.hostname", "192.168.191.183" ) ;
		}
		
		

		String server_url = "rmi://"+hostname+":"+SERVER_PORT+"/"+SERVERTSDB_NAME;
		System.out.println("server url: "+server_url);

		RemoteServer.setLog(System.out);
		Thread.setDefaultUncaughtExceptionHandler((t,e) -> System.out.println(e));
		System.out.println("open database...");
		TsDB tsdb = FactoryTsDB.createDefault();
		ServerTsDB servertsdb = new ServerTsDB(tsdb);
		RemoteTsDB remoteTsDB = servertsdb;
		System.out.println("create registry...");
		Registry registry = LocateRegistry.createRegistry(REGISTRY_PORT);
		System.out.println("bind remote...");
		RemoteTsDB stub = (RemoteTsDB) UnicastRemoteObject.exportObject( remoteTsDB, 0 ); 
		registry.rebind(server_url, stub);
		System.out.println("ready...");
	}
}
