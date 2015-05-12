package tsdb.web.api;

import java.io.IOException;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.io.Writer;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;

import javax.management.RuntimeErrorException;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.eclipse.jetty.server.Request;
import org.eclipse.jetty.server.handler.AbstractHandler;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.Text;

import tsdb.TsDBFactory;
import tsdb.web.generator.Css;
import tsdb.web.generator.Html;
import tsdb.web.generator.Tag;

public class Vis_tsmHandler extends AbstractHandler {
	private static final Logger log = LogManager.getLogger();

	@Override
	public void handle(String target, Request baseRequest, HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
		baseRequest.setHandled(true);

		String page = (String) request.getParameter("page");
		if(page==null) {
			page="";
		}
		page = page.replace('.', '_');


		String vis_tsm_path = TsDBFactory.WEBFILES_PATH+"/vis_tsm";
		Path rootDirectory = Paths.get(vis_tsm_path,page);
		log.info(rootDirectory);

		response.setContentType("text/html;charset=utf-8");

		Html html = new Html();

		Css css = html.css;
		css.addLine("body", "background-color:#f6f6f6");
		css.addLine("table", "background-color:#dddddd");
		css.addLine("div.bg", "background-image:url(../content/timeseries_bg3.png)","background-position:top left","background-size:100%");
		css.addLine("h1", "text-align:center");

		Tag body = html.body;
		Tag divTop = body.addDiv();
		divTop.setClass("bg");
		Tag h1 = divTop.addTag("h1");
		h1.addLink("../vis_tsm", "Precomputed Exploratories Visualizations");

		int lastSlashIndex = page.lastIndexOf("/");
		if(lastSlashIndex>=0) {
			String parent = page.substring(0, lastSlashIndex);
			String current = page.substring(lastSlashIndex);			
			Tag h2 = divTop.addTag("h2");
			h2.addLink("../vis_tsm?page="+parent, parent);
			h2.addText(current);
		} else {			
			divTop.addTag("h2",page);
		}

		try {
			DirectoryStream<Path> ds = Files.newDirectoryStream(rootDirectory);
			ArrayList<Path> directorylist = new ArrayList<Path>();
			ArrayList<Path> fileList = new ArrayList<Path>();

			for(Path subPath:ds) {

				if(Files.isDirectory(subPath)) {
					directorylist.add(subPath);
				} else {
					fileList.add(subPath);
				}


			}

			directorylist.sort(null);


			Tag divDirectories = body.addTag("div");			
			for(Path subPath:directorylist) { // directories
				//Tag tr = dtable.addTag("tr");
				String name = subPath.getFileName().toString();
				String subPage = page;
				if(!subPage.isEmpty()) {
					subPage += '/';
				}
				subPage += name;
				divDirectories.addLink("../vis_tsm?page="+subPage).addTag("b", name);
				divDirectories.addText(" . . . ");
			}

			body.addTag("hr");


			fileList.sort(null);
			Tag table = body.addTag("table");
			for(Path subPath:fileList) { // files
				Tag tr = table.addTag("tr");
				String name = subPath.getFileName().toString();
				String subPage = page;
				if(!subPage.isEmpty()) {
					subPage += '/';
				}
				subPage += name;
				String fileText = name;
				if(fileText.endsWith(".png")) {
					fileText = fileText.substring(0, fileText.length()-4);
				} else if(fileText.endsWith(".html")) {
					fileText = fileText.substring(0, fileText.length()-5);
				}
				tr.addTag("td").addLink("../files/vis_tsm/"+subPage, fileText);

			}


			
		} catch (Exception e) {
			log.error(e);
		}

		html.write(response.getWriter());
	}

}
