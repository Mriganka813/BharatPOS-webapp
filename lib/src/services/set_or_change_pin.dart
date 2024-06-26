import 'package:shopos/src/services/api_v1.dart';
import 'package:flutter/foundation.dart';
class PinService {
  // set pin
  Future<void> setPin(int pin) async {
    final response = await ApiV1Service.postRequest('/getpin', data: {
      'pin': pin,
    });
    if(kDebugMode)print(response.data);
  }

  // verify pin
  Future<bool> verifyPin(int pin) async {
    final response = await ApiV1Service.postRequest('/verifypin', data: {
      'pin': pin,
    });
    if(kDebugMode)print(response.data);
    bool status = response.data['success'];

    return status;
  }

  // change pin
  Future<void> changePin(int oldPin, int newPin) async {
    final response = await ApiV1Service.postRequest('/editpin', data: {
      'newPin': newPin,
      'oldPin': oldPin,
    });
    if(kDebugMode)print(response.data);
  }

  // delete pin
  Future<void> deletePin(int oldPin) async {
    final response = await ApiV1Service.postRequest('/deletepin', data: {
      'pin': oldPin,
    });
    if(kDebugMode)print(response.data);
  }

  // pin status = false(default)
  Future<bool> pinStatus() async {
    final response = await ApiV1Service.getRequest(
      '/pinstatus',
    );
    print("Pinstatus response = ${response.data}");
    bool status = false;
    try {
      status = response.data;
    } catch (e) {
      print("Error in pinstatus response = ${e}");
      status = response.data['status'];
    }

    return status;
  }
}
