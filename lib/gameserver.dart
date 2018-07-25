import 'package:cou_server2/cou_server2.dart';

Application<GameServer> app;

class GameServer extends ApplicationChannel {
	ManagedContext context;

	@override
	Future prepare() async {
		final config = RestPostgresConfiguration(options.configurationFilePath);
		context = contextWithConnectionInfo(config.database);
	}

	@override
	Controller get entryPoint {
		final router = Router();

		router
			.route("/auctions/[:id([0-9]+)]")
			.link(() => AuctionController());

		router
			.route("/users[/:id([0-9]+)]")
			.link(() => UserController());

		return router;
	}

	ManagedContext contextWithConnectionInfo(DatabaseConfiguration connectionInfo) {
		ManagedDataModel dataModel = ManagedDataModel.fromCurrentMirrorSystem();

		PostgreSQLPersistentStore psc = PostgreSQLPersistentStore.fromConnectionInfo(
			connectionInfo.username,
			connectionInfo.password,
			connectionInfo.host,
			connectionInfo.port,
			connectionInfo.databaseName);

		return ManagedContext(dataModel, psc);
	}
}

class RestPostgresConfiguration extends Configuration {
	RestPostgresConfiguration(String file) : super.fromFile(File(file));

	DatabaseConfiguration database;
}
