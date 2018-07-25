import 'package:cou_server2/cou_server2.dart';

class Auction extends ManagedObject<_Auction> implements _Auction {}

class _Auction {
	static String tableName() => "auctions";

	@primaryKey
	int id;

	@Column()
	String item_name;

	@Column()
	int item_count;

	@Column()
	int total_cost;

	@Column(defaultValue: "now()")
	DateTime start_time = DateTime.now();

	@Column(defaultValue: "(now() + '2 days'::interval)")
	DateTime end_time = DateTime.now().add(Duration(days: 2));

	@Relate(#auctions, isRequired: true, onDelete: DeleteRule.restrict)
	User user;
}
