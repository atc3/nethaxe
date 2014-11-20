package oink.nethaxe;

import cpp.vm.Thread;
import sys.net.Host;
import sys.net.Socket;
import pgr.dconsole.DC;

/**
 * Client.hx
 * Chat client program behaviour
 */

class Client {	
	/**
	 * hostname of server to connect to
	 */ 
	var hostname:String;
	
	/**
	 * port of server to connect to
	 */
	var port:Int;
	
	/**
	 * host object of server to connect to
	 */
	var host:Host;

	/**
	 * socket to handle IO
	 */
	var socket:Socket;
	
	
	public function new(Hostname:String = '', Port:Int = 0) {
		
		// check defaults
		if (Hostname == '') Hostname = Net.DEFAULT_HOSTNAME;
		if (Port == 0) Port = Net.DEFAULT_PORT;
		
		// attempt to connect
		DC.log('Connecting...\n');
		try {
			socket = new Socket();
			
			host = new Host(Hostname);
			
			socket.connect(host, Port);
			DC.log('Connected to ' + Hostname + ':' + Port + '\n');
			
			hostname = Hostname;
			port = Port;
			
		} catch (z:Dynamic) {
			DC.log('Could not connect to ' + Hostname + ':' + Port + '\n');
			return;
		}
		
		// assign us a random name
		onChatLine('/name User' + Std.int(Math.random() * 65536) + '\n');
		
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
			socket.write("XP/CHAT" + "\n");
			socket.write(text + '\n');
		} catch (z:Dynamic) {
			
			DC.log('Connection lost.\n');
			
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
				return;
			}
		}
	}
	
	
}