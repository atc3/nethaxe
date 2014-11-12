package oink.nethaxe;

import pgr.dconsole.DC;

/**
 * Wrapper for the server socket
 */
class ServerInfo extends ClientInfo {
	public function new(sv:Server) {
		super(sv, null);
		name = 'Server';
	}
	override public function toString():String {
		return name + '(console)';
	}
	override public function send(text:String) {
		DC.log(text);
	}
}