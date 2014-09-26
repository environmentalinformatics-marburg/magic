package web;

import org.eclipse.jetty.server.Handler;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.server.handler.ContextHandler;
import org.eclipse.jetty.server.handler.ContextHandlerCollection;
import org.eclipse.jetty.server.handler.DefaultHandler;
import org.eclipse.jetty.server.handler.HandlerList;
import org.eclipse.jetty.server.handler.ResourceHandler;

import tsdb.TsDB;
import tsdb.TsDBFactory;
import tsdb.remote.RemoteTsDB;
import tsdb.remote.ServerTsDB;

public class Main {
	
	static {
		System.out.println("start");
	}

	public static void main(String[] args) throws Exception {
		
		//System.out.println(System.getenv().get("APP_HOME"));
		
		
		RemoteTsDB tsdb = new ServerTsDB(TsDBFactory.createDefault());
		
        Server server = new Server(8080);
        
        ContextHandler context = new ContextHandler("/");
        context.setContextPath("/");
        context.setHandler(new TestingHandler("Root Hello"));
 
        ContextHandler contextFR = new ContextHandler("/fr");
        contextFR.setHandler(new TestingHandler("Bonjoir"));
        
        ContextHandler contextStatic = new ContextHandler("/static");
        ResourceHandler resource_handler = new ResourceHandler();
        resource_handler.setDirectoriesListed(true);
        //resource_handler.setWelcomeFiles(new String[]{ "helllo.html" });
        resource_handler.setResourceBase("./static");
        HandlerList handlers = new HandlerList();
        handlers.setHandlers(new Handler[] {resource_handler, new DefaultHandler()});
        contextStatic.setHandler(handlers);
        
        ContextHandler contextTimeseries = new ContextHandler("/timeseries");
        TimeSeriesHandler timeSeriesHandler = new TimeSeriesHandler(tsdb);
        contextTimeseries.setHandler(timeSeriesHandler);
        
        ContextHandler contextTsdb = new ContextHandler("/tsdb");
        InfoHandler infoHandler = new InfoHandler(tsdb);
        contextTsdb.setHandler(infoHandler);
        
 
        ContextHandlerCollection contexts = new ContextHandlerCollection();
        contexts.setHandlers(new Handler[] {context, contextFR, contextStatic, contextTimeseries, contextTsdb});
 
        server.setHandler(contexts);
        
        
        server.start();
        //server.dumpStdErr();
        System.out.println("waiting for requests...");
        server.join();
        System.out.println("...end");
    }

}
