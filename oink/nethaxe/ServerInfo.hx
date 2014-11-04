package oink.nethaxe;

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
		//server.console.write(text);
		DC.log(text);
	}
}