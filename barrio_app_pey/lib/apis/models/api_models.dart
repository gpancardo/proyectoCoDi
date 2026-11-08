import 'package:json_annotation/json_annotation.dart';

part 'api_models.g.dart';

/// Modelos del contrato HTTPS de Barrio; la app no lee ni escribe tablas.
@JsonSerializable()
class ProductApiModel {
  const ProductApiModel({required this.nombre, this.precio = 0});

  final String nombre;
  @JsonKey(defaultValue: 0)
  final double precio;

  factory ProductApiModel.fromJson(Map<String, dynamic> json) =>
      _$ProductApiModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductApiModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BusinessApiModel {
  const BusinessApiModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.imagenUrl,
    this.zona = '',
    this.colonia,
    this.direccion = '',
    this.categoria = '',
    this.productos = const [],
    this.abierto = true,
    this.verificado = true,
    this.score,
    this.matchReasons = const [],
  });

  final int id;
  final String nombre;
  final String? descripcion;
  @JsonKey(name: 'imagen_url')
  final String? imagenUrl;
  @JsonKey(defaultValue: '')
  final String zona;
  final String? colonia;
  @JsonKey(defaultValue: '')
  final String direccion;
  @JsonKey(defaultValue: '')
  final String categoria;
  @JsonKey(defaultValue: <ProductApiModel>[])
  final List<ProductApiModel> productos;
  @JsonKey(defaultValue: true)
  final bool abierto;
  @JsonKey(defaultValue: true)
  final bool verificado;
  final double? score;
  @JsonKey(name: 'match_reasons', defaultValue: <String>[])
  final List<String> matchReasons;

  factory BusinessApiModel.fromJson(Map<String, dynamic> json) =>
      _$BusinessApiModelFromJson(json);
  Map<String, dynamic> toJson() => _$BusinessApiModelToJson(this);
}

@JsonSerializable()
class AgentSearchMeta {
  const AgentSearchMeta({
    this.answer = 'Te muestro coincidencias del catálogo disponible.',
    this.mode = 'deterministic',
    this.retrieved = 0,
    this.filters = const {},
  });

  @JsonKey(defaultValue: 'Te muestro coincidencias del catálogo disponible.')
  final String answer;
  @JsonKey(defaultValue: 'deterministic')
  final String mode;
  @JsonKey(defaultValue: 0)
  final int retrieved;
  @JsonKey(defaultValue: <String, dynamic>{})
  final Map<String, dynamic> filters;

  factory AgentSearchMeta.fromJson(Map<String, dynamic> json) =>
      _$AgentSearchMetaFromJson(json);
  Map<String, dynamic> toJson() => _$AgentSearchMetaToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AgentSearchResponse {
  const AgentSearchResponse({required this.data, this.meta});

  @JsonKey(defaultValue: <BusinessApiModel>[])
  final List<BusinessApiModel> data;
  final AgentSearchMeta? meta;

  factory AgentSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$AgentSearchResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AgentSearchResponseToJson(this);
}

@JsonSerializable()
class BadgeApiModel {
  const BadgeApiModel({
    required this.id,
    required this.nombre,
    this.nivel,
    this.detalle = '',
    this.avance = 0,
    this.meta = 0,
    this.obtenida = false,
  });

  final String id;
  final String nombre;
  final String? nivel;
  @JsonKey(defaultValue: '')
  final String detalle;
  @JsonKey(defaultValue: 0)
  final int avance;
  @JsonKey(defaultValue: 0)
  final int meta;
  @JsonKey(defaultValue: false)
  final bool obtenida;

  factory BadgeApiModel.fromJson(Map<String, dynamic> json) =>
      _$BadgeApiModelFromJson(json);
  Map<String, dynamic> toJson() => _$BadgeApiModelToJson(this);
}

@JsonSerializable()
class BoroughBadgeApiModel {
  const BoroughBadgeApiModel({
    required this.id,
    required this.nombre,
    this.zona = '',
    this.nivel,
    this.avance = 0,
    this.meta = 0,
  });

  final String id;
  @JsonKey(defaultValue: '')
  final String zona;
  final String nombre;
  final String? nivel;
  @JsonKey(defaultValue: 0)
  final int avance;
  @JsonKey(defaultValue: 0)
  final int meta;

  factory BoroughBadgeApiModel.fromJson(Map<String, dynamic> json) =>
      _$BoroughBadgeApiModelFromJson(json);
  Map<String, dynamic> toJson() => _$BoroughBadgeApiModelToJson(this);
}

@JsonSerializable()
class FirstPurchaseRewardApiModel {
  const FirstPurchaseRewardApiModel({
    required this.negocioId,
    this.negocio,
    required this.titulo,
    this.minCompraMinor = 0,
  });

  @JsonKey(name: 'negocio_id')
  final int negocioId;
  final String? negocio;
  final String titulo;
  @JsonKey(name: 'min_compra_minor', defaultValue: 0)
  final int minCompraMinor;

