import 'package:cou_server2/cou_server2.dart';
import 'package:test/test.dart';
import 'package:aqueduct/test.dart';
import 'package:aqueduct/aqueduct.dart';

void main() {
	Application<ServerRequestSink> app = Application<ServerRequestSink>();
	TestClient client;
	List<String> itemTypes = ['pick', 'fancy_pick', 'guano'];
	List<String> usernames = ['Thaderator', 'Elle Lament', 'Paal', 'Klikini'];
	Map auctionMatchMap = {
		"id": greaterThan(0),
		"item_name": isIn(itemTypes),
		"item_count": greaterThan(0),
		"total_cost": greaterThan(0),
		"start_time": isNotEmpty,
		"end_time": isNotEmpty,
		"user": {"id": greaterThan(-1)}
	};

	setUp(() async {
		await app.start(runOnMainIsolate: true);
		client = TestClient(app);

		ManagedContext ctx = ManagedContext.defaultContext;
		SchemaBuilder builder = SchemaBuilder.toSchema(
			ctx.persistentStore, Schema.fromDataModel(ctx.dataModel),
			isTemporary: true);

		for (String cmd in builder.commands) {
			await ctx.persistentStore.execute(cmd);
		}

		// create an auction for every item type
		for (int i = 0; i < itemTypes.length; i++) {
			Query<Auction> auctionQuery = Query<Auction>();
			Query<User> userQuery = Query<User>();
			User user = User()
				..id = i
				..username = usernames[i % usernames.length]
				..email = usernames[i % usernames.length] + '@domain.com'
				..bio = '';
			userQuery.values = user;
			await userQuery.insert();
			Query<ApiAccess> apiQuery = Query<ApiAccess>();
			apiQuery.values
				..user = user
				..access_count = 0
				..api_token = '$i-$i-$i-$i-$i';
			await apiQuery.insert();
			auctionQuery.values
				..item_name = itemTypes[i % itemTypes.length]
				..user = user
				..item_count = i + 1
				..total_cost = (i + 1) * 10;
			await auctionQuery.insert();
		}
	});

	tearDown(() async {
		await app.stop();
	});

	test("/auctions returns list of auctions", () async {
		TestRequest request = client.request("/auctions");
		request.addHeader('api-key', '0-0-0-0-0');
		TestResponse response = await request.get();
		expect(response, hasResponse(200, everyElement(auctionMatchMap)));
		expect(response.decodedBody, hasLength(itemTypes.length));
	});

	test('/auctions?item_type= returns auctions for a specific item', () async {
		TestRequest request = client.request('/auctions?item_name=pick');
		request.addHeader('api-key', '0-0-0-0-0');
		TestResponse response = await request.get();
		expect(response, hasResponse(200, everyElement(auctionMatchMap)));
		expect(response.decodedBody, hasLength(2));

		request = client.request('/auctions?item_name=fancy_pick');
		request.addHeader('api-key', '0-0-0-0-0');
		response = await request.get();
		expect(response, hasResponse(200, everyElement(auctionMatchMap)));
		expect(response.decodedBody, hasLength(1));

		request = client.request('/auctions?item_name=bogus');
		request.addHeader('api-key', '0-0-0-0-0');
		response = await request.get();
		expect(response.decodedBody, hasLength(0));
	});

	test('/auctions?total_cost= returns auctions compared to cost', () async {
		await _intOpParseTest('total_cost', client, auctionMatchMap);
	});

	test(
		'/auctions?item_count= returns auctions compared to item count', () async {
		await _intOpParseTest('item_count', client, auctionMatchMap);
	});

	test('/auctions/:id returns the auction matching id', () async {
		TestRequest request = client.request('/auctions/1');
		request.addHeader('api-key', '0-0-0-0-0');
		TestResponse response = await request.get();
		expect(response, hasResponse(200, auctionMatchMap));

		request = client.request('/auctions/${itemTypes.length + 1}');
		request.addHeader('api-key', '0-0-0-0-0');
		response = await request.get();
		expect(response, hasResponse(404, isNull));
	});

	test('post to /auctions and expect the new auction to be there', () async {
		User user = User()
			..id = 1;
		Auction auction = Auction()
			..item_name = itemTypes[0]
			..user = user
			..item_count = 10
			..total_cost = 50;

		TestRequest request = client.request('/auctions')
			..json = auction.asMap();
		request.addHeader('api-key', '0-0-0-0-0');
		TestResponse response = await request.post();
		expect(response, hasResponse(201, auctionMatchMap));
		auction.readMap(response.decodedBody);
		expect(auction.user.id, equals(1));
		expect(auction.item_name, equals(itemTypes[0]));
	});
}

_intOpParseTest(String param, TestClient client,
	Map<String, dynamic> auctionMatchMap) async {
	TestRequest request = client.request('/auctions?total_cost=lt10');
	request.addHeader('api-key', '0-0-0-0-0');
	TestResponse response = await request.get();
	expect(response.decodedBody, hasLength(0));

	request = client.request('/auctions?total_cost=lt20');
	request.addHeader('api-key', '0-0-0-0-0');
	response = await request.get();
	expect(response, hasResponse(200, everyElement(auctionMatchMap)));
	expect(response.decodedBody, hasLength(1));

	request = client.request('/auctions?total_cost=gt10,le20');
	request.addHeader('api-key', '0-0-0-0-0');
	response = await request.get();
	expect(response, hasResponse(200, everyElement(auctionMatchMap)));
	expect(response.decodedBody, hasLength(1));

	request = client.request('/auctions?total_cost=ge10,le20');
	request.addHeader('api-key', '0-0-0-0-0');
	response = await request.get();
	expect(response, hasResponse(200, everyElement(auctionMatchMap)));
	expect(response.decodedBody, hasLength(2));

	request = client.request('/auctions?total_cost=30');
	request.addHeader('api-key', '0-0-0-0-0');
	response = await request.get();
	expect(response, hasResponse(400, contains('must be in the format')));

	request = client.request('/auctions?total_cost=le5,le6,le7');
	request.addHeader('api-key', '0-0-0-0-0');
	response = await request.get();
	expect(response,
		hasResponse(400, contains('may not have more than two operators')));

	request = client.request('/auctions?total_cost=eq5,eq6');
	request.addHeader('api-key', '0-0-0-0-0');
	response = await request.get();
	expect(response, hasResponse(400, contains(
		'may not have more than one operator if one of the operators is eq')));
}