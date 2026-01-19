import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixi_vpn/utils/v2ray_subscription_parser.dart';

void main() {
  test('parses plain URI list', () {
    const vless = 'vless://11111111-1111-1111-1111-111111111111@example.com:443?type=tcp#VLESS-Node';
    final vmessJson = jsonEncode({
      'v': '2',
      'ps': 'VMESS-Node',
      'add': 'vmess.example.com',
      'port': '443',
      'id': '22222222-2222-2222-2222-222222222222',
      'aid': '0',
      'net': 'tcp',
      'type': 'none',
      'host': '',
      'path': '',
      'tls': 'tls',
    });
    final vmess = 'vmess://${base64Encode(utf8.encode(vmessJson))}';
    const trojan = 'trojan://password@trojan.example.com:443#Trojan-Node';

    final content = [vless, vmess, trojan].join('\n');
    final nodes = V2raySubscriptionParser.parse(content);

    expect(nodes.length, 3);
    expect(nodes[0].type, 'vless');
    expect(nodes[0].name, 'VLESS-Node');
    expect(nodes[0].raw, vless);
    expect(nodes[1].type, 'vmess');
    expect(nodes[1].name, 'VMESS-Node');
    expect(nodes[2].type, 'trojan');
    expect(nodes[2].name, 'Trojan-Node');
  });

  test('parses base64 list', () {
    const vless = 'vless://11111111-1111-1111-1111-111111111111@example.com:443?type=tcp#VLESS-Node';
    const trojan = 'trojan://password@trojan.example.com:443#Trojan-Node';
    final content = [vless, trojan].join('\n');
    final encoded = base64Encode(utf8.encode(content));

    final nodes = V2raySubscriptionParser.parse(encoded);

    expect(nodes.length, 2);
    expect(nodes[0].type, 'vless');
    expect(nodes[0].raw, vless);
    expect(nodes[1].type, 'trojan');
    expect(nodes[1].raw, trojan);
  });
}
