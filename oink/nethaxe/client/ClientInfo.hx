package oink.nethaxe.client ;

import haxe.io.Bytes;
import org.bsonspec.BSON;
import org.bsonspec.ObjectID;
import sys.net.Socket;

import oink.nethaxe.server.Server;

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
	public function send(Text:String, Action:String = "INFO") {
		
		var send_packet = BSON.encode({
			_id: new ObjectID()
			, action: Action
			, text: Text
		});
		
		try {
			//socket.output.writeString(text);
			socket.output.write(send_packet);
		} catch (z:Dynamic) {
			active = false;
		}
	}
}