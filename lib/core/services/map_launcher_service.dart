import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

/// Servicio para abrir ubicaciones en Google Maps App
class MapLauncherService {
  /// Abre Google Maps App con las coordenadas proporcionadas
  /// 
  /// [latitude] y [longitude] son las coordenadas del lugar
  /// [label] es el nombre opcional que se mostrará en el marcador
  static Future<bool> openMapsWithCoordinates({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    Uri url;
    
    if (Platform.isAndroid) {
      // Android: geo URI scheme
      final encodedLabel = label != null ? Uri.encodeComponent(label) : '';
      url = Uri.parse(
        'geo:$latitude,$longitude?q=$latitude,$longitude${encodedLabel.isNotEmpty ? '($encodedLabel)' : ''}',
      );
    } else if (Platform.isIOS) {
      // iOS: comgooglemaps URI scheme
      final encodedLabel = label != null ? '&label=${Uri.encodeComponent(label)}' : '';
      url = Uri.parse(
        'comgooglemaps://?q=$latitude,$longitude$encodedLabel',
      );
    } else {
      // Fallback for other platforms (web, desktop)
      url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );
    }

    if (await canLaunchUrl(url)) {
      return await launchUrl(url);
    }

    return false;
  }

  /// Abre Google Maps App con la dirección proporcionada
  /// 
  /// [address] es la dirección del lugar
  static Future<bool> openMapsWithAddress({
    required String address,
  }) async {
    final encodedAddress = Uri.encodeComponent(address);
    Uri url;

    if (Platform.isAndroid) {
      // Android: geo URI scheme with address query
      url = Uri.parse('geo:0,0?q=$encodedAddress');
    } else if (Platform.isIOS) {
      // iOS: comgooglemaps URI scheme
      url = Uri.parse('comgooglemaps://?q=$encodedAddress');
    } else {
      // Fallback for other platforms
      url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
      );
    }

    if (await canLaunchUrl(url)) {
      return await launchUrl(url);
    }

    return false;
  }

  /// Abre Google Maps App para navegación (modo conducción)
  /// 
  /// Usa coordenadas si están disponibles, de lo contrario usa la dirección
  static Future<bool> openMapsForNavigation({
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    Uri url;

    if (Platform.isAndroid) {
      // Android: google.navigation URI scheme
      url = Uri.parse('google.navigation:q=$latitude,$longitude&mode=d');
    } else if (Platform.isIOS) {
      // iOS: comgooglemaps URI scheme with navigation
      url = Uri.parse(
        'comgooglemaps://?daddr=$latitude,$longitude&directionsmode=driving',
      );
    } else {
      // Fallback for other platforms
      url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
      );
    }

    if (await canLaunchUrl(url)) {
      return await launchUrl(url);
    }

    // Si falla y hay dirección, intentar con la dirección
    if (address != null && address.isNotEmpty) {
      return await openMapsWithAddress(address: address);
    }

    return false;
  }
}