  factory FirstPurchaseRewardApiModel.fromJson(Map<String, dynamic> json) =>
      _$FirstPurchaseRewardApiModelFromJson(json);
  Map<String, dynamic> toJson() => _$FirstPurchaseRewardApiModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BuyerProfileResponse {
  const BuyerProfileResponse({
    this.nombre,
    this.pedidosPagados = 0,
    this.insignias = const [],
    this.premio,
    this.alcaldias = const [],
    this.cdmx,
  });

  final String? nombre;
  @JsonKey(name: 'pedidos_pagados', defaultValue: 0)
  final int pedidosPagados;
  @JsonKey(defaultValue: <BadgeApiModel>[])
  final List<BadgeApiModel> insignias;
  final FirstPurchaseRewardApiModel? premio;
  @JsonKey(defaultValue: <BoroughBadgeApiModel>[])
  final List<BoroughBadgeApiModel> alcaldias;
  final BoroughBadgeApiModel? cdmx;

  factory BuyerProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$BuyerProfileResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BuyerProfileResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class QuoteResponse {
  const QuoteResponse({
    required this.quoteId,
    required this.business,
    this.items = const [],
    this.subtotalMinor = 0,
    this.descuentoMinor = 0,
    this.coupon,
    this.totalMinor = 0,
    this.expiresAt,
  });

  @JsonKey(name: 'quote_id')
  final int quoteId;
  final QuoteBusiness business;
  @JsonKey(defaultValue: <QuoteItemResponse>[])
  final List<QuoteItemResponse> items;
  @JsonKey(name: 'subtotal_minor', defaultValue: 0)
  final int subtotalMinor;
  @JsonKey(name: 'descuento_minor', defaultValue: 0)
  final int descuentoMinor;
  final QuoteCoupon? coupon;
  @JsonKey(name: 'total_minor', defaultValue: 0)
  final int totalMinor;
  @JsonKey(name: 'expires_at')
  final DateTime? expiresAt;

  factory QuoteResponse.fromJson(Map<String, dynamic> json) =>
      _$QuoteResponseFromJson(json);
  Map<String, dynamic> toJson() => _$QuoteResponseToJson(this);
}

@JsonSerializable()
class QuoteCoupon {
  const QuoteCoupon({required this.titulo});
  final String titulo;
  factory QuoteCoupon.fromJson(Map<String, dynamic> json) =>
      _$QuoteCouponFromJson(json);
  Map<String, dynamic> toJson() => _$QuoteCouponToJson(this);
}

@JsonSerializable()
class QuoteBusiness {
  const QuoteBusiness({required this.id, required this.nombre});
  final int id;
  final String nombre;
  factory QuoteBusiness.fromJson(Map<String, dynamic> json) =>
      _$QuoteBusinessFromJson(json);
  Map<String, dynamic> toJson() => _$QuoteBusinessToJson(this);
}

@JsonSerializable()
class QuoteItemResponse {
  const QuoteItemResponse({
    required this.nombre,
    required this.precioMinor,
    required this.cantidad,
  });
  final String nombre;
  @JsonKey(name: 'precio_minor')
  final int precioMinor;
  final int cantidad;
  factory QuoteItemResponse.fromJson(Map<String, dynamic> json) =>
      _$QuoteItemResponseFromJson(json);
  Map<String, dynamic> toJson() => _$QuoteItemResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OrderResponse {
  const OrderResponse({
    required this.id,
    required this.negocioId,
    required this.estado,
    this.items = const [],
    this.totalMinor = 0,
    this.descuentoMinor = 0,
    this.notas,
    this.creado,
    this.codigo,
  });

  final int id;
  @JsonKey(name: 'negocio_id')
  final int negocioId;
  final String estado;
  @JsonKey(defaultValue: <QuoteItemResponse>[])
  final List<QuoteItemResponse> items;
  @JsonKey(name: 'total_minor', defaultValue: 0)
  final int totalMinor;
  @JsonKey(name: 'descuento_minor', defaultValue: 0)
  final int descuentoMinor;
  final String? notas;
  final DateTime? creado;
  final String? codigo;

  factory OrderResponse.fromJson(Map<String, dynamic> json) =>
      _$OrderResponseFromJson(json);
  Map<String, dynamic> toJson() => _$OrderResponseToJson(this);
}

@JsonSerializable()
class PaymentAttemptResponse {
  const PaymentAttemptResponse({
    this.id,
    this.via,
    this.estado = '',
    this.vence,
    this.link,
    this.qrImage,
    this.amountMinor = 0,
  });

  @JsonKey(readValue: _paymentId)
  final int? id;
  final String? via;
  @JsonKey(defaultValue: '')
  final String estado;
  final DateTime? vence;
  final String? link;
  @JsonKey(name: 'qr_image')
  final String? qrImage;
  @JsonKey(name: 'amount_minor', readValue: _amountMinor, defaultValue: 0)
  final int amountMinor;

  factory PaymentAttemptResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentAttemptResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentAttemptResponseToJson(this);
}

Object? _paymentId(Map json, String key) => json['payment_id'] ?? json['id'];
Object? _amountMinor(Map json, String key) =>
    json['amount_minor'] ?? json['monto_minor'];
