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
	var socket:Socket;
	
	public function new() {
		var ip = '127.0.0.1';
		var port = 3000;
		DC.log('Connecting...\n');
		try {
			socket = new Socket();
			socket.connect(new Host(ip), port);
			DC.log('Connected to ' + ip + ':' + port + '\n');
		} catch (z:Dynamic) {
			DC.log('Could not connect to ' + ip + ':' + port + '\n');
			return;
		}
		
		socket.output.writeString('/name User' + Std.int(Math.random() * 65536) + '\n');
		//console = new RawEdit();
		//console.prefix = '> ';
		//console.onSend = onChatLine;
		Thread.create(threadListen);
		//console.open();
		
		DC.registerFunction(onChatLine, "chat");
	}
	
	/** Input handler */
	function onChatLine(text:String):Bool {
		try {
			socket.write(text + '\n');
		} catch (z:Dynamic) {
			//console.write('Connection lost.\n');
			//console.close();
			DC.log('Connection lost.\n');
			return false;
		}
		return true;
	}
	/** Listener thread*/
	function threadListen() {
		while (true) {
			try {
				var text = socket.input.readLine();
				//console.write(text + '\n');
				DC.log(text + '\n');
			} catch (z:Dynamic) {
				//console.write('Connection lost.\n');
				//console.close();
				DC.log('Connection lost.\n');
				return;
			}
		}
	}
	
	
}