import 'package:cou_server2/cou_server2.dart';

class AuctionController extends HTTPController {
	@httpPost
	Future<Response> postAuction() async {
		Auction auction = new Auction()
			..readMap(request.body.asMap());
		Query<Auction> query = new Query<Auction>()
			..values = auction;

		try {
			auction = await query.insert();
			return new Response.created(
				'/auctions/${auction.id}', body: auction);
		} catch (e) {
			return new Response.badRequest();
		}
	}

	@httpGet
	Future<Response> getAuction(@HTTPPath("id") int id) async {
		Query<Auction> auctionQuery = new Query<Auction>();
		auctionQuery.where.id = whereEqualTo(id);
		try {
			Auction auction = await auctionQuery.fetchOne();
			if (auction == null) {
				return new Response.notFound();
			}
			return new Response.ok(auction);
		} catch (e) {
			return new Response.serverError(body: e.toString());
		}
	}

	@httpGet
	Future<Response> getAuctions({@HTTPQuery("item_name") String item_name,
		@HTTPQuery("total_cost") String total_cost, @HTTPQuery(
			"username") String username, @HTTPQuery(
			"item_count") String item_count}) async {
		Query<Auction> auctionQuery = new Query<Auction>();
		if (item_name != null) {
			auctionQuery.where.item_name =
				whereContainsString(item_name, caseSensitive: false);
		}
		if (username != null) {
			auctionQuery.where.user.username =
				whereContainsString(username, caseSensitive: false);
		}
		if (item_count != null) {
			try {
				auctionQuery.where.total_cost =
					_parseIntCompareParam('item_count', item_count);
			} on FormatException catch (e) {
				return new Response.badRequest(body: e.message);
			}
		}
		if (total_cost != null) {
			try {
				auctionQuery.where.total_cost =
					_parseIntCompareParam('total_cost', total_cost);
			} on FormatException catch (e) {
				return new Response.badRequest(body: e.message);
			}
		}

		List<Auction> auctions = await auctionQuery.fetch();

		return new Response.ok(auctions);
	}

	_parseIntCompareParam(String paramName, String parameter) {
		RegExp costRegex = new RegExp(r'(eq|ge|le|lt|gt)(\d+)');
		List<Match> matches = costRegex.allMatches(parameter).toList();
		if (matches.length > 2) {
			throw new FormatException(
				'$paramName may not have more than two operators');
		}
		if (matches.length > 1) {
			String firstOp = matches[0].group(1);
			String secondOp = matches[1].group(1);
			if (firstOp == 'eq' || secondOp == 'eq') {
				throw new FormatException(
					'$paramName may not have more than one operator if one of the operators is eq');
			}
			if (firstOp == 'lt' || firstOp == 'le' ||
				secondOp == 'gt' || secondOp == 'ge') {
				throw new FormatException(
					r' range must be specified as (gt|ge)\d+,(lt|le)\d+');
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
			return whereBetween(firstValue, secondValue);
		} else if (matches.length == 1) {
			String op = matches[0].group(1);
			int cost = int.parse(matches[0].group(2));
			switch (op) {
				case 'eq':
					return whereEqualTo(cost);
				case 'lt':
					return whereLessThan(cost);
				case 'gt':
					return whereGreaterThan(cost);
				case 'le':
					return whereLessThanEqualTo(cost);
				case 'ge':
					return whereGreaterThanEqualTo(cost);
			}
		} else {
			throw new FormatException(
				'$paramName must be in the format (?:(eq|ge|le|lt|gt)(\d+),?)');
		}
	}
}