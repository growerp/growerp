class TotalPostedByTimePeriod {
  double all;

  TotalPostedByTimePeriod({this.all});

  factory TotalPostedByTimePeriod.fromJson(Map<String, dynamic> json) {
    return TotalPostedByTimePeriod(
      all: json['ALL'] as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ALL': all,
    };
  }
}
