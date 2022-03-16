import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:string_validator/string_validator.dart';
import 'package:dart_scan/scanner.dart';

void main(List<String> arguments) async {
	final parser = ArgParser()
		..addFlag('help', abbr: 'h', help: 'Display this help menu.')
		..addOption('host', defaultsTo: '', abbr: 'H', help: 'The host which to scan. Must be a FQDN or IP address.')
		..addOption('ports', defaultsTo: '', abbr: 'p', help: 'The port or ports to scan on the host. Can be a single port, comma-separated list of ports, or a range of ports.');
	var opts = parser.parse(arguments);
	
	if(opts['help']){
		print(parser.usage);
		exit(2);
	}
	
	if(opts['host'] == ''){
		print('	You must specify a host domain name or IP.');
		exit(2);
	}
	
	if(opts['ports'] == ''){
		print('	You must specify a port, comma-separated list of ports, or range of ports.');
		exit(2);
	}
	
	InternetAddress ip = await getIP(opts['host']);
	
	if (ip == null) {
		print('Error: Invalid host target.');
		exitCode = 2;
	}
	
	var ports = [];
	if (opts['ports'].contains("-")) {
		var range = opts['ports'].split("-");
		ports = range2List(int.parse(range[0]), int.parse(range[1]));
	} else if (opts['ports'].contains(",")) {
		ports = opts['ports'].split(",");
	} else {
		ports.add(opts['ports']);
	}
	
	try {
		Scanner scanner = new Scanner(ip, ports);
		scanner.start().then((data) {
			Map<String, dynamic> map = json.decode(data);
			List<dynamic> openPorts = map["open"];
			List<dynamic> closedPorts = map["closed"];
			int closedCt = closedPorts.length;
			
			print(' ');
			print('Found $closedCt closed ports.');
			print('Found open ports:');
			
			openPorts.forEach((port) {
				print('$port');
			});
			
			print(' ');
			print('Scan complete!');
		});
	} catch(e) {
		stderr.write('Error: $e');
	}
}

List range2List(int n, int m, [bool excludeLimits = false]) {
	final diff = m - n;
	final times = excludeLimits ? diff - 1 : diff + 1;
	final startingIdx = excludeLimits ? n + 1 : n;
	return List.generate(times, (i) => startingIdx + i);
}

Future<InternetAddress> getIP(String host) async {
	if(isIP(host)){
		return Future<InternetAddress>.value(new InternetAddress(host));
	}else{
		var value = await InternetAddress.lookup(host);
		return Future<InternetAddress>.value(value[0]);
	}
}