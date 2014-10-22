package net ;

import cpp.vm.Thread;
import haxe.io.Bytes;
import sys.net.Socket;
import sys.net.Host;

import pgr.dconsole.DC;

class Net {
	public static var MAX_SOCKETS:Int = 10;
	public static var SERVER_BIND_PORT:Int = 3000;
	public static var SERVER_HOST:String = "localhost";
	
	public static var server:Server;
	public static var server_active:Bool;
	
	public static var client:Client;
	public static var client_active:Bool;
	
	public static var connected_sockets:Array<Socket>;
	
	private static var c:Socket;
	
	public function new() {
		
	}
	
	public static function init():Void {
		server_active = false;
		client_active = false;
		
		DC.registerFunction(server_status, "server_status");
		DC.registerFunction(client_status, "client_status");
	}
	
	public static function create_server():Void {
		if (!server_active) {
			server = new Server(new Host(SERVER_HOST), SERVER_BIND_PORT);
		}
	}
	
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