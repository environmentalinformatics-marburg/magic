package tsdb.web.api;

import java.io.IOException;
import java.io.PrintWriter;
import java.io.StringWriter;
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

import tsdb.TsDBFactory;

public class Vis_tsmHandler extends AbstractHandler {

	private static class Css {
		public final Tag tag;
		public Css(Tag tag) {
			this.tag = tag;
			tag.setAttribute("type", "text/css");
		}
		public void addLine(String text) {
			tag.element.setTextContent(tag.element.getTextContent()+text+"\n");
		}
	}

	private static class Tag {
		public final Element element;
		public Tag(Element element) {
			this.element = element;
		}
		public Tag addTag(String tagName) {
			Element subElement = element.getOwnerDocument().createElement(tagName);
			element.appendChild(subElement);
			return new Tag(subElement);
		}
		public void setAttribute(String attributeName, String attributeValue) {
			element.setAttribute(attributeName, attributeValue);
		}
		public void setClass(String className) {
			element.setAttribute("class", className);
		}
		public Tag addDiv() {
			return addTag("div");
		}
	}

	private static class Html {
		public final Document document;
		public final Tag html;
		public final Tag head;
		public final Css css;
		public final Tag body;
		public Html() {
			try {
				document = DocumentBuilderFactory.newInstance().newDocumentBuilder().newDocument();
				Element htmlElement = document.createElement("HTML");
				document.appendChild(htmlElement);
				this.html = new Tag(htmlElement);
				this.head = html.addTag("head");
				this.css = new Css(head.addTag("style"));

				this.body = html.addTag("body");
			} catch(Exception e) {
				throw new RuntimeException(e);
			}
		}
	}



	private static final Logger log = LogManager.getLogger();

	@Override
	public void handle(String target, Request baseRequest, HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
		baseRequest.setHandled(true);

		//**********************************************************

		/*Html html = new Html();
		
		Css css = html.css;
		css.addLine("body {background-color:#f6f6f6;}");
		css.addLine("table {background-color:#dddddd;}");
		css.addLine("div.bg {background-image: url(../content/timeseries_bg3.png);background-position: top left;background-size: 100%;}");
		css.addLine("h1 {text-align: center;}");
		
		Tag body = html.body;
		Tag divTop = body.addDiv();
		divTop.setClass("bg");
		Tag h1 = divTop.addTag("h1");
		Tag link = h1.addTag("a");
		link.setAttribute("href", "../vis_tsm");
		link.element.setTextContent("Precomputed Exploratories Visualizations");



		try {
			//set up a transformer
			TransformerFactory transfac = TransformerFactory.newInstance();
			Transformer trans;

			trans = transfac.newTransformer();

			trans.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "yes");
			trans.setOutputProperty(OutputKeys.INDENT, "yes");

			//create string from xml tree
			StringWriter sw = new StringWriter();
			StreamResult result = new StreamResult(response.getWriter());
			DOMSource source = new DOMSource(html.document);

			trans.transform(source, result);
			String xmlString = sw.toString();

			log.info(xmlString);

			return;
		} catch (Exception e) {
			log.error(e);
		}*/


		//**********************************************************

		String page = (String) request.getParameter("page");
		if(page==null) {
			page="";
		}
		page = page.replace('.', '_');


		String vis_tsm_path = TsDBFactory.WEBFILES_PATH+"/vis_tsm";
		Path rootDirectory = Paths.get(vis_tsm_path,page);
		log.info(rootDirectory);

		response.setContentType("text/html;charset=utf-8");
		PrintWriter out = response.getWriter();
		out.println("<html><head>");
		out.println("<style type=\"text/css\">");
		out.println("body {background-color:#f6f6f6;}");
		out.println("table {background-color:#dddddd;}");
		out.println("div.bg {background-image: url(../content/timeseries_bg3.png);background-position: top left;background-size: 100%;}");
		out.println("h1 {text-align: center;}");
		out.println("</style>");
		out.println("</head><body>");

		out.println("<div class=\"bg\">");

		out.println("<h1>");
		out.println("<a href=\""+"../vis_tsm\">"+"Precomputed Exploratories Visualizations"+"</a>");
		out.println("</h1>");

		int lastSlashIndex = page.lastIndexOf("/");
		if(lastSlashIndex>=0) {
			String parent = page.substring(0, lastSlashIndex);
			String current = page.substring(lastSlashIndex);
			out.println("<h2><a href=\""+"../vis_tsm?page="+parent+"\">"+parent+"</a>");
			out.println(current+"</h2>");
		} else {		
			out.println("<h2>"+page+"</h2>");
		}

		out.println("</div>");

		out.println("<table>");
		try {
			DirectoryStream<Path> ds = Files.newDirectoryStream(rootDirectory);
			ArrayList<Path> list = new ArrayList<Path>();

			for(Path subPath:ds) {
				list.add(subPath);
			}

			list.sort(null);			

			for(Path subPath:list) {
				out.println("<tr>");
				String name = subPath.getFileName().toString();
				String subPage = page;
				if(!subPage.isEmpty()) {
					subPage += '/';
				}
				subPage += name;
				if(Files.isDirectory(subPath)) {
					//log.info("read directory "+subPath);
					out.println("<td><a href=\""+"../vis_tsm?page="+subPage+"\">"+name+"</a></td>");
					out.println("<td>"+"(subpage)"+"</td>");
				} else {
					//log.info("read file "+subPath);
					//out.println("<td>"+"file"+"</td>");
					//out.println("<td>"+""+"</td>");
					String fileText = name;
					if(fileText.endsWith(".png")) {
						fileText = fileText.substring(0, fileText.length()-4);
					}
					out.println("<td><a href=\""+"../files/vis_tsm/"+subPage+"\">"+fileText+"</a></td>");
				}
				out.println("</tr>");
			}
		} catch (Exception e) {
			log.error(e);
		}
		out.println("</table>");


		out.println("</body></html>");
		out.close();
	}

}
