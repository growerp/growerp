import "balance_by_time_period.dart";
import "total_balance_by_time_period.dart";
import "total_posted_by_time_period.dart";
import "total_posted_no_closing_by_time_period.dart";

class CurrentAsset {
	String glAccountClassEnumId;
	String className;
	BalanceByTimePeriod balanceByTimePeriod;
	TotalBalanceByTimePeriod totalBalanceByTimePeriod;
	TotalPostedByTimePeriod totalPostedByTimePeriod;
	TotalPostedNoClosingByTimePeriod totalPostedNoClosingByTimePeriod;

	CurrentAsset({
		this.glAccountClassEnumId,
		this.className,
		this.balanceByTimePeriod,
		this.totalBalanceByTimePeriod,
		this.totalPostedByTimePeriod,
		this.totalPostedNoClosingByTimePeriod,
	});

	factory CurrentAsset.fromJson(Map<String, dynamic> json) {
		return CurrentAsset(
			glAccountClassEnumId: json['glAccountClassEnumId'] as String,
			className: json['className'] as String,
			balanceByTimePeriod: json['balanceByTimePeriod'] == null
					? null
					: BalanceByTimePeriod.fromJson(json['balanceByTimePeriod'] as Map<String, dynamic>),
			totalBalanceByTimePeriod: json['totalBalanceByTimePeriod'] == null
					? null
					: TotalBalanceByTimePeriod.fromJson(json['totalBalanceByTimePeriod'] as Map<String, dynamic>),
			totalPostedByTimePeriod: json['totalPostedByTimePeriod'] == null
					? null
					: TotalPostedByTimePeriod.fromJson(json['totalPostedByTimePeriod'] as Map<String, dynamic>),
			totalPostedNoClosingByTimePeriod: json['totalPostedNoClosingByTimePeriod'] == null
					? null
					: TotalPostedNoClosingByTimePeriod.fromJson(json['totalPostedNoClosingByTimePeriod'] as Map<String, dynamic>),
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'glAccountClassEnumId': glAccountClassEnumId,
			'className': className,
			'balanceByTimePeriod': balanceByTimePeriod?.toJson(),
			'totalBalanceByTimePeriod': totalBalanceByTimePeriod?.toJson(),
			'totalPostedByTimePeriod': totalPostedByTimePeriod?.toJson(),
			'totalPostedNoClosingByTimePeriod': totalPostedNoClosingByTimePeriod?.toJson(),
		};
	}
}
