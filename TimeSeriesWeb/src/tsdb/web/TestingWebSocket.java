package tsdb.web;

import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.File;

import javax.imageio.ImageIO;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.eclipse.jetty.server.Handler;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.server.handler.ContextHandler;
import org.eclipse.jetty.server.handler.ContextHandlerCollection;
import org.eclipse.jetty.server.handler.DefaultHandler;
import org.eclipse.jetty.server.handler.HandlerList;
import org.eclipse.jetty.server.handler.ResourceHandler;
import org.eclipse.jetty.server.session.HashSessionManager;
import org.eclipse.jetty.server.session.SessionHandler;
import org.eclipse.jetty.websocket.server.WebSocketHandler;
import org.eclipse.jetty.websocket.servlet.WebSocketServletFactory;

import tsdb.TsDBFactory;
import tsdb.remote.RemoteTsDB;
import tsdb.remote.ServerTsDB;
import tsdb.util.gui.TimeSeriesPainterGraphics2D;
import tsdb.web.api.TsDBAPIHandler;
import tsdb.web.api.TsDBExportAPIHandler;

public class TestingWebSocket {

	private static final int WEB_SERVER_PORT = 8080;
	private static final String WEB_SERVER_BASE_URL = "/static";
	
	private static final Logger log = LogManager.getLogger();

	public static void main(String[] args) throws Exception {
		RemoteTsDB tsdb = new ServerTsDB(TsDBFactory.createDefault());
		run(tsdb);
	}

	public static void run(RemoteTsDB tsdb) throws Exception {

		try{
			BufferedImage rainbow = ImageIO.read(new File(TsDBFactory.WEBCONTENT_PATH,"rainbow.png"));
			Color[] indexedColors = new Color[rainbow.getWidth()];
			for(int i=0;i<indexedColors.length;i++) {
				int c = rainbow.getRGB(i, 0);
				Color color = new Color(c);
				//System.out.println(c+"  "+color);
				indexedColors[i] = color;
			}
			TimeSeriesPainterGraphics2D.setIndexedColors(indexedColors);
		} catch(Exception e) {
			log.error(e);
		}



		Server server = new Server(WEB_SERVER_PORT);

		ContextHandler contextStatic = new ContextHandler(WEB_SERVER_BASE_URL);
		ResourceHandler resource_handler = new ResourceHandler();
		resource_handler.setDirectoriesListed(true);
		//resource_handler.setWelcomeFiles(new String[]{ "helllo.html" });
		resource_handler.setResourceBase(TsDBFactory.WEBCONTENT_PATH);
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
		
		ContextHandler contextEcho = new ContextHandler(); //"/echo"
		//contextEcho.setContextPath("/echo");
		WebSocketHandler wsHandler = new WebSocketHandler()	    {
	        @Override
	        public void configure(WebSocketServletFactory factory)
	        {
	            System.out.println("configure WebSocketServletFactory");
	        	factory.register(MyEchoSocket.class);
	        }
	    };
	    contextEcho.setHandler(wsHandler);

		

		ContextHandlerCollection contexts = new ContextHandlerCollection();
		contexts.setHandlers(new Handler[] {contextEcho, contextStatic, contextTsdb, contextExport});

		server.setHandler(contexts);


		server.start();
		//server.dumpStdErr();
		System.out.println();
		System.out.println();
		System.out.println("Web Sever started at ***   http://[HOSTNAME]:"+WEB_SERVER_PORT+WEB_SERVER_BASE_URL+"   ***");
		System.out.println();
		System.out.println("stop Web Server with 'Ctrl-C'");
		System.out.println("waiting for requests...");
		server.join();
		System.out.println("...Web Sever stopped");		
	}

}
