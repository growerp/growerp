class TotalBalanceByTimePeriod {
  double all;

  TotalBalanceByTimePeriod({this.all});

  factory TotalBalanceByTimePeriod.fromJson(Map<String, dynamic> json) {
    return TotalBalanceByTimePeriod(
      all: json['ALL'] as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ALL': all,
    };
  }
}
