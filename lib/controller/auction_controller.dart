import 'package:cou_server2/cou_server2.dart';

class AuctionController extends ResourceController {
	@Operation.post()
	Future<Response> postAuction(@Bind.body() Auction auction) async {
		Query<Auction> query = Query<Auction>(app.channel.context)
			..values = auction;

		try {
			auction = await query.insert();
			return Response.created('/auctions/${auction.id}', body: auction);
		} catch (e) {
			return Response.badRequest();
		}
	}

	@Operation.get("id")
	Future<Response> getAuction() async {
		final int id = int.parse(request.path.variables["id"]);

		Query<Auction> auctionQuery = Query<Auction>(app.channel.context)
			..where((Auction auction) => auction.id).equalTo(id);

		try {
			Auction auction = await auctionQuery.fetchOne();

			if (auction == null) {
				return Response.notFound();
			}

			return Response.ok(auction);
		} catch (e) {
			return Response.serverError(body: e.toString());
		}
	}

	@Operation.get("item_name", "username", "item_count", "total_cost")
	Future<Response> getAuctions() async {
		final String itemName = request.path.variables["item_name"] ?? null;
		final String username = request.path.variables["username"];
		final String itemCount = request.path.variables["item_count"] ?? null;
		final String totalCost = request.path.variables["total_cost"] ?? null;

		Query<Auction> auctionQuery = Query<Auction>(app.channel.context);

		if (itemName != null) {
			auctionQuery..where((Auction auction) => auction.item_name).contains(itemName, caseSensitive: false);
		}

		if (username != null) {
			auctionQuery..where((Auction auction) => auction.user.username).equalTo(username, caseSensitive: false);
		}

		if (itemCount != null) {
			try {
				_applyCompareParam(auctionQuery, (Auction auction) => auction.item_count, "item_count", itemCount);
			} on FormatException catch (e) {
				return Response.badRequest(body: e.message);
			}
		}

		if (totalCost != null) {
			try {
				_applyCompareParam(auctionQuery, (Auction auction) => auction.total_cost, "total_cost", totalCost);
			} on FormatException catch (e) {
				return Response.badRequest(body: e.message);
			}
		}

		try {
			List<Auction> auctions = await auctionQuery.fetch();
			return Response.ok(auctions);
		} catch (e) {
			return Response.serverError(body: e.toString());
		}
	}

	void _applyCompareParam(Query<Auction> query, Function property, String paramName, String parameter) {
		RegExp costRegex = RegExp(r'(eq|ge|le|lt|gt)(\d+)');
		List<Match> matches = costRegex.allMatches(parameter).toList();

		if (matches.length > 2) {
			throw FormatException("$paramName may not have more than two operators");
		}

		if (matches.length > 1) {
			String firstOp = matches[0].group(1);
			String secondOp = matches[1].group(1);

			if (firstOp == 'eq' || secondOp == 'eq') {
				throw FormatException("$paramName may not have more than one operator if one of the operators is eq");
			}

			if (firstOp == 'lt' || firstOp == 'le' || secondOp == 'gt' || secondOp == 'ge') {
				throw FormatException(r" range must be specified as (gt|ge)\d+,(lt|le)\d+");
			}

			// these parses shouldn't fail since it matched the regex already
			int firstValue = int.parse(matches[0].group(2));
			int secondValue = int.parse(matches[1].group(2));

			if (firstOp == 'gt') {
				firstValue++;
			}

			if (secondOp == 'lt') {
				secondValue--;
			}

			query..where(property).between(firstValue, secondValue);
		} else if (matches.length == 1) {
			String op = matches[0].group(1);
			int cost = int.parse(matches[0].group(2));

			switch (op) {
				case 'eq':
					query..where(property).equalTo(cost);
					break;
				case 'lt':
					query..where(property).lessThan(cost);
					break;
				case 'gt':
					query..where(property).greaterThan(cost);
					break;
				case 'le':
					query..where(property).lessThanEqualTo(cost);
					break;
				case 'ge':
					query.where(property).greaterThanEqualTo(cost);
					break;
			}
		} else {
			throw FormatException("$paramName must be in the format (?:(eq|ge|le|lt|gt)(\d+),?)");
		}
	}
}
