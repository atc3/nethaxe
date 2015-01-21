package oink.nethaxe.server ;

import haxe.io.BytesInput;
import haxe.io.Bytes;

import sys.net.Host;
import sys.net.Socket;
import cpp.vm.Thread;

import org.bsonspec.ObjectID;
import org.bsonspec.BSON;
import pgr.dconsole.DC;

import oink.nethaxe.client.Client;
import oink.nethaxe.client.ClientInfo;

/**
 * Server.hx
 * Server side of chat.
 * Based off of yellowafterlife's chat server
 */
class Server {
	
	/**
	 * max connections the server will accept before rejecting new requests
	 */
	public static inline var MAX_CLIENTS = 4;
	
	/**
	 * server socket that will accept all incoming connections
	 */
	public var socket:Socket;
	
	/**
	 * array of clients to handle i/o from
	 */
	public var clients:Array<ClientInfo>;
	
	/**
	 * server info
	 */
	public var info:ServerInfo;
	
	/**
	 * thread that accepts incoming connection requests
	 */
	public var accept_thread:Thread;
	
	/**
	 * threads that handle client i/o
	 */
	public var listen_threads:Array<Thread>;
	
	/**
	 * map of all 'on' event callbacks
	 */
	private var event_map:Map<String, Dynamic>;
	
	/**
	 * helper var to track and call 'on' functions
	 */
	private var callback_func:Dynamic;
	
	/**
	 * constructor. 
	 * auto connects to given host and port
	 * @param	Hostname
	 * @param	Port
	 */
	public function new(Hostname:String = '', Port:Int = 0) {
		// Initialize some values
		info = new ServerInfo(this);
		
		bind(Hostname, Port);
		
		clients = [];
		
		event_map = new Map<String, Dynamic>();
		
		accept_thread = Thread.create(threadAccept);
		listen_threads = [];
	}
	
	/**
	 * bind the server to the given hostname and port
	 * @param	Hostname host to bind to. eg. 'localhost'. defaults to 127.0.0.1
	 * @param	Port port to bind to. defaults to 3000
	 * @return true if success, false if fail
	 */
	public function bind(Hostname:String, Port:Int):Bool {
		
		// apply defaults
		if (Hostname == '') Hostname = Net.DEFAULT_HOSTNAME;
		if (Port == 0) Port = Net.DEFAULT_PORT;
		info.port = Port;
		info.hostname = Hostname;
		info.host = new Host(Hostname);
		
		// Bind server to port and start listening:
		trace('Binding...');
		try {
			socket = new Socket();
			socket.bind(info.host, Port);
			socket.listen(MAX_CLIENTS);
		} catch (z:Dynamic) {
			trace('Could not bind to port.');
			trace('Ensure that no server is running on port ' + Port);
			return false;
		}
		Net.server_active = true;
		return true;
	}
	
	/** 
	 * Accepts new sockets and spawns new threads for them
	 **/
	function threadAccept() {
		var thread_message = "";
		while (thread_message != "finish") {
			thread_message = Thread.readMessage(false);
			
			var sk = socket.accept();
			if (sk != null) {
				var cl = new ClientInfo(this, sk);
				
				var listen_thread = Thread.create(getThreadListen(cl));
				listen_threads.push(listen_thread);
			}
		}
	}
	
	/** 
	 * Creates a new thread function to handle given ClientInfo 
	 **/
	function getThreadListen(cl:ClientInfo) {
		return function() {
			// keep track of this client
			clients.push(cl);
			
			trace(Std.string(cl) + ' connected.');
			//broadcast(Std.string(cl) + ' connected.');
			
			var thread_message = "";
			while (cl.active && thread_message != "finish") {
				thread_message = Thread.readMessage(false);
				
				var packet = BSON.decode(cl.socket.input);
				
				// skip empty packet
				if (Reflect.fields(packet).length <= 0) {
					trace("received empty packet");
					continue;
				}
				
				trace(packet);
				
				var action = packet.action;
				
				if (event_map.exists(action)) {
					on_trigger(action, [packet, cl]);
				} else {
					trace("invalid XP type");
					trace("Message Type: " + action);
					trace(packet);
				}
			}
			
			// if time out, clean up
			trace(Std.string(cl) + ' timed out.');
			//broadcast(Std.string(cl) + ' timed out.');
			
			clients.remove(cl);
			
			// attempt to destroy
			try {
				cl.socket.shutdown(true, true);
				cl.socket.close();
			} catch (e:Dynamic) {
				trace(e);
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
	public function on_trigger(Event:String, Args:Array<Dynamic>):Bool {
		callback_func = event_map.get(Event);
		if (!Reflect.isFunction(callback_func)) {
			trace("invalid on call");
			return false;
		}
		Reflect.callMethod(Net.server, Reflect.field(Net.server, "callback_func"), Args);
		return true;
	}
	
	/**
	 * destroy server
	 * disconnects all clients and kills all threads
	 */
	public function destroy():Void {
		
		Net.server_active = false;
		
		// destroy threads
		accept_thread.sendMessage("finish");
		for (thread in listen_threads) {
			thread.sendMessage("finish");
		}
		
		// close sockets
		for (cl in clients) {
			try {
				cl.socket.shutdown(true, true);
				cl.socket.close();
			} catch (e:Dynamic) {
				trace(e);
			}
			cl = null;
		}
		try {
			socket.shutdown(true, true);
			socket.close();
		} catch (e:Dynamic) {
			trace(e);
		}
		
		// clear vars
		clients = [];
		info = null;
	}
}