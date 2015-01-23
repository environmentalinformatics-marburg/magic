package tsdb.web;

import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.atomic.LongAdder;

import javax.imageio.ImageIO;
import javax.servlet.ServletException;
import javax.servlet.SessionTrackingMode;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.eclipse.jetty.http.HttpHeader;
import org.eclipse.jetty.server.ConnectionFactory;
import org.eclipse.jetty.server.Connector;
import org.eclipse.jetty.server.Handler;
import org.eclipse.jetty.server.HttpConfiguration;
import org.eclipse.jetty.server.HttpConfiguration.Customizer;
import org.eclipse.jetty.server.HttpConnectionFactory;
import org.eclipse.jetty.server.Request;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.server.ServerConnector;
import org.eclipse.jetty.server.handler.AbstractHandler;
import org.eclipse.jetty.server.handler.ContextHandler;
import org.eclipse.jetty.server.handler.ContextHandlerCollection;
import org.eclipse.jetty.server.handler.DefaultHandler;
import org.eclipse.jetty.server.handler.HandlerList;
import org.eclipse.jetty.server.handler.ResourceHandler;
import org.eclipse.jetty.server.session.HashSessionManager;
import org.eclipse.jetty.server.session.SessionHandler;
import org.eclipse.jetty.servlet.ServletContextHandler;
import org.eclipse.jetty.util.SharedBlockingCallback;
import org.eclipse.jetty.util.URIUtil;

import tsdb.TsDBFactory;
import tsdb.remote.RemoteTsDB;
import tsdb.remote.ServerTsDB;
import tsdb.util.gui.TimeSeriesPainterGraphics2D;
import tsdb.web.api.TsDBAPIHandler;
import tsdb.web.api.TsDBExportAPIHandler;

public class Main {
	
	private static final long GENERAL_TIMEOUT_MILLISECONDS = 2*60*60*1000; // set timeout to 2 hours
	
	private static final long FILE_DOWNLOAD_TIMEOUT_MILLISECONDS = 2*60*60*1000; // set timeout to 2 hours
	private static final long TSDB_API_TIMEOUT_MILLISECONDS = 5*60*1000; // set timeout to 5 minutes
	private static final long EXPORT_API_TIMEOUT_MILLISECONDS = 2*60*60*1000; // set timeout to 2 hours
	private static final int EXPORT_API_SESSION_TIMEOUT_SECONDS = 2*60*60; // set timeout to 2 hours

	private static final int WEB_SERVER_PORT = 8080;

	private static final String WEBCONTENT_PART_URL = "/content";
	private static final String TSDB_API_PART_URL = "/tsdb";
	private static final String EXPORT_API_PART_URL = "/export";
	private static final String DOWNLOAD_PART_URL = "/download";

	private static final Logger log = LogManager.getLogger();

	public static void main(String[] args) throws Exception {
		RemoteTsDB tsdb = new ServerTsDB(TsDBFactory.createDefault());
		run(tsdb);
	}

	public static void run(RemoteTsDB tsdb) throws Exception {

		createRainbowScale();

		Server server = new Server(WEB_SERVER_PORT);

		for(Connector y : server.getConnectors()) {
			for(ConnectionFactory x  : y.getConnectionFactories()) {
				if(x instanceof HttpConnectionFactory) {
					HttpConfiguration httpConfiguration = ((HttpConnectionFactory)x).getHttpConfiguration();
					httpConfiguration.setSendServerVersion(false);
					httpConfiguration.setSendDateHeader(false);
					httpConfiguration.setSendXPoweredBy(false);
					Customizer customizer = new Customizer() {
						
						@Override
						public void customize(Connector connector, HttpConfiguration channelConfig, Request request) {
							System.out.println(connector.getClass()+"   idle timeout "+connector.getIdleTimeout());
							ServerConnector sc = (ServerConnector) connector;
							sc.setIdleTimeout(GENERAL_TIMEOUT_MILLISECONDS); //TODO set earlier !!!
							System.out.println(connector.getClass()+"   idle timeout "+connector.getIdleTimeout());
							
							
						}
					};
					httpConfiguration.addCustomizer(customizer);
				}
			}
		}

		

		ContextHandler contextRedirect = new ContextHandler(TsDBFactory.WEB_SERVER_PREFIX_BASE_URL);
		contextRedirect.setHandler(new BaseRedirector(TsDBFactory.WEB_SERVER_PREFIX_BASE_URL+WEBCONTENT_PART_URL));
		
		//ServletContextHandler x = new ServletContextHandler();		
		//x.addFilter(holder, pathSpec, dispatches);
		//x.addServlet(RobotsTxtServlet.SERVLET_HOLDER, "/robots.txt");
		//x.addServlet(InvalidUrlServlet.SERVLET_HOLDER, "/*");

		ContextHandler[] contexts = new ContextHandler[] {
				createContextWebcontent(), 
				createContextTsDB(tsdb), 
				createContextExport(tsdb), 
				createContextWebDownload(),
				contextRedirect,
				Robots_txt_Handler.CONTEXT_HANDLER,
				//x,
				createContextInvalidURL()
		};

		ContextHandlerCollection contextCollection = new ContextHandlerCollection();
		contextCollection.setStopTimeout(GENERAL_TIMEOUT_MILLISECONDS);
		contextCollection.setHandlers(contexts);
		server.setHandler(contextCollection);
		server.setStopTimeout(GENERAL_TIMEOUT_MILLISECONDS);
		
		//SharedBlockingCallback

		server.start();
		//server.dumpStdErr();
		System.out.println();
		System.out.println();
		System.out.println("Web Sever started at    ***      http://[HOSTNAME]:"+WEB_SERVER_PORT+TsDBFactory.WEB_SERVER_PREFIX_BASE_URL+"      ***");
		System.out.println();
		System.out.println("stop Web Server with 'Ctrl-C'");
		System.out.println();
		System.out.println("waiting for requests...");
		server.join();
		System.out.println("...Web Sever stopped");		
	}

