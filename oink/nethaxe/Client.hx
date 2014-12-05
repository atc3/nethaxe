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
	
	var listen_thread:Thread;
	
	var event_map:Map<String, Dynamic>;
	var callback_func:Dynamic;
	
	
	public function new(Hostname:String = '', Port:Int = 0) {
		
		trace('Creating Client...\n');
		
		// check defaults
		if (Hostname == '') Hostname = Net.DEFAULT_HOSTNAME;
		if (Port == 0) Port = Net.DEFAULT_PORT;
		
		socket = new Socket();	
		host = new Host(Hostname);
		
		// attempt to connect
		trace('Connecting...\n');
		

		try {
			socket.connect(host, Port);
		} catch (z:Dynamic) {
			trace('Could not connect to ' + Hostname + ':' + Port + '\n');
			return;
		}
		
		Net.client_active = true;
		trace('Connected to ' + Hostname + ':' + Port + '\n');
			
		hostname = Hostname;
		port = Port;
		
		// assign us a random name
		onChatLine('/name User' + Std.int(Math.random() * 65536) + '\n');
		
		// create listening thread
		listen_thread = Thread.create(threadListen);
		
		event_map = new Map<String, Dynamic>();
		
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
			
			trace('Connection lost.\n');
			
			return false;
		}
		return true;
	}
	
	public function ping() {
		try {
			trace("pinging server...");
			socket.write("XP/PING" + "\n");
		} catch (z:Dynamic) {
			trace("connection lost.\n");
		}
	}
	
	public function send_player_location(X:Float, Y:Float) {
		//trace("sending x:" + X + " y:" + Y);
		try {
			socket.write("XP/PLAYERLOC" + "\n");
			socket.output.writeFloat(X);
			socket.output.writeFloat(Y);
		} catch (e:Dynamic) {
			trace(e);
		}
	}
	
	/** 
	 * Listener thread
	 **/
	function threadListen() {
		var thread_message = "";
		while (thread_message != "client_finish") {
			thread_message = Thread.readMessage(false);
			
			var text;
			try {
				text = socket.input.readLine();
			} catch (z:Dynamic) {
				trace('Connection lost.\n');
				return;
			}
			var msg_type = Net.xp_protocol_check(text);
			if (msg_type != "") {
				switch(msg_type) {
					case "INFO":
						try {
							text = socket.input.readLine();
						} catch (z:Dynamic) {
							trace('Connection lost.\n');
							return;
						}
						trace('SERVERINFO > ' + text + '\n');
					case "PONG":
						//trace("server ponged");
						on_trigger("PONG", []);
					case "REMOTEPLAYERLOC":
						try {
							var client_name = socket.input.readLine();
							var remote_x = socket.input.readFloat();
							var remote_y = socket.input.readFloat();
						} catch (z:Dynamic) {
							trace('Connection lost.\n');
							return;
						}
					default:
						// default behavior
						trace("invalid XP type\n");
						trace("Message Type: " + msg_type);
				}
			}
		}
	}
	
	public function on(Event:String, Callback:Dynamic) {
		if (!Reflect.isFunction(Callback)) {
			trace("invalid on bind");
			return;
		}
		event_map.set(Event, Callback);
	}
	private function on_trigger(Event:String, Args:Array<Dynamic>) {
		callback_func = event_map.get(Event);
		if (!Reflect.isFunction(callback_func)) {
			trace("invalid on call");
			return;
		}
		Reflect.callMethod(Net.client, Reflect.field(Net.client, "callback_func"), Args);
		//callback_func(Args);
	}
	
	function destroy():Void {
		Net.client_active = false;
		
		listen_thread.sendMessage("client_finish");
		
		try {
			socket.shutdown(true, true);
			socket.close();
		} catch (e:Dynamic) {
			trace(e);
		}
			
	}
}