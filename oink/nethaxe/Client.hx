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
	//var console:RawEdit;
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
	public function new() {
		//var cout = Sys.stdout();
		//var cin = Sys.stdin();
		//
		//cout.writeString('Server IP: ');
		//var ip = cin.readLine();
		//if (ip == '') ip = '127.0.0.1';
		var ip = '127.0.0.1';
		//cout.writeString('Port: ');
		//var port = Std.parseInt(cin.readLine());
		//if (port == null) port = 17051;
		var port = 3000;
		//cout.writeString('Connecting...\n');
		DC.log('Connecting...\n');
		try {
			socket = new Socket();
			socket.connect(new Host(ip), port);
			//cout.writeString('Connected to ' + ip + ':' + port + '\n');
			DC.log('Connected to ' + ip + ':' + port + '\n');
		} catch (z:Dynamic) {
			//cout.writeString('Could not connect to ' + ip + ':' + port + '\n');
			DC.log('Could not connect to ' + ip + ':' + port + '\n');
			return;
		}
		//
		socket.output.writeString('/name User' + Std.int(Math.random() * 65536) + '\n');
		//console = new RawEdit();
		//console.prefix = '> ';
		//console.onSend = onChatLine;
		Thread.create(threadListen);
		//console.open();
	}
	
}