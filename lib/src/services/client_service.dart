import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class ClientService {
  ClientService({
    required AuthService authService,
    http.Client? client,
  })  : _authService = authService,
        _client = client ?? http.Client();

  final AuthService _authService;
  final http.Client _client;

  Future<List<PetSpecies>> getSpecies() async {
    final data = await _getList('/api/gestion/clientes/especies/');
    return data.map((item) => PetSpecies.fromJson(item)).toList();
  }

  Future<ClientProfile> getProfile() async {
    final response = await _send(
      method: 'GET',
      path: '/api/gestion/clientes/me/',
    );
    return ClientProfile.fromJson(_decode(response) as Map<String, dynamic>);
  }

  Future<ClientProfile> updateProfile(UpdateClientProfileRequest request) async {
    final response = await _send(
      method: 'PATCH',
      path: '/api/gestion/clientes/me/',
      body: request.toJson(),
    );
    return ClientProfile.fromJson(_decode(response) as Map<String, dynamic>);
  }

  Future<List<PetBreed>> getBreeds({int? speciesId}) async {
    final query = speciesId == null ? '' : '?especie=$speciesId';
    final data = await _getList('/api/gestion/clientes/razas/$query');
    return data.map((item) => PetBreed.fromJson(item)).toList();
  }

  Future<List<Pet>> getPets() async {
    final data = await _getList('/api/gestion/clientes/mascotas/');
    return data.map((item) => Pet.fromJson(item)).toList();
  }

  Future<void> createPet(CreatePetRequest request) async {
    await _send(
      method: 'POST',
      path: '/api/gestion/clientes/mascotas/',
      body: request.toJson(),
    );
  }

  Future<List<ServiceItem>> getServices() async {
    final data = await _getList('/api/gestion/servicios/');
    return data.map((item) => ServiceItem.fromJson(item)).toList();
  }

  Future<List<ServicePrice>> getPrices() async {
    final data = await _getList('/api/gestion/servicios/precios-servicio/');
    return data.map((item) => ServicePrice.fromJson(item)).toList();
  }

  Future<List<Appointment>> getAppointments() async {
    final data = await _getList('/api/gestion/servicios/citas/');
    return data.map((item) => Appointment.fromJson(item)).toList();
  }

  Future<void> createAppointment(AppointmentRequest request) async {
    await _send(
      method: 'POST',
      path: '/api/gestion/servicios/citas/',
      body: request.toJson(),
    );
  }

  Future<void> updateAppointment(int id, AppointmentRequest request) async {
    await _send(
      method: 'PATCH',
      path: '/api/gestion/servicios/citas/$id/',
      body: request.toJson(),
    );
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final response = await _send(method: 'GET', path: path);
    final decoded = _decode(response);

    if (decoded is List) {
      return decoded.cast<Map<String, dynamic>>();
    }

    if (decoded is Map<String, dynamic> && decoded['results'] is List) {
      return (decoded['results'] as List).cast<Map<String, dynamic>>();
    }

    return <Map<String, dynamic>>[];
  }

  Future<http.Response> _send({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    var headers = await _authService.authorizedHeaders();
    var response = await _request(method: method, path: path, headers: headers, body: body);

    if (response.statusCode == 401) {
      await _authService.refreshToken();
      headers = await _authService.authorizedHeaders();
      response = await _request(method: method, path: path, headers: headers, body: body);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ClientException(_extractErrorMessage(_decode(response)));
    }

    return response;
  }

  Future<http.Response> _request({
    required String method,
    required String path,
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) {
    final uri = Uri.parse('${_authService.baseUrl}$path');
    final encodedBody = body == null ? null : jsonEncode(body);

    switch (method) {
      case 'POST':
        return _client.post(uri, headers: headers, body: encodedBody);
      case 'PATCH':
        return _client.patch(uri, headers: headers, body: encodedBody);
      default:
        return _client.get(uri, headers: headers);
    }
  }

  Object _decode(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};
    return jsonDecode(response.body);
  }

  String _extractErrorMessage(Object data) {
    if (data is Map<String, dynamic>) {
      final detail = data['detail'] ?? data['error'];
      if (detail is String && detail.isNotEmpty) return detail;
      if (data.isNotEmpty) return data.values.first.toString();
    }
    return 'No se pudo completar la solicitud.';
  }
}

class PetSpecies {
  const PetSpecies({required this.id, required this.name});

  final int id;
  final String name;

  factory PetSpecies.fromJson(Map<String, dynamic> json) {
    return PetSpecies(
      id: json['id_especie'] as int,
      name: json['nombre'] as String,
    );
  }
}

class PetBreed {
  const PetBreed({required this.id, required this.name, required this.speciesId});

  final int id;
  final String name;
  final int speciesId;

  factory PetBreed.fromJson(Map<String, dynamic> json) {
    return PetBreed(
      id: json['id_raza'] as int,
      name: json['nombre'] as String,
      speciesId: json['especie'] as int,
    );
  }
}

class Pet {
  const Pet({
    required this.id,
    required this.name,
    required this.speciesName,
    this.breedName,
    this.sex,
  });

  final int id;
  final String name;
  final String speciesName;
  final String? breedName;
  final String? sex;

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id_mascota'] as int,
      name: json['nombre'] as String? ?? '',
      speciesName: json['especie_nombre'] as String? ?? 'Especie',
      breedName: json['raza_nombre'] as String?,
      sex: json['sexo'] as String?,
    );
  }
}

