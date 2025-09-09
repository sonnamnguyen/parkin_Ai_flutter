// This file demonstrates how to use the API services
// You can delete this file after understanding the usage

import '../services/auth_service.dart';
import '../services/vehicle_service.dart';
import '../services/storage_service.dart';
import '../../data/models/login_request_model.dart';
import '../../data/models/register_request_model.dart';
import '../../data/models/vehicle_request_model.dart';

class ApiUsageExample {
  final AuthService _authService = AuthService();
  final VehicleService _vehicleService = VehicleService();
  final StorageService _storageService = StorageService();

  // Initialize services
  Future<void> initialize() async {
    await _storageService.initialize();
  }

  // Example: User Login
  Future<void> loginExample() async {
    try {
      final loginRequest = LoginRequest(
        account: "user@gmail.com",
        password: "1234",
      );

      final authResponse = await _authService.login(loginRequest);
      
      print('Login successful!');
      print('User ID: ${authResponse.userId}');
      print('Username: ${authResponse.username}');
      print('Role: ${authResponse.role}');
      print('Wallet Balance: ${authResponse.walletBalance}');
      
    } catch (e) {
      print('Login failed: $e');
    }
  }

  // Example: User Registration
  Future<void> registerExample() async {
    try {
      final registerRequest = RegisterRequest(
        username: "newuser",
        email: "newuser@gmail.com",
        password: "1234",
        phone: "01234567890",
        fullName: "New User",
        gender: "male",
        birthDate: "2000-01-01",
      );

      final authResponse = await _authService.register(registerRequest);
      
      print('Registration successful!');
      print('User ID: ${authResponse.userId}');
      print('Username: ${authResponse.username}');
      
    } catch (e) {
      print('Registration failed: $e');
    }
  }

  // Example: Get Vehicles
  Future<void> getVehiclesExample() async {
    try {
      final vehicleListResponse = await _vehicleService.getVehicles(
        type: "car",
        page: 1,
        pageSize: 10,
      );

      print('Total vehicles: ${vehicleListResponse.total}');
      for (final vehicle in vehicleListResponse.list) {
        print('Vehicle: ${vehicle.licensePlate} - ${vehicle.brand} ${vehicle.model}');
      }
      
    } catch (e) {
      print('Failed to get vehicles: $e');
    }
  }

  // Example: Add Vehicle
  Future<void> addVehicleExample() async {
    try {
      final vehicleRequest = VehicleRequest(
        licensePlate: "30A-22345",
        brand: "Toyota",
        model: "Camry",
        color: "Black",
        type: "car",
      );

      final vehicle = await _vehicleService.addVehicle(vehicleRequest);
      
      print('Vehicle added successfully!');
      print('Vehicle ID: ${vehicle.id}');
      print('License Plate: ${vehicle.licensePlate}');
      
    } catch (e) {
      print('Failed to add vehicle: $e');
    }
  }

  // Example: Update Vehicle
  Future<void> updateVehicleExample(int vehicleId) async {
    try {
      final vehicleRequest = VehicleRequest(
        licensePlate: "30A-22345",
        brand: "Toyota",
        model: "Camry",
        color: "White", // Changed color
        type: "car",
      );

      final vehicle = await _vehicleService.updateVehicle(vehicleId, vehicleRequest);
      
      print('Vehicle updated successfully!');
      print('New color: ${vehicle.color}');
      
    } catch (e) {
      print('Failed to update vehicle: $e');
    }
  }

  // Example: Delete Vehicle
  Future<void> deleteVehicleExample(int vehicleId) async {
    try {
      await _vehicleService.deleteVehicle(vehicleId);
      
      print('Vehicle deleted successfully!');
      
    } catch (e) {
      print('Failed to delete vehicle: $e');
    }
  }

  // Example: Get Vehicle Detail
  Future<void> getVehicleDetailExample(int vehicleId) async {
    try {
      final vehicle = await _vehicleService.getVehicleDetail(vehicleId);
      
      print('Vehicle Detail:');
      print('ID: ${vehicle.id}');
      print('License Plate: ${vehicle.licensePlate}');
      print('Brand: ${vehicle.brand}');
      print('Model: ${vehicle.model}');
      print('Color: ${vehicle.color}');
      print('Type: ${vehicle.type}');
      print('Created At: ${vehicle.createdAt}');
      
    } catch (e) {
      print('Failed to get vehicle detail: $e');
    }
  }

  // Example: Check if user is logged in
  bool isUserLoggedIn() {
    return _authService.isLoggedIn();
  }

  // Example: Logout
  Future<void> logoutExample() async {
    try {
      await _authService.logout();
      print('Logout successful!');
    } catch (e) {
      print('Logout failed: $e');
    }
  }
}
