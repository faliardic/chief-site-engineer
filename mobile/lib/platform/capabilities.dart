enum DeviceCapability { notification, camera, photoLibrary, filePicker, export }

enum CapabilityStatus { granted, denied, unavailable }

abstract interface class PermissionGateway {
  Future<CapabilityStatus> request(DeviceCapability capability);
}

class SafeCapabilityService {
  const SafeCapabilityService(this.gateway);

  final PermissionGateway gateway;

  Future<CapabilityStatus> request(DeviceCapability capability) async {
    try {
      return await gateway.request(capability);
    } on Object {
      return CapabilityStatus.unavailable;
    }
  }
}
