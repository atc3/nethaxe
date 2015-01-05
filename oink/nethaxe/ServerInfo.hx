package oink.nethaxe;

import pgr.dconsole.DC;
import sys.net.Host;

/**
 * Wrapper for the server socket
 */
class ServerInfo extends ClientInfo {
	
	// hostname server is bound to.
	public var hostname:String;
	// port server is bound to.
	public var port:Int;
	
	// host object. used by sockets
	public var host:Host;
	
	public function new(sv:Server) {
		super(sv, null);
		name = 'Server';
	}
	override public function toString():String {
		return name + '(console)';
	}
	override public function send(Text:String, Action:String = "INFO") {
		trace(Text);
	}
}