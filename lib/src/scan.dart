part of scanner;

class Scanner {
	final InternetAddress host;
	var ports = [];
	List<int> foundPorts = [];
	List<int> closedPorts = [];
	final Duration socketTimeout;
	List<Future> connections = [];
	bool _isRunning = false;
	
	bool get isRunning => _isRunning;
	
	Scanner(this.host, this.ports, {this.socketTimeout = const Duration(seconds: 1)}) {
		if (ports.isEmpty) {
			throw Exception('Ports list is empty');
		} else if (ports.any((port)=> port < 0 || 65535 < port )) {
			throw Exception('Some port is out of range 0-65535');
		}
	}
	
	Future start() async {
		if (_isRunning) {
			throw Exception('Scanning is in progress');
		}
		
		_isRunning = true;
		
		Completer completer = new Completer();
		for(final port in this.ports){
			this.probe(port);
		}
		
		
		Future.wait(this.connections).then((sockets) {
			final results = {
				'open': this.foundPorts,
				'closed': this.closedPorts
			};
			completer.complete(json.encode(results));
		});
		
		return completer.future;
	}
	
	void probe(port) {
		this.connections.add(Socket.connect(this.host.address, port).then((socket) {
			this.foundPorts.add(socket.remotePort);
			socket.destroy();
		}).catchError((error) {
			this.closedPorts.add(port);
		}));
	}
}