class TotalPosted {
  double all;

  TotalPosted({this.all});

  factory TotalPosted.fromJson(Map<String, dynamic> json) {
    return TotalPosted(
      all: json['ALL'] as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ALL': all,
    };
  }
}
