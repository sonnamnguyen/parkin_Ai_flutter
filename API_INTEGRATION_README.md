# API Integration Documentation

This document describes the API integration for the ParkinAI Flutter application.

## Overview

The API integration includes:
- Authentication (Login/Register)
- Vehicle Management (CRUD operations)
- Token-based authentication with automatic token management
- Error handling and response parsing

## API Endpoints

### Base URL
```
http://localhost:8000/backend/parkin/v1
```

### Authentication Endpoints

#### Login
- **URL**: `POST /login`
- **Auth**: No
- **Request Body**:
```json
{
  "account": "user@gmail.com",
  "password": "1234"
}
```
- **Response**:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "1hc9b201000dcnxza5ju8h2400e6rk4g",
  "user_id": 4,
  "username": "user",
  "role": "role_user",
  "wallet_balance": 0
}
```

#### Register
- **URL**: `POST /user/register`
- **Auth**: No
- **Request Body**:
```json
{
  "username": "user",
  "email": "user@gmail.com",
  "password": "1234",
  "phone": "01234567890",
  "full_name": "user",
  "gender": "male",
  "birth_date": "2000-01-01"
}
```

### Vehicle Endpoints

#### Get Vehicles
- **URL**: `GET /vehicles?type=car&page=1&page_size=10`
- **Auth**: Bearer Token required
- **Response**:
```json
{
  "list": [
    {
      "id": 12,
      "user_id": 4,
      "username": "user",
      "license_plate": "30A-22342",
      "brand": "Toyota",
      "model": "Camry",
      "color": "Black",
      "type": "car",
      "created_at": "2025-09-09 11:17:43"
    }
  ],
  "total": 1
}
```

#### Add Vehicle
- **URL**: `POST /vehicles`
- **Auth**: Bearer Token required
- **Request Body**:
```json
{
  "license_plate": "30A-22345",
  "brand": "Toyota",
  "model": "Camry",
  "color": "Black",
  "type": "car"
}
```

#### Get Vehicle Detail
- **URL**: `GET /vehicles/{id}`
- **Auth**: Bearer Token required

#### Update Vehicle
- **URL**: `PUT /vehicles/{id}`
- **Auth**: Bearer Token required

#### Delete Vehicle
- **URL**: `DELETE /vehicles/{id}`
- **Auth**: Bearer Token required

## Services

### AuthService
Handles authentication operations:
- `login(LoginRequest request)` - User login
- `register(RegisterRequest request)` - User registration
- `logout()` - User logout
- `isLoggedIn()` - Check if user is logged in
- `getToken()` - Get stored access token
- `getUserData()` - Get stored user data

### VehicleService
Handles vehicle operations:
- `getVehicles({String? type, int page, int pageSize})` - Get vehicles with pagination
- `getVehicleDetail(int id)` - Get vehicle details
- `addVehicle(VehicleRequest request)` - Add new vehicle
- `updateVehicle(int id, VehicleRequest request)` - Update vehicle
- `deleteVehicle(int id)` - Delete vehicle

### StorageService
Handles local storage:
- `saveToken(String token)` - Save access token
- `getToken()` - Get access token
- `removeToken()` - Remove access token
- `saveUserData(String userData)` - Save user data
- `getUserData()` - Get user data
- `removeUserData()` - Remove user data

## Models

### Request Models
- `LoginRequest` - Login request data
- `RegisterRequest` - Registration request data
- `VehicleRequest` - Vehicle creation/update data

### Response Models
- `AuthResponse` - Authentication response data
- `Vehicle` - Vehicle data model
- `VehicleListResponse` - Paginated vehicle list response

## Usage Examples

### Login
```dart
final authService = AuthService();
final loginRequest = LoginRequest(
  account: "user@gmail.com",
  password: "1234",
);

try {
  final authResponse = await authService.login(loginRequest);
  print('Login successful: ${authResponse.username}');
} catch (e) {
  print('Login failed: $e');
}
```

### Get Vehicles
```dart
final vehicleService = VehicleService();

try {
  final vehicleListResponse = await vehicleService.getVehicles(
    type: "car",
    page: 1,
    pageSize: 10,
  );
  
  for (final vehicle in vehicleListResponse.list) {
    print('${vehicle.licensePlate} - ${vehicle.brand} ${vehicle.model}');
  }
} catch (e) {
  print('Failed to get vehicles: $e');
}
```

### Add Vehicle
```dart
final vehicleService = VehicleService();
final vehicleRequest = VehicleRequest(
  licensePlate: "30A-22345",
  brand: "Toyota",
  model: "Camry",
  color: "Black",
  type: "car",
);

try {
  final vehicle = await vehicleService.addVehicle(vehicleRequest);
  print('Vehicle added: ${vehicle.id}');
} catch (e) {
  print('Failed to add vehicle: $e');
}
```

## Error Handling

All services include comprehensive error handling:
- Network errors
- HTTP status code errors (400, 401, 403, 404, 422, 500)
- Validation errors
- Authentication errors

## Token Management

- Access tokens are automatically included in API requests
- Tokens are stored securely using SharedPreferences
- Automatic token refresh handling (when implemented)
- Automatic logout on token expiration

## Initialization

Make sure to initialize the services in your app:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize storage service
  await StorageService().initialize();
  
  // Initialize API client
  ApiClient().initialize();
  
  runApp(MyApp());
}
```

## Dependencies

The following packages are required:
- `dio: ^5.4.0` - HTTP client
- `shared_preferences: ^2.2.2` - Local storage

## Notes

- All API calls are asynchronous
- Bearer token authentication is handled automatically
- Error messages are user-friendly
- The API client includes request/response logging for debugging
