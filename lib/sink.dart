import 'package:cou_server2/cou_server2.dart';

class SSLDatabaseConnectionConfiguration
	extends DatabaseConnectionConfiguration {
	bool useSSL = false;
}

class ServerConfiguration extends ConfigurationItem {
	ServerConfiguration(String fileName) : super.fromFile(fileName);

	SSLDatabaseConnectionConfiguration database;
}

class ServerRequestSink extends RequestSink {
	ManagedContext context;

	ServerRequestSink(ApplicationConfiguration appConfig) : super(appConfig) {
		ServerConfiguration options = new ServerConfiguration(
			appConfig.configurationFilePath ?? 'test.config.yaml');
		ManagedDataModel dataModel = new ManagedDataModel
			.fromCurrentMirrorSystem();
		PostgreSQLPersistentStore persistentStore = new PostgreSQLPersistentStore
			.fromConnectionInfo(
			options.database.username, options.database.password,
			options.database.host, options.database.port,
			options.database.databaseName, useSSL: options.database.useSSL);
		context = new ManagedContext(dataModel, persistentStore);
	}

	@override
	void setupRouter(Router router) {
		router
			.route("/auctions[/:id([0-9]+)]")
			.pipe(new APIAuthorizer(null))
			.generate(() => new AuctionController());
		router
			.route('/users[/:id([0-9]+)]')
			.pipe(new APIAuthorizer(null))
			.generate(() => new UserController());
	}
}

class APIAuthorizer extends Authorizer {
	APIAuthorizer(AuthValidator validator) : super(validator);

	Future<RequestOrResponse> processRequest(Request request) async {
		String apiKey = request.innerRequest.headers.value('api-key');
		Query<ApiAccess> apiQuery = new Query<ApiAccess>()
			..where.api_token = whereEqualTo(apiKey);
		try {
			ApiAccess apiAccess = await apiQuery.fetchOne();
			if (apiAccess.access_count < 100) {
				apiQuery.values.access_count = apiAccess.access_count + 1;
				await apiQuery.updateOne();
				return request;
			} else {
				// there's a cron job to reset it every 15 minutes (*/15 * * * *)
				// so we'll figure out how many seconds until they can try again
				DateTime now = new DateTime.now();
				int retry = 0;
				int currentMinute = now.minute;
				if (currentMinute > 44) {
					retry = (60 - currentMinute) * 60;
				} else if (currentMinute > 29) {
					retry = (45 - currentMinute) * 60;
				} else if (currentMinute > 14) {
					retry = (30 - currentMinute) * 60;
				} else {
					retry = (15 - currentMinute) * 60;
				}
				retry -= now.second;
				return new Response(
					429, {'retry-after': '$retry'}, 'Rate limit exceeded');
			}
		} catch (_) {
			return new Response.unauthorized();
		}
	}
}