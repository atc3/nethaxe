package oink.nethaxe;

import cpp.vm.Thread;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import org.bsonspec.BSON;
import org.bsonspec.ObjectID;
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
	
	public var id:Int;
	
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
		id = Std.int(Math.random() * 65536);
		onChatLine('/name User' + id + '\n');
		
		listen_thread = Thread.create(threadListen);
		
		event_map = new Map<String, Dynamic>();
		
		// DC functions
		DC.registerFunction(onChatLine, "chat");
		
		// basic on functions
		on("INFO", on_info);
		on("PONG", on_pong);
	}
	
	/** 
	 * Listener thread
	 **/
	function threadListen() {
		var thread_message = "";
		while (thread_message != "client_finish") {
			thread_message = Thread.readMessage(false);
			
			var packet = BSON.decode(socket.input);
			trace(packet);
			
			// skip empty packet
			if(Reflect.fields(packet).length <= 0)
				continue;
			
			var action = packet.action;
			
			if (event_map.exists(action)) {
				on_trigger(action, [packet]);
			} else {
				trace("invalid XP type\n");
				trace("Message Type: " + action + "\n");
				trace(packet);
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
	
	/** 
	 * Input handler 
	 **/
	function onChatLine(text:String):Bool {
		
		var chat_packet = BSON.encode({
			_id: new ObjectID()
			, action: "CHAT"
			, text: text
		});
		
		try {
			socket.output.write(chat_packet);
		} catch (z:Dynamic) {
			trace('Connection lost.\n');
			return false;
		}
		return true;
	}
	
	public function ping() {
		
		var ping_packet = BSON.encode({
			_id: new ObjectID()
			, action: "PING"
		});
		
		try {
			trace("pinging server...");
			socket.output.write(ping_packet);
		} catch (z:Dynamic) {
			trace("connection lost.\n");
		}
	}
	
	public function send_player_location(X:Float, Y:Float) {
		
		var location_packet = BSON.encode({
			_id: new ObjectID()
			, action: "REMOTEPLAYERLOC"
			, client_id: this.id
			, x: X
			, y: Y
		});
		
		try {
			socket.output.write(location_packet);
		} catch (z:Dynamic) {
			trace("connection lost.\n");
		}
	}
	
	function on_info(packet) {
		if (!Reflect.hasField(packet, "text")) return;
		
		trace("INFO>" + packet.text + "\n");
	}
	function on_pong() {
		trace("pong\n");
	}
	
}