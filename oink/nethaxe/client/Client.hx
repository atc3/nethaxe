package oink.nethaxe.client ;

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
 * Based off of yellowafterlife's chat client
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
		
		trace('Creating Client...');
		socket = new Socket();
		
		connect(Hostname, Port);
		
		event_map = new Map<String, Dynamic>();
		listen_thread = Thread.create(threadListen);		
	}
	
	/**
	 * connect to the given hostname and port
	 * @param	Hostname
	 * @param	Port
	 * @return true if successful, false if fail
	 */
	public function connect(Hostname:String = '', Port:Int = 0):Bool {
		
		// disconnect first if necessary
		if (Net.client_active) {
			if (!disconnect()) return false;
		}
		
		// check defaults
		if (Hostname == '') Hostname = Net.DEFAULT_HOSTNAME;
		if (Port == 0) Port = Net.DEFAULT_PORT;
		
		host = new Host(Hostname);
		
		// attempt to connect
		trace('Connecting...');
		try {
			socket.connect(host, Port);
		} catch (z:Dynamic) {
			trace('Could not connect to ' + Hostname + ':' + Port);
			return false;
		}
		
		Net.client_active = true;
		trace('Connected to ' + Hostname + ':' + Port);
		hostname = Hostname;
		port = Port;
		
		return true;
	}
	
	/**
	 * disconnect from current server
	 * @return true if success, false if fail
	 */
	public function disconnect():Bool {
		try {
			socket.shutdown(true, true);
			socket.close();
		} catch (e:Dynamic) {
			trace('Could not disconnect from ' + hostname + ':' + port);
			return false;
		}
		Net.client_active = false;
		return true;
	}
	
	/** 
	 * Listener thread
	 * handles input from server and calls on functions
	 **/
	function threadListen() {
		var thread_message = "";
		while (thread_message != "client_finish") {
			thread_message = Thread.readMessage(false);
			
			var packet = BSON.decode(socket.input);
			
			
			// skip empty packet
			if (Reflect.fields(packet).length <= 0)
				continue;
				
			trace(packet);
			
			var action = packet.action;
			
			if (event_map.exists(action)) {
				on_trigger(action, [packet]);
			} else {
				trace("invalid XP type");
				trace("Message Type: " + action);
				trace(packet);
			}
		}
	}
	
	/**
	 * register/map an on function
	 * @param	Event name of the function/event
	 * @param	Callback function to call. packet is automatically 
	 * passed as the first variable to the callback function
	 * @return true if success, false if fail
	 */
	public function on(Event:String, Callback:Dynamic):Bool {
		if (!Reflect.isFunction(Callback)) {
			trace("callback is not a function");
			return false;
		}
		
		// remove existing mapping if it exists
		if (event_map.exists(Event)) event_map.remove(Event);
		
		event_map.set(Event, Callback);
		
		return true;
	}
	
	/**
	 * internal helper
	 * trigger an on function
	 * @param	Event event to trigger
	 * @param	Args args passed
	 * @return true if success, false if fail
	 */
	private function on_trigger(Event:String, Args:Array<Dynamic>):Bool {
		callback_func = event_map.get(Event);
		if (!Reflect.isFunction(callback_func)) {
			trace("invalid on call");
			return false;
		}
		Reflect.callMethod(Net.client, Reflect.field(Net.client, "callback_func"), Args);
		return true;
	}
	
	/**
	 * destroy the client
	 * disconnects and stops threads too
	 */
	public function destroy():Void {
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