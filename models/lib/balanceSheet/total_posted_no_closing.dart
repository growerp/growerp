class TotalPostedNoClosing {
  double all;

  TotalPostedNoClosing({this.all});

  factory TotalPostedNoClosing.fromJson(Map<String, dynamic> json) {
    return TotalPostedNoClosing(
      all: json['ALL'] as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ALL': all,
    };
  }
}
