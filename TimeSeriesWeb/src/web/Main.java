package web;

import java.util.concurrent.atomic.LongAdder;

import org.eclipse.jetty.server.Handler;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.server.handler.ContextHandler;
import org.eclipse.jetty.server.handler.ContextHandlerCollection;
import org.eclipse.jetty.server.handler.DefaultHandler;
import org.eclipse.jetty.server.handler.HandlerList;
import org.eclipse.jetty.server.handler.ResourceHandler;
import org.eclipse.jetty.server.session.HashSessionManager;
import org.eclipse.jetty.server.session.SessionHandler;

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
        
        ContextHandler contextStatic = new ContextHandler("/static");
        ResourceHandler resource_handler = new ResourceHandler();
        resource_handler.setDirectoriesListed(true);
        //resource_handler.setWelcomeFiles(new String[]{ "helllo.html" });
        resource_handler.setResourceBase("./static");
        HandlerList handlers = new HandlerList();
        handlers.setHandlers(new Handler[] {resource_handler, new DefaultHandler()});
        contextStatic.setHandler(handlers);
        
        ContextHandler contextTsdb = new ContextHandler("/tsdb");
        TsDBAPIHandler infoHandler = new TsDBAPIHandler(tsdb);
        contextTsdb.setHandler(infoHandler);
        
        ContextHandler contextExport = new ContextHandler("/export");
        TsDBExportAPIHandler exportHandler = new TsDBExportAPIHandler(tsdb);
        HashSessionManager manager = new HashSessionManager();
                
        manager.setMaxInactiveInterval(60*60);
        SessionHandler sessions = new SessionHandler(manager);
        contextExport.setHandler(sessions);
        sessions.setHandler(exportHandler);
        new LongAdder();
 
        ContextHandlerCollection contexts = new ContextHandlerCollection();
        contexts.setHandlers(new Handler[] {contextStatic, contextTsdb, contextExport});
 
        server.setHandler(contexts);
                
        
        
        
        server.start();
        //server.dumpStdErr();
        System.out.println("waiting for requests...");
        server.join();
        System.out.println("...end");
    }

}
