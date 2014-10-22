package net;

import sys.net.Host;
import sys.net.Socket;
import cpp.vm.Thread;

import pgr.dconsole.DC;

class Client {

	public var socket:Socket;
	
	public var listen_thread:Thread;
	
	public var connected:Bool;
	
	public var server_host:Host;
	public var server_port:Int;
	
	public var host:Host;
	public var port:Int;
	
	public function new() {
		DC.log("creating client...");
		socket = new Socket();
		socket.setFastSend(true);
		
		listen_thread = Thread.create(thread_listen);
	}
	
	public function connect(Host:Host, Port:Int):Void {
		
		// terminate any existing connection
		if (connected) {
			DC.log("disconnecting client...");
			socket.close();
			connected = false;
			DC.log("disconnected client from " + socket.peer);
		}
		
		DC.log("connecting client...");
		try {
			socket.connect(Host, Port);
			connected = true;
			DC.log('Connected to ' + Host.toString() + ':' + Port);
			
			server_host = Host;
			server_port = Port;
			
			Net.client_active = true;
		} catch (z:Dynamic) {
			DC.log('Could not connect to ' + Host.toString() + ':' + Port);
			
			Net.client_active = false;
			return;
		}
		
		// send handshake
	}
	
	private function thread_listen():Void {
		
		var threadMessage:String = "";
		
		while (threadMessage != "finish") {
			threadMessage = Thread.readMessage(false);
			
			// catch server output
			
			Sys.sleep(0.001);
		}
		
		// clean up
		DC.log("closing client...");
		socket.close();
		DC.log("client closed");
		return;
	}
	
	public function destroy():Void {
		DC.log("destroying client...");
		listen_thread.sendMessage("finish");
		socket.close();
		
		Net.client_active = false;
	}
}