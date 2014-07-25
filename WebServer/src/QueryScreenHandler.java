import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.eclipse.jetty.server.Request;
import org.eclipse.jetty.server.handler.AbstractHandler;


public class QueryScreenHandler extends AbstractHandler {

	@Override
	public void handle(String target, Request baseRequest, HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
		if(request.getRequestURI().equals("/QueryScreen.html")) {
			response.setContentType("text/html;charset=utf-8");
			response.setStatus(HttpServletResponse.SC_OK);
			baseRequest.setHandled(true);
			PrintWriter out = response.getWriter();
			
			out.println("<html>");
			
			out.println("<body>");
			out.println("<a href=\"timeseries.html?plotid=HEG01\">timeseries.html?plotid=HEG01</a><br>");
			
			out.println("<form name=\"input\" action=\"timeseries.html\" method=\"get\">");
			
			//out.println("PlotID: <input type=\"text\" name=\"plotid\">");
			out.println("PlotID: <select name=\"plotid\">");
			out.println("<option value=\"HEG01\">HEG01</option>");
			out.println("<option value=\"HEG02\">HEG02</option>");
			out.println("<option value=\"HEG03\">HEG03</option>");
			
			
			
			out.println("<input type=\"submit\" value=\"query\">");
			
			out.println("</form> ");
			
			out.println("</body>");
			
			out.println("</html>");
		}
		
	}

}
