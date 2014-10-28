package oink.nethaxe ;

import cpp.vm.Thread;
import haxe.io.Bytes;
import sys.net.Socket;
import sys.net.Host;

import pgr.dconsole.DC;

class Net {
	// default values
	public static var DEFAULT_SERVER_BIND_PORT:Int = 3000;
	public static var DEFAULT_SERVER_HOST:Host = new Host("localhost");
	
	public static var SERVER_BIND_PORT:Int;
	public static var SERVER_HOST:Host;
	
	public static var server:Server;
	public static var server_active:Bool;
	
	public static var client:Client;
	public static var client_active:Bool;
	
	public static var connected_sockets:Array<Socket>;
	
	private static var c:Socket;
	
	public function new() {
		
	}
	
	/**
	 * set some flags and register some other stuff with dconsole
	 */
	public static function init():Void {
		server_active = false;
		client_active = false;
		
		DC.registerFunction(create_server, "create_server");
		DC.registerFunction(create_client, "create_client");
		DC.registerFunction(server_status, "server_status");
		DC.registerFunction(client_status, "client_status");
	}
	
	/**
	 * create a server and bind it
	 * @param	Host hostname to bind to. ex, "localhost"
	 * @param	Port port # to bind to. ex, 3000
	 */
	public static function create_server(Host:Host = null, Port:Int = -1):Void {
		
		if (!server_active) {
			if (Host != null && Port > 0) {
				SERVER_HOST = Host;
				SERVER_BIND_PORT = Port;
				server = new Server(SERVER_HOST, SERVER_BIND_PORT);
			}
			else
				server = new Server(DEFAULT_SERVER_HOST, DEFAULT_SERVER_BIND_PORT);
		}
	}
	
	/**
	 * create a client. doesn't connect to anything yet
	 */
	public static function create_client():Void {
		if(!client_active) {
			client = new Client();
		}
	}
	
	
	private static function server_status():Void {
		if (server_active) {
			DC.log("server is active. listening on " + SERVER_HOST + " at port " + SERVER_BIND_PORT);
		} else {
			DC.log("server not active");
		}
	}
	
	
	private static function client_status():Void {
		if (client_active) {
			DC.log("client is active. connected to " + client.server_host.toString() + ":" + client.server_port);
		} else {
			DC.log("client not active");
		}
	}
}