package tsdb.web;

import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.File;
import java.util.concurrent.atomic.LongAdder;

import javax.imageio.ImageIO;

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
import tsdb.web.api.TsDBAPIHandler;
import tsdb.web.api.TsDBExportAPIHandler;

public class Main {

	static {
		System.out.println("start");
	}

	public static void main(String[] args) throws Exception {

		//System.out.println(System.getenv().get("APP_HOME"));


		RemoteTsDB tsdb = new ServerTsDB(TsDBFactory.createDefault());

		if(args.length==1) {
			run(tsdb,args[0]);
		} else {
			run(tsdb,null);
		}

	}

	public static void run(RemoteTsDB tsdb, String base_url) throws Exception {

		if(base_url==null) {
			base_url = "/static";
		}

		try{
			BufferedImage rainbow = ImageIO.read(new File("static/rainbow.png"));
			Color[] indexedColors = new Color[rainbow.getWidth()];
			for(int i=0;i<indexedColors.length;i++) {
				int c = rainbow.getRGB(i, 0);
				Color color = new Color(c);
				//System.out.println(c+"  "+color);
				indexedColors[i] = color;
			}
			TimeSeriesPainterGraphics2D.setIndexedColors(indexedColors);
		} catch(Exception e) {
			e.printStackTrace();
		}



		Server server = new Server(8080);

		ContextHandler contextStatic = new ContextHandler(base_url);
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
