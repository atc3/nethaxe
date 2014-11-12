package oink.nethaxe;

import cpp.vm.Thread;
import sys.net.Host;
import sys.net.Socket;
import pgr.dconsole.DC;

/**
 * Server.hx
 * Server side of chat.
 * @author YellowAfterlife
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
	
	public function new() {
		var port = 3000;
		
		// Bind server to port and start listening:
		DC.log('Binding...\n');
		try {
			socket = new Socket();
			socket.bind(new Host('127.0.0.1'), port);
			socket.listen(3);
		} catch (z:Dynamic) {
			// bind failed. some other server is probably hogging the specified port
			DC.log('Could not bind to port.\n');
			DC.log('Ensure that no server is running on port ' + port + '.\n');
			return;
		}
		DC.log('Done.\n');
		
		// Initialize some values
		info = new ServerInfo(this);
		clients = [];
		//console.onSend = function(t:String) { onChat(t, info); return true; };
		Thread.create(threadAccept);
		//console.open();
	}
	
	
	/** 
	 * Sends given text to all active clients 
	 **/
	public function broadcast(text:String) {
		for (cl in clients) {
			cl.send(text);
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
		while (true) {
			var sk = socket.accept();
			if (sk != null) {
				var cl = new ClientInfo(this, sk);
				Thread.create(getThreadListen(cl));
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
			
			while (cl.active) {
				try {
					var text = cl.socket.input.readLine();
					
					//TODO: PROCESS INPUT TYPE
					
					if (cl.active) onChat(text, cl);
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
	
}