package oink.nethaxe;

import cpp.vm.Thread;
import sys.net.Host;
import sys.net.Socket;
import pgr.dconsole.DC;

/**
 * Client.hx
 * Chat client program behaviour
 * @author YellowAfterlife
 */

class Client {
	
	// defaults
	private static inline var DEFAULT_HOSTNAME:String = '127.0.0.1';
	private static inline var DEFAULT_PORT:Int = 3000;
	
	var socket:Socket;
	
	public function new() {
		
		// server credentials
		// TODO: these should be specified during creation via parameters
		var ip = '127.0.0.1';
		var port = 3000;
		
		// attempt to connect
		DC.log('Connecting...\n');
		try {
			socket = new Socket();
			socket.connect(new Host(ip), port);
			DC.log('Connected to ' + ip + ':' + port + '\n');
		} catch (z:Dynamic) {
			DC.log('Could not connect to ' + ip + ':' + port + '\n');
			return;
		}
		
		// assign us a random name
		socket.output.writeString('/name User' + Std.int(Math.random() * 65536) + '\n');
		
		// create listening thread
		Thread.create(threadListen);
		
		
		// DC functions
		DC.registerFunction(onChatLine, "chat");
	}
	
	/** 
	 * Input handler 
	 **/
	function onChatLine(text:String):Bool {
		try {
			socket.write(text + '\n');
		} catch (z:Dynamic) {
			
			DC.log('Connection lost.\n');
			socket.output.writeString('Connection lost.\n');
			
			return false;
		}
		return true;
	}
	
	/** 
	 * Listener thread
	 **/
	function threadListen() {
		while (true) {
			try {
				var text = socket.input.readLine();
				DC.log(text + '\n');
				
			} catch (z:Dynamic) {
				DC.log('Connection lost.\n');
				socket.output.writeString('Connection lost.\n');
				return;
			}
		}
	}
	
	
}