class TotalPostedNoClosingByTimePeriod {
  double all;

  TotalPostedNoClosingByTimePeriod({this.all});

  factory TotalPostedNoClosingByTimePeriod.fromJson(Map<String, dynamic> json) {
    return TotalPostedNoClosingByTimePeriod(
      all: json['ALL'] as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ALL': all,
    };
  }
}
