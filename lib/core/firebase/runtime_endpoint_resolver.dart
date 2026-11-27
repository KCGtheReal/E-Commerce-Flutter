import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DiscoveredRuntimeEndpoints {
  const DiscoveredRuntimeEndpoints({
    this.lanApiUrl,
    this.lanGatewayUrl,
    this.tunnelUrl,
    this.localtunnelUrl,
  });

  final String? lanApiUrl;
  final String? lanGatewayUrl;
  final String? tunnelUrl;
  final String? localtunnelUrl;

  factory DiscoveredRuntimeEndpoints.fromFirestoreDoc(
    Map<String, dynamic>? docData,
  ) {
    if (docData == null || docData.isEmpty) {
      return const DiscoveredRuntimeEndpoints();
    }
    final rawValue = docData['value'];
    final map = rawValue is Map ? Map<String, dynamic>.from(rawValue) : docData;

    return DiscoveredRuntimeEndpoints(
      lanApiUrl: _cleanHttpUrl(map['lan_api_url']),
      lanGatewayUrl: _cleanHttpUrl(map['lan_gateway_url']),
      tunnelUrl: _cleanHttpUrl(map['tunnel_url']),
      localtunnelUrl: _cleanHttpUrl(map['localtunnel_url']),
    );
  }

  static String? _cleanHttpUrl(Object? raw) {
    final value = raw?.toString().trim() ?? '';
    if (value.isEmpty) {
      return null;
    }
    final parsed = Uri.tryParse(value);
    if (parsed == null ||
        !parsed.hasScheme ||
        parsed.host.isEmpty ||
        (parsed.scheme != 'http' && parsed.scheme != 'https')) {
      return null;
    }
    var normalized = value;
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
}

class ResolvedEndpointSelection {
  const ResolvedEndpointSelection({
    required this.backendUrl,
    required this.gatewayUrl,
  });

  final String backendUrl;
  final String gatewayUrl;
}

typedef RuntimeEndpointsFetcher = Future<DiscoveredRuntimeEndpoints?> Function();

/// Automatically discovers the PC's active LAN Wi-Fi IP or live Cloudflare/localtunnel
/// backend URL from Cloud Firestore (`settings/runtime_endpoints`) for installed
/// native Android/iOS builds when no manual URL override is saved.
class RuntimeEndpointResolver {
  RuntimeEndpointResolver({
    http.Client? httpClient,
    RuntimeEndpointsFetcher? endpointsFetcher,
    Duration localProbeTimeout = const Duration(milliseconds: 900),
    Duration tunnelProbeTimeout = const Duration(milliseconds: 2500),
  })  : _httpClient = httpClient ?? http.Client(),
        _endpointsFetcher = endpointsFetcher,
        _localProbeTimeout = localProbeTimeout,
        _tunnelProbeTimeout = tunnelProbeTimeout;

  final http.Client _httpClient;
  final RuntimeEndpointsFetcher? _endpointsFetcher;
  final Duration _localProbeTimeout;
  final Duration _tunnelProbeTimeout;

  Future<ResolvedEndpointSelection?> resolve({
    TargetPlatform? platformOverride,
    bool isWebOverride = kIsWeb,
  }) async {
    if (isWebOverride) {
      return null;
    }

    final targetPlatform = platformOverride ?? defaultTargetPlatform;
    final discovered = await _fetchEndpoints();

    final localBackend = targetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://127.0.0.1:8000';
    final localGateway = targetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:4000'
        : 'http://127.0.0.1:4000';

    final lanApi = discovered?.lanApiUrl;
    final lanGateway = discovered?.lanGatewayUrl;

    // 1. Prefer local LAN Wi-Fi IP or Emulator/Loopback concurrently (~900ms max).
    final localCandidates = <_ProbePair>[
      if (lanApi != null && lanApi.isNotEmpty)
        _ProbePair(
          backendUrl: lanApi,
          gatewayUrl: lanGateway ?? _deriveLanGateway(lanApi),
        ),
      _ProbePair(
        backendUrl: localBackend,
        gatewayUrl: localGateway,
      ),
    ];

    final localChecks = await Future.wait<bool>(
      localCandidates.map(
        (pair) => _isLaravelReachable(pair.backendUrl, _localProbeTimeout),
      ),
    );

    for (var i = 0; i < localCandidates.length; i++) {
      if (localChecks[i]) {
        final winner = localCandidates[i];
        final gwAlive = winner.gatewayUrl.isNotEmpty &&
            await _isGatewayHealthy(winner.gatewayUrl, _localProbeTimeout);
        return ResolvedEndpointSelection(
          backendUrl: winner.backendUrl,
          gatewayUrl: gwAlive ? winner.gatewayUrl : '',
        );
      }
    }

    // 2. Phone is away from PC LAN (e.g. 4G/5G or isolated Wi-Fi): try live HTTPS tunnels.
    final tunnelCandidates = <String>[
      if (discovered?.tunnelUrl != null && discovered!.tunnelUrl!.isNotEmpty)
        discovered.tunnelUrl!,
      if (discovered?.localtunnelUrl != null &&
          discovered!.localtunnelUrl!.isNotEmpty)
        discovered.localtunnelUrl!,
    ];

    for (final tunnelUrl in tunnelCandidates) {
      if (await _isLaravelReachable(tunnelUrl, _tunnelProbeTimeout)) {
        // HTTPS tunnel proxies directly to PC Laravel, which already calls PC :4000.
        return ResolvedEndpointSelection(
          backendUrl: tunnelUrl,
          gatewayUrl: '',
        );
      }
    }

    return null;
  }

  Future<DiscoveredRuntimeEndpoints?> _fetchEndpoints() async {
    if (_endpointsFetcher != null) {
      try {
        return await _endpointsFetcher().timeout(const Duration(seconds: 3));
      } catch (_) {
        return null;
      }
    }

    if (Firebase.apps.isEmpty) {
      return null;
    }

    try {
      final docRef = FirebaseFirestore.instance
          .collection('settings')
          .doc('runtime_endpoints');

      DocumentSnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await docRef
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 3));
      } catch (_) {
        snapshot = await docRef.get().timeout(const Duration(seconds: 2));
      }

      if (!snapshot.exists) {
        return null;
      }
      return DiscoveredRuntimeEndpoints.fromFirestoreDoc(snapshot.data());
    } catch (_) {
      return null;
    }
  }

  Future<bool> _isLaravelReachable(String baseUrl, Duration timeout) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/pages/about');
      final response = await _httpClient.get(
        uri,
        headers: const <String, String>{
          'Accept': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
        },
      ).timeout(timeout);

      if (response.statusCode != 200 || response.body.trim().isEmpty) {
        return false;
      }

      final decoded = jsonDecode(response.body);
      return decoded is Map && decoded.containsKey('page');
    } catch (_) {
      return false;
    }
  }

  Future<bool> _isGatewayHealthy(String gatewayBaseUrl, Duration timeout) async {
    try {
      final uri = Uri.parse('$gatewayBaseUrl/health');
      final response = await _httpClient.get(
        uri,
        headers: const <String, String>{
          'Accept': 'application/json',
        },
      ).timeout(timeout);

      if (response.statusCode != 200 || response.body.trim().isEmpty) {
        return false;
      }
      final decoded = jsonDecode(response.body);
      return decoded is Map && decoded['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  static String _deriveLanGateway(String backendUrl) {
    final parsed = Uri.tryParse(backendUrl);
    if (parsed == null || parsed.host.isEmpty || parsed.scheme != 'http') {
      return '';
    }
    return Uri(scheme: 'http', host: parsed.host, port: 4000).toString();
  }
}

class _ProbePair {
  const _ProbePair({
    required this.backendUrl,
    required this.gatewayUrl,
  });

  final String backendUrl;
  final String gatewayUrl;
}