	private static ContextHandler createContextWebcontent() {
		ContextHandler contextStatic = new ContextHandler(TsDBFactory.WEB_SERVER_PREFIX_BASE_URL+WEBCONTENT_PART_URL);
		contextStatic.setStopTimeout(GENERAL_TIMEOUT_MILLISECONDS);
		ResourceHandler resource_handler = new ResourceHandler();
		resource_handler.setStopTimeout(FILE_DOWNLOAD_TIMEOUT_MILLISECONDS);
		resource_handler.setMinAsyncContentLength(-1); //no async
		resource_handler.setMinMemoryMappedContentLength(-1); // not memory mapped
		//resource_handler.setDirectoriesListed(true);
		resource_handler.setDirectoriesListed(false); // don't show directory content
		//resource_handler.setWelcomeFiles(new String[]{ "helllo.html" });
		resource_handler.setResourceBase(TsDBFactory.WEBCONTENT_PATH);
		HandlerList handlers = new HandlerList();
		handlers.setStopTimeout(GENERAL_TIMEOUT_MILLISECONDS);
		handlers.setHandlers(new Handler[] {resource_handler, /*new DefaultHandler()*/ new InvalidUrlHandler("content not found")});
		contextStatic.setHandler(handlers);
		return contextStatic;		
	}

	private static ContextHandler createContextTsDB(RemoteTsDB tsdb) {
		ContextHandler contextTsdb = new ContextHandler(TsDBFactory.WEB_SERVER_PREFIX_BASE_URL+TSDB_API_PART_URL);
		TsDBAPIHandler handler = new TsDBAPIHandler(tsdb);
		handler.setStopTimeout(TSDB_API_TIMEOUT_MILLISECONDS);
		contextTsdb.setHandler(handler);
		return contextTsdb;
	}


	private static ContextHandler createContextExport(RemoteTsDB tsdb) {
		ContextHandler contextExport = new ContextHandler(TsDBFactory.WEB_SERVER_PREFIX_BASE_URL+EXPORT_API_PART_URL);
		TsDBExportAPIHandler exportHandler = new TsDBExportAPIHandler(tsdb);
		exportHandler.setStopTimeout(EXPORT_API_TIMEOUT_MILLISECONDS);
		HashSessionManager manager = new HashSessionManager();


		manager.setMaxInactiveInterval(EXPORT_API_SESSION_TIMEOUT_SECONDS);
		SessionHandler sessions = new SessionHandler(manager);
		contextExport.setHandler(sessions);
		sessions.setHandler(exportHandler);
		return contextExport;
	}


	private static ContextHandler createContextWebDownload() {
		ContextHandler contextHandler = new ContextHandler(TsDBFactory.WEB_SERVER_PREFIX_BASE_URL+DOWNLOAD_PART_URL);
		ResourceHandler resourceHandler = new ResourceHandler();
		resourceHandler.setStopTimeout(FILE_DOWNLOAD_TIMEOUT_MILLISECONDS);
		resourceHandler.setMinAsyncContentLength(-1); //no async
		//resourceHandler.setDirectoriesListed(true);
		resourceHandler.setDirectoriesListed(false); // don't show directory content
		resourceHandler.setResourceBase(TsDBFactory.WEBDOWNLOAD_PATH);
		HandlerList handlers = new HandlerList();
		handlers.setHandlers(new Handler[] {resourceHandler, new DefaultHandler()});
		contextHandler.setHandler(handlers);
		return contextHandler;
	}

	private static ContextHandler createContextInvalidURL() {
		ContextHandler contextInvalidURL = new ContextHandler();
		Handler handler = new InvalidUrlHandler("page not found");
		contextInvalidURL.setHandler(handler);
		return contextInvalidURL;
	}

	private static void createRainbowScale() {
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
	}
}
