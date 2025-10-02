import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:swatch/models/config.dart';
import 'package:swatch/models/detection_event.dart';
import 'package:window_location_href/window_location_href.dart';

class SwatchApi {
  static final SwatchApi _singleton = SwatchApi._internal();
  static String _swatchHost = "";
  static bool _useHttps = false;

  factory SwatchApi() {
    if (kDebugMode) {
      _swatchHost = "localhost:4500";
      _useHttps = false;
    } else {
      final href = getHref() ?? "";
      
      // Parse the URL properly to extract host and port
      try {
        final uri = Uri.parse(href);
        _swatchHost = uri.host;
        _useHttps = uri.scheme == 'https';
        if (uri.hasPort && uri.port != 80 && uri.port != 443) {
          _swatchHost = "${uri.host}:${uri.port}";
        }
      } catch (e) {
        // Fallback to the old method if parsing fails
        final location = href.replaceAll("http://", "").replaceAll("https://", "");
        _useHttps = href.startsWith("https://");
        final pathStart = location.indexOf("/");

        if (pathStart == -1) {
          _swatchHost = location;
        } else {
          _swatchHost = location.substring(0, pathStart);
        }
      }
    }

    return _singleton;
  }

  SwatchApi._internal();

  String getHost() => _useHttps 
      ? Uri.https(_swatchHost, "").toString()
      : Uri.http(_swatchHost, "").toString();

  Uri _buildUri(String path) => _useHttps 
      ? Uri.https(_swatchHost, path)
      : Uri.http(_swatchHost, path);

  /// Swatch API Funs

  Future<Config> getConfig() async {
    const base = "/api/config";
    final response = await http.get(_buildUri(base)).timeout(
          const Duration(seconds: 15),
        );

    if (response.statusCode == 200) {
      return Config(json.decode(response.body));
    } else {
      return Config.template();
    }
  }

  Future<List<DetectionEvent>> getDetections() async {
    const base = "/api/detections";
    final response = await http.get(_buildUri(base)).timeout(
          const Duration(seconds: 15),
        );

    if (response.statusCode == 200) {
      final parsed = json.decode(response.body);
      return List<DetectionEvent>.from(
        parsed.map((model) => DetectionEvent(model)),
      );
    } else {
      return [];
    }
  }

  Future<Config> getLatest() async {
    const base = "/api/all/latest";
    final response = await http.get(_buildUri(base)).timeout(
          const Duration(seconds: 15),
        );

    if (response.statusCode == 200) {
      return Config(json.decode(response.body));
    } else {
      return Config.template();
    }
  }

  Future<Uint8List> testImageMask(
    Uint8List image,
    String colorLower,
    String colorUpper,
  ) async {
    const base = "/api/colortest/mask";
    final request = http.MultipartRequest("POST", _buildUri(base));
    request.fields["color_lower"] = colorLower;
    request.fields["color_upper"] = colorUpper;
    request.files.add(
      http.MultipartFile.fromBytes("test_image", image,
          filename: 'test_image', contentType: MediaType("image", "jpg")),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      if (kDebugMode) {
        print("testImageMask::${response.toString()}");
      }

      return image;
    }
  }

  // Detection Specific Funs

  Future<bool> deleteDetection(final String detectionId) async {
    final base = "/api/detections/$detectionId";
    final response = await http.delete(_buildUri(base)).timeout(
      const Duration(seconds: 15),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  /// General Utility Funs

  Future<Uint8List> getImageBytes(final String imageSource) async {
    try {
      final http.Response r = await http.get(
        Uri.parse(imageSource),
      );
      return r.bodyBytes;
    } catch (e) {
      return Uint8List(0);
    }
  }
}
