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

  List<GlAccount> toList() => this.glAccounts.toList();
}

@freezed
class Categories with _$Categories {
  factory Categories({
    @Default(const []) List<Category> categories,
  }) = _Categories;
  Categories._();

  factory Categories.fromJson(Map<String, dynamic> json) =>
      _$CategoriesFromJson(json);

  List<Category> toList() => this.categories.toList();
}

@freezed
class Products with _$Products {
  factory Products({
    @Default(const []) List<Product> products,
  }) = _Products;
  Products._();

  factory Products.fromJson(Map<String, dynamic> json) =>
      _$ProductsFromJson(json);
  List<Product> toList() => this.products.toList();
}

@freezed
class Users with _$Users {
  factory Users({
    @Default(const []) List<User> users,
  }) = _Users;
  Users._();

  factory Users.fromJson(Map<String, dynamic> json) => _$UsersFromJson(json);

  List<User> toList() => this.users.toList();
}

@freezed
class Companies with _$Companies {
  factory Companies({
    @Default(const []) List<Company> companies,
  }) = _Companies;
  Companies._();

  factory Companies.fromJson(Map<String, dynamic> json) =>
      _$CompaniesFromJson(json);
  List<Company> toList() => this.companies.toList();
}
