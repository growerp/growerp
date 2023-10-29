import 'package:freezed_annotation/freezed_annotation.dart';

import 'models.dart';

part 'lists_model.g.dart';
part 'lists_model.freezed.dart';

@freezed
class GlAccounts with _$GlAccounts {
  factory GlAccounts({
    @Default(const []) List<GlAccount> glAccounts,
  }) = _GlAccounts;
  GlAccounts._();

  factory GlAccounts.fromJson(Map<String, dynamic> json) =>
      _$GlAccountsFromJson(json);
}

@freezed
class Categories with _$Categories {
  factory Categories({
    @Default(const []) List<Category> categories,
  }) = _Categories;
  Categories._();

  factory Categories.fromJson(Map<String, dynamic> json) =>
      _$CategoriesFromJson(json);
}

@freezed
class Products with _$Products {
  factory Products({
    @Default(const []) List<Product> products,
  }) = _Products;
  Products._();

  factory Products.fromJson(Map<String, dynamic> json) =>
      _$ProductsFromJson(json);
}

@freezed
class Assets with _$Assets {
  factory Assets({
    @Default(const []) List<Asset> assets,
  }) = _Assets;
  Assets._();

  factory Assets.fromJson(Map<String, dynamic> json) => _$AssetsFromJson(json);
}

@freezed
class Users with _$Users {
  factory Users({
    @Default(const []) List<User> users,
  }) = _Users;
  Users._();

  factory Users.fromJson(Map<String, dynamic> json) => _$UsersFromJson(json);
}

@freezed
class Companies with _$Companies {
  factory Companies({
    @Default(const []) List<Company> companies,
  }) = _Companies;
  Companies._();

  factory Companies.fromJson(Map<String, dynamic> json) =>
      _$CompaniesFromJson(json);
}
