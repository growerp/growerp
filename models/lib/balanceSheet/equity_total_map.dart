import "total_balance.dart";
import "total_posted.dart";
import "total_posted_no_closing.dart";

class EquityTotalMap {
  TotalPostedNoClosing totalPostedNoClosing;
  TotalBalance totalBalance;
  TotalPosted totalPosted;

  EquityTotalMap(
      {this.totalPostedNoClosing, this.totalBalance, this.totalPosted});

  factory EquityTotalMap.fromJson(Map<String, dynamic> json) {
    return EquityTotalMap(
      totalPostedNoClosing: json['totalPostedNoClosing'] == null
          ? null
          : TotalPostedNoClosing.fromJson(
              json['totalPostedNoClosing'] as Map<String, dynamic>),
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

  String toString() => "Equity Total:  "
      " totalBalance: ${totalBalance.all}"
      " totalPosted: ${totalPosted.all}";
}
