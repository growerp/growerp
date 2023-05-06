import 'package:freezed_annotation/freezed_annotation.dart';

part 'growerp_package_model.freezed.dart';
part 'growerp_package_model.g.dart';

@freezed
class GrowerpPackage with _$GrowerpPackage {
  factory GrowerpPackage({
    /// the package name
    required String name,

    /// source file location in the system
    required String fileLocation,

    /// the version from pub.dev
    required String pubVersion,

    /// the published date from pub.dev
    required DateTime pubDate,

    /// version from the pubspec.yaml
    required String version,

    /// flag to indicate need build_runner if installed package
    required bool buildRunner,
  }) = _GrowerpPackage;
  GrowerpPackage._();

  factory GrowerpPackage.fromJson(Map<String, Object?> json) =>
      _$GrowerpPackageFromJson(json);
}
