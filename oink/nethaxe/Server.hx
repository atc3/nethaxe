package oink.nethaxe;

import cpp.vm.Thread;
import sys.net.Host;
import sys.net.Socket;
import pgr.dconsole.DC;

/**
 * Server.hx
 * Server side of chat.
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
		DC.log('Binding...\n');
		try {
			socket = new Socket();
			socket.bind(info.host, Port);
			socket.listen(4);
			
			Net.server_active = true;
			
		} catch (z:Dynamic) {
			// bind failed. some other server is probably hogging the specified port
			DC.log('Could not bind to port.\n');
			DC.log('Ensure that no server is running on port ' + Port + '.\n');
			return;
			
		}
		DC.log('Done.\n');
		
		clients = [];
		
		accept_thread = Thread.create(threadAccept);
		listen_threads = [];
	}
	
	/** 
	 * Sends given text to all active clients 
	 **/
	public function broadcast(Text:String, Type:String = "INFO") {
		for (cl in clients) {
			cl.send("XP/" + Type + "\n");
			cl.send(Text);
		}
	}
	
	/** 
	 * Finds client(s) that match given name 
	 **/
	public function findClients(name:String) {
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
	public function onChat(text:String, cl:ClientInfo) {
		// disallow empty input
		if (text == '') return;
		
		// command handling
		if (text.charAt(0) == '/') {
			
			DC.log(Std.string(cl) + ' issued command: ' + text + '\n');
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
					DC.log(Std.string(cl) + ' is now known as ' + name + '.\n');
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
					var rcs = findClients(rx.matched(1));
					
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
			DC.log(Std.string(cl) + ': ' + text + '\n');
			broadcast((cl != null ? cl.name + ': ' : '') + text + '\n');
		}
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
			
			DC.log(Std.string(cl) + ' connected.\n');
			broadcast(Std.string(cl) + ' connected.\n');
			
			var thread_message = "";
			while (cl.active && thread_message != "finish") {
				thread_message = Thread.readMessage(false);
				
				try {
					
					var text = cl.socket.input.readLine();
					
					if (cl.active) {
					
						var msg_type = Net.xp_protocol_check(text);
						if (msg_type != "") {
							switch(msg_type) {
								case "CHAT":
									text = cl.socket.input.readLine();
									onChat(text, cl);
								case "PING":
									DC.log(cl.name + " pinged\n");
									DC.log("sending PONG to " + cl.name);
									
									cl.send("XP/PONG" + "\n");
								default:
									// default behavior
									DC.log("invalid XP type\n");
									DC.log("Message Type: " + msg_type);
							}
						} else {
							// default behavior - chat
							onChat(text, cl);
						}
					}
					
				} catch (z:Dynamic) {
					break;
				}
			}
			
			// if time out, clean up
			DC.log(Std.string(cl) + ' timed out.\n');
			broadcast(Std.string(cl) + ' timed out.\n');
			
			broadcast(cl.name + ' disconnected.\n');
			clients.remove(cl);
			
			// attempt to destroy
			try {
				cl.socket.shutdown(true, true);
				cl.socket.close();
			} catch (e:Dynamic) {
				DC.log(e);
			}
		}
	}
	
	
	function destroy():Void {
		
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
				DC.log(e);
			}
			cl = null;
		}
		try {
			socket.shutdown(true, true);
			socket.close();
		} catch (e:Dynamic) {
			DC.log(e);
		}
		
		// clear vars
		clients = [];
		info = null;
	}
}