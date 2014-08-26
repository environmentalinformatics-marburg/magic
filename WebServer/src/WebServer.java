import java.net.MalformedURLException;
import java.rmi.AlreadyBoundException;
import java.rmi.RemoteException;
import java.rmi.registry.LocateRegistry;
import java.rmi.registry.Registry;

import org.eclipse.jetty.server.Handler;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.server.handler.DefaultHandler;
import org.eclipse.jetty.server.handler.HandlerList;
import org.eclipse.jetty.server.handler.ResourceHandler;

import tsdb.server.StartServer;
import tsdb.server.TSDServerInterface;


public class WebServer {
	
	public static void main(String[] args) throws Exception {		
		WebServer webserver = new WebServer();
		webserver.run(10342);
		
		
		
	}
	
	/*public void runAsync_timeseriesdatabase_server() {
		new Thread(){
			@Override
			public void run() {
				try {
					StartServer.main(null);
				} catch (RemoteException | MalformedURLException | AlreadyBoundException e) {
					e.printStackTrace();
				}
			}}.start();
	}*/
	
	public void run(int port) throws Exception {
		
		//runAsync_timeseriesdatabase_server();
		
		System.out.println("start WebServer...");
		Server server = new Server(port);
		
		System.out.println("start ResourceHandler...");
		ResourceHandler resource_handler_visual = new ResourceHandler();
		resource_handler_visual.setDirectoriesListed(true);
		resource_handler_visual.setWelcomeFiles(new String[] { "index.html" });
		resource_handler_visual.setResourceBase("C:/git_magic/timeseries_visualisation/");
		
		ResourceHandler resource_handler_timeseriesdatabase_output = new ResourceHandler();
		resource_handler_timeseriesdatabase_output.setDirectoriesListed(true);
		resource_handler_timeseriesdatabase_output.setWelcomeFiles(new String[] { "index.html" });
		resource_handler_timeseriesdatabase_output.setResourceBase("c:/timeseriesdatabase_output/");
		
		System.out.println("start TSDServerInterface...");
		 Registry registry = LocateRegistry.getRegistry("localhost");
         TSDServerInterface stub1 = (TSDServerInterface) registry.lookup(StartServer.SERVER_NAME);
         TSDServerInterface stub2 = (TSDServerInterface) registry.lookup(StartServer.SERVER_NAME);
		
         QueryScreenHandler queryScreenHandler = new QueryScreenHandler();
         QueryHandler queryHandler = new QueryHandler(stub1);
         TestingHandler testingHandler = new TestingHandler(stub2);
		
		HandlerList handlers = new HandlerList();
		handlers.setHandlers(new Handler[] {queryScreenHandler, queryHandler, resource_handler_visual, resource_handler_timeseriesdatabase_output, testingHandler, new DefaultHandler() });
		server.setHandler(handlers);
		server.start();
		System.out.println("WebServer started at port: " + port);		
		server.join();
	}

}
