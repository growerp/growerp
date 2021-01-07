class BalanceByTimePeriod {
  double all;

  BalanceByTimePeriod({this.all});

  factory BalanceByTimePeriod.fromJson(Map<String, dynamic> json) {
    return BalanceByTimePeriod(
      all: json['ALL'] as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ALL': all,
    };
  }
}
