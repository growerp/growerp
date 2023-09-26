/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'dart:convert';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_rest/growerp_rest.dart';

class CatalogAPIRepository extends APIRepository {
  CatalogAPIRepository(super.apiKey);

  Future<ApiResult<List<Product>>> getProduct(
      {int? start,
      int? limit,
      String? companyPartyId,
      String? categoryId,
      String? productId,
      String? productTypeId,
      String? assetClassId,
      String? filter,
      String? searchString}) async {
    try {
      final response = await dioClient.get(
          'rest/s1/growerp/100/Products', apiKey,
          queryParameters: <String, dynamic>{
            'classificationId': classificationId,
            'companyPartyId': companyPartyId,
            'categoryId': categoryId,
            'productId': productId,
            'productTypeId': productTypeId,
            'assetClassId': assetClassId,
            'start': start,
            'limit': limit,
            'filter': filter,
            'search': searchString
          });
      return getResponseList<Product>(
          "products", response, (json) => Product.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<Product>> createProduct(Product product) async {
    // no productId is add
    try {
      final response = await dioClient
          .post('rest/s1/growerp/100/Product', apiKey!, data: <String, dynamic>{
        'product': jsonEncode(product.toJson()),
        'classificationId': classificationId,
        'moquiSessionToken': sessionToken
      });
      return getResponse<Product>(
          "product", response, (json) => Product.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<Product>> updateProduct(Product product) async {
    // no productId is add
    try {
      final response = await dioClient.patch(
          'rest/s1/growerp/100/Product', apiKey!,
          data: <String, dynamic>{
            'product': jsonEncode(product.toJson()),
            'classificationId': classificationId,
            'moquiSessionToken': sessionToken
          });
      return getResponse<Product>(
          "product", response, (json) => Product.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<Product>> deleteProduct(Product product) async {
    try {
      final response = await dioClient.delete(
          'rest/s1/growerp/100/Product', apiKey!,
          queryParameters: <String, dynamic>{
            'product': jsonEncode(product.toJson()),
          });
      return getResponse<Product>(
          "product", response, (json) => Product.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<String>> importProducts(List<Product> products) async {
    try {
      final response = await dioClient.post(
          'rest/s1/growerp/100/ImportExport', apiKey!,
          data: <String, dynamic>{
            'products': 'jsonEncode(products.map((x) => x.toJson()).toList())',
            'classificationId': classificationId,
            'moquiSessionToken': sessionToken
          });
      return ApiResult.success(
          data: jsonDecode(response.toString())['messages'] ?? 'no result');
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<String>> exportProducts() async {
    try {
      final response = await dioClient.get(
          'rest/s1/growerp/100/ImportExport', apiKey,
          queryParameters: <String, dynamic>{
            'entityName': 'Product',
            'classificationId': classificationId,
          });
      return ApiResult.success(
          data: jsonDecode(response.toString())['messages'] ?? 'no result');
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<List<Asset>>> getAsset(
      {int? start,
      int? limit,
      String? companyPartyId,
      String? assetClassId,
      String? assetId,
      String? productId,
      String? filter,
      String? searchString}) async {
    try {
      final response = await dioClient.get('rest/s1/growerp/100/Asset', apiKey!,
          queryParameters: <String, dynamic>{
            'companyPartyId': companyPartyId,
            'assetId': assetId,
            'assetClassId': assetClassId,
            'productId': productId,
            'start': start,
            'limit': limit,
            'filter': filter,
            'search': searchString
          });
      return getResponseList<Asset>(
          "assets", response, (json) => Asset.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<Asset>> createAsset(Asset asset) async {
    try {
      final response = await dioClient
          .post('rest/s1/growerp/100/Asset', apiKey!, data: <String, dynamic>{
        'asset': jsonEncode(asset.toJson()),
        'classificationId': classificationId,
        'moquiSessionToken': sessionToken
      });
      return getResponse<Asset>(
          "asset", response, (json) => Asset.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<Asset>> updateAsset(Asset asset) async {
    try {
      final response = await dioClient.patch(
          'rest/s1/growerp/100/Asset', apiKey!, data: <String, dynamic>{
        'asset': jsonEncode(asset.toJson()),
        'moquiSessionToken': sessionToken
      });
      return getResponse<Asset>(
          "asset", response, (json) => Asset.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<Asset>> deleteAsset(Asset asset) async {
    try {
      final response = await dioClient.delete(
          'rest/s1/growerp/100/Asset', apiKey!,
          queryParameters: <String, dynamic>{
            'asset': jsonEncode(asset.toJson()),
          });
      return getResponse<Asset>(
          "asset", response, (json) => Asset.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<List<Category>>> getCategory(
      {int? start,
      int? limit,
      String? companyPartyId,
      String? filter,
      String? searchString}) async {
    try {
      final response = await dioClient.get(
          'rest/s1/growerp/100/Categories', apiKey,
          queryParameters: <String, dynamic>{
            'start': start,
            'limit': limit,
            'companyPartyId': companyPartyId,
            'filter': filter,
            'search': searchString,
            'classificationId': classificationId,
          });
      return getResponseList<Category>(
          "categories", response, (json) => Category.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<String>> importCategories(List<Category> categories) async {
    try {
      final response = await dioClient.post(
          'rest/s1/growerp/100/ImportExport', apiKey!,
          data: <String, dynamic>{
            'categories':
                jsonEncode(categories.map((x) => x.toJson()).toList()),
            'classificationId': classificationId,
            'moquiSessionToken': sessionToken
          });
      return ApiResult.success(
          data: jsonDecode(response.toString())['messages'] ?? 'no result');
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<String>> exportCategories() async {
    try {
      final response = await dioClient.get(
          'rest/s1/growerp/100/ImportExport', apiKey,
          queryParameters: <String, dynamic>{
            'entityName': 'Category',
            'classificationId': classificationId,
          });
      return ApiResult.success(
          data: jsonDecode(response.toString())['messages'] ?? 'no result');
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<Category>> createCategory(Category category) async {
    // no categoryId is add
    try {
      final response = await dioClient.post(
          'rest/s1/growerp/100/Category', apiKey!,
          data: <String, dynamic>{
            'category': jsonEncode(category.toJson()),
            'classificationId': classificationId,
            'moquiSessionToken': sessionToken
          });
      return getResponse<Category>(
          "category", response, (json) => Category.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<Category>> updateCategory(Category category) async {
    try {
      final response = await dioClient.patch(
          'rest/s1/growerp/100/Category', apiKey!,
          data: <String, dynamic>{
            'category': jsonEncode(category.toJson()),
            'classificationId': classificationId,
            'moquiSessionToken': sessionToken
          });
      return getResponse<Category>(
          "category", response, (json) => Category.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<Category>> deleteCategory(Category category) async {
    try {
      final response = await dioClient.delete(
          'rest/s1/growerp/100/Category', apiKey!,
          queryParameters: <String, dynamic>{
            'category': jsonEncode(category.toJson()),
            'classificationId': classificationId,
            'moquiSessionToken': sessionToken
          });
      return getResponse<Category>(
          "category", response, (json) => Category.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<List<String>>> getRentalOccupancy(
      {required String productId}) async {
    try {
      final response = await dioClient.get(
          'rest/s1/growerp/100/RentalOccupancy', apiKey!,
          queryParameters: <String, dynamic>{
            'productId': productId,
          });
      var json = jsonDecode(response.toString())['rentalFullDates'];
      List<dynamic> list = List.from(json);
      List<String> stringList = [];
      // change members from dynamic to string
      for (String string in list) {
        stringList.add(string);
      }
      return ApiResult.success(data: stringList);
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<List<FullDatesProductRental>>>
      getRentalAllOccupancy() async {
    try {
      final response =
          await dioClient.get('rest/s1/growerp/100/RentalOccupancy', apiKey!);
      return getResponseList<FullDatesProductRental>("fullDatesProductRental",
          response, (json) => FullDatesProductRental.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }
}