class CreatePetRequest {
  const CreatePetRequest({
    required this.name,
    required this.speciesId,
    this.breedId,
    this.sex,
    this.color,
    this.birthDate,
    this.size,
    this.weight,
    this.allergies,
    this.notes,
  });

  final String name;
  final int speciesId;
  final int? breedId;
  final String? sex;
  final String? color;
  final String? birthDate;
  final String? size;
  final String? weight;
  final String? allergies;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'nombre': name,
        'especie': speciesId,
        'raza': breedId,
        'sexo': sex,
        'color': color,
        'fecha_nac': birthDate,
        'tamano': size,
        'peso': weight,
        'alergias': allergies,
        'notas_generales': notes,
      };
}

class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.name,
    required this.active,
    required this.homeAvailable,
  });

  final int id;
  final String name;
  final bool active;
  final bool homeAvailable;

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id_servicio'] as int,
      name: json['nombre'] as String? ?? '',
      active: json['estado'] as bool? ?? false,
      homeAvailable: json['disponible_domicilio'] as bool? ?? false,
    );
  }
}

class ServicePrice {
  const ServicePrice({
    required this.id,
    required this.serviceId,
    required this.variation,
    required this.modality,
    required this.price,
    required this.active,
  });

  final int id;
  final int serviceId;
  final String variation;
  final String modality;
  final String price;
  final bool active;

  factory ServicePrice.fromJson(Map<String, dynamic> json) {
    return ServicePrice(
      id: json['id_precio'] as int,
      serviceId: json['servicio'] as int,
      variation: json['variacion'] as String? ?? '',
      modality: json['modalidad'] as String? ?? 'CLINICA',
      price: json['precio'].toString(),
      active: json['estado'] as bool? ?? false,
    );
  }
}

class Appointment {
  const Appointment({
    required this.id,
    required this.petId,
    required this.serviceId,
    required this.priceId,
    required this.petName,
    required this.serviceName,
    required this.date,
    required this.time,
    required this.modality,
    required this.status,
    this.address,
    this.description,
  });

  final int id;
  final int petId;
  final int serviceId;
  final int priceId;
  final String petName;
  final String serviceName;
  final String date;
  final String time;
  final String modality;
  final String status;
  final String? address;
  final String? description;

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id_cita'] as int,
      petId: json['mascota'] as int,
      serviceId: json['servicio'] as int,
      priceId: json['precio_servicio'] as int,
      petName: json['mascota_nombre'] as String? ?? 'Mascota',
      serviceName: json['servicio_nombre'] as String? ?? 'Servicio',
      date: json['fecha_programada'] as String? ?? '',
      time: _shortTime(json['hora_inicio'] as String?),
      modality: json['modalidad'] as String? ?? 'CLINICA',
      status: json['estado'] as String? ?? 'PENDIENTE',
      address: json['direccion_cita'] as String?,
      description: json['descripcion'] as String?,
    );
  }
}

String _shortTime(String? value) {
  if (value == null || value.isEmpty) return '';
  return value.length >= 5 ? value.substring(0, 5) : value;
}

class ClientProfile {
  const ClientProfile({
    required this.id,
    required this.userId,
    required this.email,
    required this.name,
    this.phone,
    this.address,
    required this.active,
  });

  final int id;
  final int userId;
  final String email;
  final String name;
  final String? phone;
  final String? address;
  final bool active;

  factory ClientProfile.fromJson(Map<String, dynamic> json) {
    return ClientProfile(
      id: json['id_perfil'] as int,
      userId: json['usuario'] as int,
      email: json['correo'] as String? ?? '',
      name: json['nombre'] as String? ?? '',
      phone: json['telefono'] as String?,
      address: json['direccion'] as String?,
      active: json['estado'] as bool? ?? false,
    );
  }
}

class UpdateClientProfileRequest {
  const UpdateClientProfileRequest({
    required this.name,
    this.phone,
    this.address,
  });

  final String name;
  final String? phone;
  final String? address;

  Map<String, dynamic> toJson() => {
        'nombre': name,
        'telefono': phone,
        'direccion': address,
      };
}

class AppointmentRequest {
  const AppointmentRequest({
    required this.petId,
    required this.serviceId,
    required this.priceId,
    required this.date,
    required this.time,
    required this.modality,
    this.address,
    this.description,
  });

  final int petId;
  final int serviceId;
  final int priceId;
  final String date;
  final String time;
  final String modality;
  final String? address;
  final String? description;

  Map<String, dynamic> toJson() => {
        'mascota': petId,
        'servicio': serviceId,
        'precio_servicio': priceId,
        'fecha_programada': date,
        'hora_inicio': time,
        'modalidad': modality,
        'direccion_cita': modality == 'DOMICILIO' ? address : null,
        'descripcion': description,
      };
}

class ClientException implements Exception {
  const ClientException(this.message);

  final String message;

  @override
  String toString() => message;
}
