package tsdb.server;

import java.net.MalformedURLException;
import java.rmi.AlreadyBoundException;
import java.rmi.RemoteException;
import java.rmi.registry.LocateRegistry;
import java.rmi.registry.Registry;
import java.rmi.server.UnicastRemoteObject;

import tsdb.FactoryTsDB;
import tsdb.TsDB;

public class StartServer {
	
	public static final String SERVER_NAME = "tsdserver";

	public static void main(String[] args) throws RemoteException, AlreadyBoundException, MalformedURLException {
		System.out.println("start...");
		
		TsDB timeSeriesDatabase = FactoryTsDB.createDefault();

        try {
            TSDServer tsdserver = new TSDServer(timeSeriesDatabase);
            TSDServerInterface stub = (TSDServerInterface) UnicastRemoteObject.exportObject(tsdserver, 0);
            System.out.println("create registry...");
            Registry registry = LocateRegistry.createRegistry(Registry.REGISTRY_PORT);
            System.out.println("bind tsdserver...");
            registry.rebind(SERVER_NAME, stub);
            System.out.println("...tsdserver bound");
        } catch (Exception e) {
            e.printStackTrace();
        }

	}

}
