package oink.nethaxe.server ;

import cpp.vm.Thread;
import haxe.io.BytesInput;
import haxe.io.Bytes;
import org.bsonspec.ObjectID;
import sys.net.Host;
import sys.net.Socket;
import pgr.dconsole.DC;

import org.bsonspec.BSON;

import oink.nethaxe.client.Client;
import oink.nethaxe.client.ClientInfo;

/**
 * Server.hx
 * Server side of chat.
 * Based off of yellowafterlife's chat server
 */
class Server {
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
	
	public var accept_thread:Thread;
	public var listen_threads:Array<Thread>;
	
	var event_map:Map<String, Dynamic>;
	var callback_func:Dynamic;
	
	public function new(Hostname:String = '', Port:Int = 0) {
		
		// Initialize some values
		info = new ServerInfo(this);
		
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
			socket.listen(4);
			
			Net.server_active = true;
		} catch (z:Dynamic) {
			trace('Could not bind to port.');
			trace('Ensure that no server is running on port ' + Port);
			return;
		}
		
		clients = [];
		
		event_map = new Map<String, Dynamic>();
		
		// on triggers
		on("CHAT", on_chat);
		on("INFO", on_chat);
		on("PING", on_ping);
		on("REMOTEPLAYERLOC", on_remoteplayerloc);
		
		accept_thread = Thread.create(threadAccept);
		listen_threads = [];
		
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
			broadcast(Std.string(cl) + ' connected.');
			
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
			broadcast(Std.string(cl) + ' timed out.');
			
			broadcast(cl.name + ' disconnected.');
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
	
	/** 
	 * Sends given text to all active clients 
	 **/
	function broadcast(Text:String, Type:String = "INFO") {
		for (cl in clients) {
			cl.send(Text);
		}
	}
	
	/** 
	 * Finds client(s) that match given name 
	 **/
	function find_clients(name:String) {
		var r:Array<ClientInfo> = [];
		name = name.toLowerCase();
		for (cl in clients) {
			if (cl.name.toLowerCase().indexOf(name) != -1) r.push(cl);
		}
		return r;
	}
	
	/** 
	 * Chat message handler 
	 **/
	function on_chat(packet, cl:ClientInfo) {
		
		if (!Reflect.hasField(packet, "text")) return;
		var text = packet.text;
		
		// disallow empty input
		if (text == '') return;
		
		// command handling
		if (text.charAt(0) == '/') {
			
			trace(Std.string(cl) + ' issued command: ' + text + '\n');
			broadcast(Std.string(cl) + ' issued command: ' + text + '\n');
			
			// regex for sanitation
			text = text.substr(1);
			var rx = ~/^(\w+) *(.*)/g;
			
			// idiot proofing
			if (!rx.match(text)) { 
				cl.send('Not a valid command format.'); 
				return; 
			}
			
			// parse command and parameters
			var cmd = rx.matched(1);
			var par = rx.matched(2);
			
			switch (cmd) {
				// lists online users
				case 'list', 'online': 
					
					var r = '';
					var c = 0;
					
					for (cl in clients) {
						if (c++ != 0) r += ', ';
						r += cl.name;
					}
					
					r = 'Users online (' + c + '): ' + r + '\n';
					cl.send(r);
				
				// changes username
				case 'name', 'nick':
					
					// sanitation and idiot proofing
					rx = ~/^(\w+)/;
					if (!rx.match(par)) { 
						cl.send('Not a valid name.\n'); 
						return; 
					}
					var name = rx.matched(1);
					
					// check if new name does not match with existing one:
					var overlap = false;
					for (cl in clients) { 
						if (name == cl.name) { 
							overlap = true; 
							break; 
						} 
					}
					if (overlap) { 
						cl.send('Such name already exists.'); 
						return; 
					}
					
					// inform participants:
					trace(Std.string(cl) + ' is now known as ' + name + '.\n');
					broadcast(Std.string(cl) + ' is now known as ' + name + '.\n');
					
					if (cl.name == '') {
						broadcast(name + ' connected.\n');
					} else {
						broadcast(cl.name + ' is now known as ' + name + '.\n');
					}
					
					// actual name assignment
					cl.name = name;
					
					return;
					
				// sends private message
				case 'msg', 'm':
					
					// sanitation and idiot proofing
					rx = ~/^(\w+) *(.+)/;
					if (!rx.match(par)) { 
						cl.send('Invalid format.\n'); 
						return; 
					}
					
					// find targeted client(s)
					var rcs = find_clients(rx.matched(1));
					
					// not found
					if (rcs.length == 0) { 
						cl.send('User not found.\n'); 
						return; 
					}
					
					// send message
					var msg = rx.matched(2);
					for (rc in rcs) {
						cl.send('[me > ' + rc.name + '] ' + msg + '\n');
						rc.send('[' + cl.name + ' > me] ' + msg + '\n');
					}
			}
		} else {
			
			// send message
			trace(Std.string(cl) + ': ' + text + '\n');
			broadcast((cl != null ? cl.name + ': ' : '') + text + '\n');
		}
	}

	function on_ping(packet, cl:ClientInfo) {
		trace(cl.name + " pinged");
		trace("sending PONG to " + cl.name);
		
		var pong_packet = BSON.encode({
			_id: new ObjectID()
			, action: "PONG"
		});
		
		try {
			cl.socket.output.write(pong_packet);
		} catch (z:Dynamic) {
			trace(z);
		}
	}
	
	function on_remoteplayerloc(packet, cl:ClientInfo) {
		if (!Reflect.hasField(packet, "client_id")
			|| !Reflect.hasField(packet, "x")
			|| !Reflect.hasField(packet, "y")) return;
			
		var remoteplayerloc_packet = BSON.encode({
			_id: new ObjectID()
			, action: "REMOTEPLAYERLOC"
			, client_id: packet.client_id
			, x: packet.x
			, y: packet.y
		});
		
		for (client in clients) {
			try {
				client.socket.output.write(remoteplayerloc_packet);
			} catch (z:Dynamic) {
				trace(z);
			}
		}
	}
}