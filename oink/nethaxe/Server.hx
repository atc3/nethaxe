package oink.nethaxe;

import cpp.vm.Thread;
import sys.net.Host;
import sys.net.Socket;

import pgr.dconsole.DC;

class Server {
	
	/**
	 * max number of clients this server will handle before it starts to reject new connection requests.
	 */
	public static inline var MAX_CONNECTIONS:Int = 10;
	
	var socket:Socket;
	var c:Socket;
	var connected_sockets:Array<Socket>;
	
	var listen_thread:Thread;

	public function new(Host:Host, Port:Int) {
		DC.log("creating server...");
		
		socket = new Socket();
		connected_sockets = new Array<Socket>();
		
		if (!bind_server(Host, Port)) {
			Net.server_active = false;
			return;
		};
		
		listen_thread = Thread.create(thread_listen);
		
		DC.registerFunction(this.list_clients, "list_clients");
		
		Net.server_active = true;
	}
	
	/**
	 * binds the server to the given host & port
	 * can only bind one server per port
	 * @param	Host hostname, ex. "127.0.0.1"
	 * @param	Port port #, ex. 3000
	 * @return true if bind is successful, false if bind has failed
	 */
	public function bind_server(Host:Host, Port:Int):Bool {
		DC.log("binding server...");
		try {
			socket.bind(Host, Port);
			DC.log("server bound to " + Host.toString());
			socket.listen(MAX_CONNECTIONS);
			DC.log("server listening on port " + Port);
			
			return true;
		} catch (z:Dynamic) {
			DC.log("error binding server. maybe something is already bound to " + Host.toString() + ":" + Port + "?");
			
			return false;
		}
	}
	
	/**
	 * the server thread that listens for feedback
	 */
	private function thread_listen():Void {
		
		var threadMessage:String = "";
		while (threadMessage != "finish") {
			threadMessage = Thread.readMessage(false);
			
			accept_clients();
		}
		
		DC.log("closing server...");
		socket.close();
		DC.log("server closed.");
		
		return;
	}
	
	/**
	 * accept incoming connection requests as they come in
	 * if a client is accepted, add them to the pool so they get updates and such
	 */
	private function accept_clients():Void {
		c = socket.accept();
		if (c != null) {
			DC.log("client connected!");
			DC.log("client info: " + c.peer());
			
			//push to array of connected sockets
			connected_sockets.push(c);
			//reset to null
			c = null;
		}
	}
	
	/**
	 * list all clients currently connected to the server
	 */
	private function list_clients():Void {
		if (connected_sockets.length <= 0) {
			DC.log("no clients connected");
		} else {
			for (s in connected_sockets) {
				DC.log(s.peer());
			}
		}
	}
	
	/**
	 * clean up
	 */
	public function destroy():Void {
		DC.log("destroying server...");
		this.socket.close();
		
		for (s in connected_sockets) {
			s.close();
		}
		
		listen_thread.sendMessage("finish");
		
		Net.server_active = false;
	}
}