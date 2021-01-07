import "total_balance.dart";
import "total_posted.dart";
import "total_posted_no_closing.dart";

class NetIncomeOut {
	TotalPostedNoClosing totalPostedNoClosing;
	TotalBalance totalBalance;
	TotalPosted totalPosted;

	NetIncomeOut({this.totalPostedNoClosing, this.totalBalance, this.totalPosted});

	factory NetIncomeOut.fromJson(Map<String, dynamic> json) {
		return NetIncomeOut(
			totalPostedNoClosing: json['totalPostedNoClosing'] == null
					? null
					: TotalPostedNoClosing.fromJson(json['totalPostedNoClosing'] as Map<String, dynamic>),
			totalBalance: json['totalBalance'] == null
					? null
					: TotalBalance.fromJson(json['totalBalance'] as Map<String, dynamic>),
			totalPosted: json['totalPosted'] == null
					? null
					: TotalPosted.fromJson(json['totalPosted'] as Map<String, dynamic>),
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'totalPostedNoClosing': totalPostedNoClosing?.toJson(),
			'totalBalance': totalBalance?.toJson(),
			'totalPosted': totalPosted?.toJson(),
		};
	}
}
