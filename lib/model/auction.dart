import 'package:cou_server2/cou_server2.dart';

class Auction extends ManagedObject<_Auction> implements _Auction {}

class _Auction {
	@ManagedColumnAttributes(primaryKey: true, autoincrement: true)
	int id;

	String item_name;
	int item_count;
	int total_cost;
	@ManagedColumnAttributes(defaultValue: 'now()')
	DateTime start_time = new DateTime.now();
	@ManagedColumnAttributes(defaultValue: "(now() + '2 days'::interval)")
	DateTime end_time = new DateTime.now().add(new Duration(days: 2));

	@ManagedRelationship(#auctions, isRequired: true,
		onDelete: ManagedRelationshipDeleteRule.restrict)
	User user;

	static String tableName() => "auctions";
}
