package oink.nethaxe;

import sys.net.Socket;

/**
 * Wrapper for the client socket.
 */
class ClientInfo {
	public var socket:Socket;
	public var name:String;
	public var server:Server;
	public var active:Bool;
	public function new(sv:Server, skt:Socket) {
		server = sv;
		socket = skt;
		name = '';
		active = true;
	}
	public function toString():String {
		var peer = socket.peer();
		var pstr = Std.string(peer.host) + ':' + peer.port;
		return (name == null || name == '') ? pstr : (name + '(' + pstr + ')');
	}
	public function send(text:String) {
		try {
			socket.output.writeString(text);
		} catch (z:Dynamic) {
			active = false;
		}
	}
}