# Flutter-Moqui REST Backend Interface: A Complete Guide

This guide explains how Flutter applications communicate with the Moqui backend through REST APIs, with practical code examples and references to the actual GrowERP codebase.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [REST API Fundamentals](#rest-api-fundamentals)
3. [Authentication & Authorization](#authentication--authorization)
4. [Request/Response Patterns](#requestresponse-patterns)
5. [Error Handling](#error-handling)
6. [Practical Examples](#practical-examples)
7. [Data Models](#data-models)
8. [Best Practices](#best-practices)

---

## Architecture Overview

### High-Level Communication Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Application                      │
│  (Flutter Bloc/Provider sends HTTP requests via Retrofit)  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ HTTP/HTTPS Requests
                     │ (JSON payloads)
                     ↓
┌─────────────────────────────────────────────────────────────┐
│                   Moqui Backend Server                       │
│  (Receives requests → Executes services → Returns JSON)    │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ HTTP/HTTPS Responses
                     │ (JSON payloads)
                     ↓
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Application                      │
│  (BLoC/Provider processes response → Updates UI)           │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

**Flutter Side:**
- **Retrofit Client**: Type-safe HTTP client for making REST calls
- **BLoC/Provider**: State management layer that calls the API client
- **Data Models**: Dart classes representing backend entities

**Moqui Side:**
- **REST Endpoints**: Service definitions that expose business logic
- **Services**: XML-defined business operations
- **Entities**: Data models stored in the database
- **JSON Serialization**: Automatic conversion between Java objects and JSON

---

## REST API Fundamentals

### Base URL Structure

The base URL for API calls depends on your environment:

```
Development:  http://localhost:8080
Cloud:        https://admin.growerp.org
Custom:       https://your-domain.com
```

Endpoints follow the Moqui REST pattern: `/rest/s1/{app}/{version}/{entity}`

Example full URLs:
```
http://localhost:8080/rest/s1/growerp/100/RestRequest
http://localhost:8080/rest/s1/growerp/100/Product
http://localhost:8080/rest/s1/growerp/100/Order
```

### HTTP Methods

| Method | Purpose | Example |
|--------|---------|---------|
| GET | Retrieve data | Get all products |
| POST | Create or execute | Create a new order |
| PUT | Update entire resource | Update product details |
| PATCH | Partial update | Update order status |
| DELETE | Remove resource | Delete a product |

### Common Endpoints

```
GET    /rest/s1/growerp/100/Product                    # List all products
GET    /rest/s1/growerp/100/Product/{id}               # Get specific product
POST   /rest/s1/growerp/100/Product                    # Create new product
PUT    /rest/s1/growerp/100/Product/{id}               # Update product
DELETE /rest/s1/growerp/100/Product/{id}               # Delete product

GET    /rest/s1/growerp/100/Order                      # List orders
POST   /rest/s1/growerp/100/Order                      # Create order
GET    /rest/s1/growerp/100/Order/{id}                 # Get order details

POST   /rest/s1/growerp/100/User                       # User authentication
GET    /rest/s1/growerp/100/Company                    # List companies
```

---

## Authentication & Authorization

### JWT Token Flow

1. User logs in with credentials
2. Backend returns `moquiSessionToken` 
3. Token is stored locally on device
4. Token is included in Authorization header for subsequent requests
5. Backend validates token before processing requests

### Login Request (Flutter Side)

**Reference**: [growerp_models - AuthRepository](https://github.com/growerp/growerp/blob/master/flutter/packages/growerp_models/lib/src/rest/api_client.dart)

```dart
// Flutter code - making a login request
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';

@RestApi()
abstract class AuthClient {
  factory AuthClient(Dio dio, {String baseUrl}) = _AuthClient;

  @post('/authentication/login')
  Future<AuthenticateResponse> login(
    @Body() AuthenticateRequest request,
  );
}

// Usage in BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final response = await authClient.login(
        AuthenticateRequest(
          username: event.username,
          password: event.password,
        ),
      );
      
      // Save moquiSessionToken
      await secureStorage.write(key: 'moquiSessionToken', value: response.moquiSessionToken);
      
      emit(AuthSuccess(response));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}
```

### Moqui Service Definition (Backend)

**Reference**: [Moqui REST Service Definition](https://github.com/growerp/growerp/blob/master/moqui/runtime/component/growerp/service/growerp.rest.xml)

All REST endpoints are defined in `*.rest.xml` files. Example from `growerp.rest.xml`:

```xml
<!-- File: moqui/runtime/component/growerp/service/growerp.rest.xml -->
<resource uri="/User/Authenticate" method="post" auth="false">
    <description>Authenticate user with credentials</description>
    <service name="org.growerp.user.authenticate" method="post"/>
</resource>

<resource uri="/Product" method="get" auth="true">
    <description>Get list of products with pagination</description>
    <service name="org.growerp.product.getList" method="get"/>
</resource>

<resource uri="/Product" method="post" auth="true">
    <description>Create new product</description>
    <service name="org.growerp.product.create" method="post"/>
</resource>

<resource uri="/Order" method="post" auth="true">
    <description>Create new order</description>
    <service name="org.growerp.order.create" method="post"/>
</resource>
```

### Token Inclusion in Requests

```dart
// Interceptor that adds moquiSessionToken to every request
class TokenInterceptor extends Interceptor {
  final SecureStorage secureStorage;

  TokenInterceptor(this.secureStorage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await secureStorage.read(key: 'moquiSessionToken');
    
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    handler.next(options);
  }
}

// Configure Dio with interceptor
final dio = Dio();
dio.interceptors.add(TokenInterceptor(secureStorage));
```

---

## Request/Response Patterns

### Standard Request Format

```json
{
  "id": "optional-resource-id",
  "filters": [
    {
      "key": "status",
      "value": "ACTIVE"
    }
  ],
  "search": {
    "key": "name",
    "value": "Search term"
  },
  "pageSize": 20,
  "pageNumber": 1,
  "orderBy": "createdDate DESC"
}
```

### Standard Response Format

```json
{
  "data": [
    {
      "id": "123",
      "name": "Product Name",
      "description": "Product description",
      "price": 99.99,
      "createdDate": "2024-01-15T10:30:00Z"
    }
  ],
  "pageSize": 20,
  "pageNumber": 1,
  "total": 150,
  "errors": null
}
```

### Error Response Format

```json
{
  "error": true,
  "message": "Validation error",
  "errors": [
    {
      "field": "email",
      "message": "Email is required"
    },
    {
      "field": "price",
      "message": "Price must be greater than 0"
    }
  ]
}
```

---

## Error Handling

### HTTP Status Codes

| Code | Meaning | Handling |
|------|---------|----------|
| 200 | Success | Process response normally |
| 201 | Created | Resource created successfully |
| 204 | No Content | Operation succeeded, no response body |
| 400 | Bad Request | Validation errors in request |
| 401 | Unauthorized | Invalid or expired token |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource does not exist |
| 500 | Server Error | Backend error occurred |

### Error Handling in Flutter

**Reference**: [growerp_core - DioException handling](https://github.com/growerp/growerp/blob/master/flutter/packages/growerp_core/lib/src/bloc/data_fetch_bloc.dart)

```dart
Future<void> fetchProducts() async {
  try {
    final response = await productClient.getProducts(
      PageRequest(pageSize: 20, pageNumber: 1),
    );
    
    emit(ProductsLoaded(response.data));
  } on DioException catch (e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        emit(ProductsError('Connection timeout'));
        break;
      case DioExceptionType.badResponse:
        // Server returned error status
        final errorData = e.response?.data;
        emit(ProductsError(errorData['message'] ?? 'Unknown error'));
        break;
      case DioExceptionType.unknown:
        emit(ProductsError('Network error'));
        break;
      default:
        emit(ProductsError('An error occurred'));
    }
  }
}
```

### Moqui Service Error Response

```groovy
// Groovy service in Moqui
import org.moqui.entity.EntityList
import org.moqui.entity.EntityValue

Map validateProductData(Map productData) {
    def errors = []
    
    if (!productData.name) {
        errors.add([field: 'name', message: 'Product name is required'])
    }
    
    if (!productData.price || productData.price <= 0) {
        errors.add([field: 'price', message: 'Price must be greater than 0'])
    }
    
    if (errors) {
        return [error: true, errors: errors]
    }
    
    return [error: false]
}
```

---

## Practical Examples

### Example 1: Fetching a List of Products

**Flutter Client Definition**:

```dart
// File: growerp_models/lib/src/rest/product_api_client.dart
@RestApi()
abstract class ProductApiClient {
  factory ProductApiClient(Dio dio, {String baseUrl}) = _ProductApiClient;

  @get('/products')
  Future<ProductListResponse> getProducts(
    @Queries() Map<String, dynamic> query,
  );

  @get('/products/{id}')
  Future<Product> getProduct(@Path('id') String productId);

  @post('/products')
  Future<Product> createProduct(@Body() Product product);
}
```

**Moqui Endpoint**:

```xml
<!-- File: moqui/runtime/component/growerp/service/growerp.rest.xml -->
<resource uri="/Product" method="get" auth="true">
    <description>Get list of products with pagination and search</description>
    <service name="org.growerp.product.getList" method="get">
        <in-parameter name="pageSize" type="integer" default="20"/>
        <in-parameter name="pageNumber" type="integer" default="1"/>
        <in-parameter name="searchKey" type="string"/>
    </service>
</resource>
```

**Usage in BLoC**:

```dart
// File: growerp_catalog/lib/src/bloc/product_bloc.dart
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository productRepository;

  ProductBloc({required this.productRepository})
      : super(ProductInitial()) {
    on<FetchProducts>(_onFetchProducts);
  }

  Future<void> _onFetchProducts(
    FetchProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    
    try {
      final products = await productRepository.getProducts(
        pageSize: 20,
        pageNumber: event.pageNumber,
        searchKey: event.searchKey,
      );
      
      emit(ProductLoaded(products));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }
}
```

### Example 2: Creating an Order

**Flutter Request**:

```dart
// BLoC event and handling
class CreateOrderRequested extends OrderEvent {
  final List<OrderItem> items;
  final String customerId;
  
  CreateOrderRequested({
    required this.items,
    required this.customerId,
  });
}

// BLoC method
Future<void> _onCreateOrder(
  CreateOrderRequested event,
  Emitter<OrderState> emit,
) async {
  try {
    final order = Order(
      customerId: event.customerId,
      items: event.items,
      status: 'DRAFT',
      createdDate: DateTime.now(),
    );
    
    final response = await orderClient.createOrder(order);
    emit(OrderCreated(response));
  } catch (e) {
    emit(OrderError(e.toString()));
  }
}
```

**Moqui Service**:

```groovy
// File: moqui/runtime/component/growerp/service/growerp.rest.xml defines the endpoint
// The actual service implementation is referenced from that definition

// Service implementation in corresponding Groovy file:
class OrderServices {
    def createOrder(Map orderData) {
        def ec = ec()
        def result = [:]
        
        ec.transaction.begin()
        try {
            // Validate order
            def validation = validateOrderData(orderData)
            if (validation.error) {
                return [error: true, errors: validation.errors]
            }
            
            // Create order header
            def order = ec.entity.makeValue('Order', [
                orderId: ec.id.sequenceNextSeqNum('Order'),
                partyId: orderData.customerId,
                orderStatus: 'DRAFT',
                createdDate: new Date()
            ]).create()
            
            // Create order items
            orderData.items?.each { item ->
                ec.entity.makeValue('OrderItem', [
                    orderId: order.orderId,
                    itemSeqId: String.format('%05d', orderData.items.indexOf(item) + 1),
                    productId: item.productId,
                    quantity: item.quantity,
                    price: item.price
                ]).create()
            }
            
            result.orderId = order.orderId
            result.error = false
            
            ec.transaction.commit()
        } catch (Exception e) {
            ec.transaction.rollback()
            result.error = true
            result.message = e.message
        }
        
        return result
    }
}
```

### Example 3: Authentication Flow

**Flutter Login Process**:

```dart
class AuthRepository {
  final AuthApiClient apiClient;
  final SecureStorage secureStorage;

  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await apiClient.login(
        AuthenticateRequest(
          username: username,
          password: password,
        ),
      );
      
      // Save moquiSessionToken securely
      await secureStorage.write(
        key: 'moquiSessionToken',
        value: response.moquiSessionToken,
      );
      
      // Save user info
      await secureStorage.write(
        key: 'user_info',
        value: jsonEncode(response.user),
      );
      
      return response;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw UnauthorizedException('Invalid credentials');
      }
      rethrow;
    }
  }
}
```

**Moqui Authentication Service**:

```xml
<!-- File: moqui/runtime/component/growerp/service/growerp.rest.xml -->
<resource uri="/User/Authenticate" method="post" auth="false">
    <description>Authenticate user and return moquiSessionToken</description>
    <service name="org.growerp.user.authenticate" method="post">
        <in-parameter name="username" type="string" required="true"/>
        <in-parameter name="password" type="string" required="true"/>
    </service>
</resource>
```

The actual service implementation handles the authentication logic and returns the `moquiSessionToken`.

---

## Data Models

### Request/Response Models

**Flutter Data Models** (Generated by `build_runner`):

```dart
// File: growerp_models/lib/src/models/product_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

@JsonSerializable()
class Product {
  @JsonKey(name: 'productId')
  final String id;
  
  final String name;
  final String description;
  final double price;
  final int quantity;
  
  @JsonKey(name: 'createdDate')
  final DateTime createdDate;
  
  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.createdDate,
  });

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);

  Map<String, dynamic> toJson() => _$ProductToJson(this);
}

@JsonSerializable()
class ProductListResponse {
  final List<Product> data;
  final int total;
  final int pageSize;
  final int pageNumber;

  ProductListResponse({
    required this.data,
    required this.total,
    required this.pageSize,
    required this.pageNumber,
  });

  factory ProductListResponse.fromJson(Map<String, dynamic> json) =>
      _$ProductListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ProductListResponseToJson(this);
}
```

**Moqui Entity Definition**:

```xml
<!-- File: moqui/runtime/component/growerp/entity/ProductEntities.xml -->
<entity entity-name="Product" package-name="org.growerp.entity">
    <field name="productId" type="id" is-pk="true"/>
    <field name="name" type="text-medium"/>
    <field name="description" type="text-long"/>
    <field name="price" type="currency-amount"/>
    <field name="quantity" type="number-integer"/>
    <field name="createdDate" type="date-time"/>
    <field name="updatedDate" type="date-time"/>
    
    <relationship type="one" related-entity-name="Category"/>
    <relationship type="many" related-entity-name="ProductImage"/>
</entity>
```

---

## Best Practices

### 1. Connection Management

```dart
// Use connection pooling and proper timeout management
final dio = Dio(
  BaseOptions(
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 30),
    sendTimeout: Duration(seconds: 30),
  ),
);

// Connection pooling is handled by Dio automatically
```

### 2. Request Optimization

```dart
// Use pagination for large datasets
Future<List<Product>> getProducts({
  int pageSize = 20,
  int pageNumber = 1,
  String? searchKey,
}) async {
  return await productClient.getProducts({
    'pageSize': pageSize,
    'pageNumber': pageNumber,
    if (searchKey != null) 'searchKey': searchKey,
  });
}
```

### 3. Response Caching

```dart
// Cache responses to reduce server load
class CachedProductRepository {
  final Map<String, CacheEntry> _cache = {};

  Future<List<Product>> getProducts({
    required int pageNumber,
    Duration cacheDuration = const Duration(minutes: 5),
  }) async {
    final key = 'products_page_$pageNumber';
    
    if (_cache.containsKey(key) && !_cache[key]!.isExpired) {
      return _cache[key]!.data;
    }

    final products = await productClient.getProducts({
      'pageNumber': pageNumber,
    });

    _cache[key] = CacheEntry(
      data: products,
      expiresAt: DateTime.now().add(cacheDuration),
    );

    return products;
  }
}
```

### 4. Retry Logic

```dart
// Implement retry logic for failed requests
Future<T> withRetry<T>(
  Future<T> Function() request, {
  int maxRetries = 3,
  Duration delay = const Duration(seconds: 1),
}) async {
  for (int i = 0; i < maxRetries; i++) {
    try {
      return await request();
    } on DioException catch (e) {
      if (i == maxRetries - 1 || !_isRetryable(e)) {
        rethrow;
      }
      await Future.delayed(delay * (i + 1));
    }
  }
  throw Exception('Request failed after $maxRetries retries');
}

bool _isRetryable(DioException e) {
  // Retry on network errors, timeout, 5xx errors
  return e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      (e.response?.statusCode ?? 0) >= 500;
}
```

### 5. Security Best Practices

```dart
// Never store sensitive data in plain text
class SecureAuthStorage {
  final FlutterSecureStorage _storage;

  Future<void> saveMoquiSessionToken(String token) async {
    await _storage.write(
      key: 'moquiSessionToken',
      value: token,
      aOptions: AndroidOptions(
        keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1,
      ),
    );
  }

  Future<String?> getMoquiSessionToken() async {
    return await _storage.read(key: 'moquiSessionToken');
  }

  Future<void> deleteMoquiSessionToken() async {
    await _storage.delete(key: 'moquiSessionToken');
  }
}

// Use HTTPS in production
final dio = Dio(
  BaseOptions(
    baseUrl: 'https://api.growerp.com',  // HTTPS only
  ),
);
```

---

## References

- [Moqui Framework Documentation](https://www.moqui.org/)
- [Retrofit Package](https://pub.dev/packages/retrofit)
- [Dio HTTP Client](https://pub.dev/packages/dio)
- [Flutter BLoC Pattern](https://bloclibrary.dev/)
- [GrowERP GitHub Repository](https://github.com/growerp/growerp)
- [REST API Best Practices](https://restfulapi.net/)

---

## Related Documentation

- [Basic Explanation of Frontend-REST Backend Data Models](./basic_explanation_of_the_frontend_REST_Backend_data_models.md)
- [GrowERP Design Patterns](./GrowERP_Design_Patterns.md)
- [Backend Components Development Guide](./Backend_Components_Development_Guide.md)
- [Building Blocks Development Guide](./Building_Blocks_Development_Guide.md)
