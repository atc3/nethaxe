package oink.nethaxe.server;

import org.bsonspec.BSON;
import org.bsonspec.ObjectID;

import oink.nethaxe.client.ClientInfo;

/**
 * handy class with a few core on functions.
 * showcases extendability of server class
 */
class BaseServer extends Server {

	public function new(Hostname:String='', Port:Int=0)	{
		super(Hostname, Port);
		
		// on triggers
		on("CHAT", on_chat);
		on("INFO", on_chat);
		on("PING", on_ping);
		on("REMOTEPLAYERLOC", on_remoteplayerloc);
	}
	
	/**
	 * sends broadcast to all connected clients
	 * @param	Text
	 * @param	Type XP type
	 */
	function broadcast(Text:String, Type:String = "INFO") {
		for (cl in clients) {
			cl.send(Text);
		}
	}
	
	/**
	 * Find client(s) with the given name
	 * @param	name
	 */
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
	 * parses commands if it catches one
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

	/**
	 * receive ping from client and bounce back
	 * @param	packet
	 * @param	cl
	 */
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
	
	/**
	 * receive player location and distribute
	 * @param	packet
	 * @param	cl
	 */
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