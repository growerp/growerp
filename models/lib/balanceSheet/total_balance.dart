class TotalBalance {
  double all;

  TotalBalance({this.all});

  factory TotalBalance.fromJson(Map<String, dynamic> json) {
    return TotalBalance(
      all: json['ALL'] as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ALL': all,
    };
  }
}
