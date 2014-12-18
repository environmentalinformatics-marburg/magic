package tsdb.web;

import org.eclipse.jetty.websocket.api.Session;
import org.eclipse.jetty.websocket.api.WebSocketListener;


public class MyEchoSocket implements WebSocketListener {
	
	public MyEchoSocket() {
		System.out.println("create MyEchoSocket");
	}

	@Override
	public void onWebSocketBinary(byte[] payload, int offset, int len) {
		System.out.println("onWebSocketBinary");
		
	}

	@Override
	public void onWebSocketClose(int statusCode, String reason) {
		System.out.println("onWebSocketClose");
		
	}

	@Override
	public void onWebSocketConnect(Session session) {
		System.out.println("onWebSocketConnect: "+session.getUpgradeRequest().getRequestURI());
		
	}

	@Override
	public void onWebSocketError(Throwable cause) {
		System.out.println("onWebSocketError");
		
	}

	@Override
	public void onWebSocketText(String message) {
		System.out.println("onWebSocketText: "+message);
		
	}
}
