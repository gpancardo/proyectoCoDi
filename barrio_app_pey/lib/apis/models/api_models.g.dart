// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductApiModel _$ProductApiModelFromJson(Map<String, dynamic> json) =>
    ProductApiModel(
      nombre: json['nombre'] as String,
      precio: (json['precio'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$ProductApiModelToJson(ProductApiModel instance) =>
    <String, dynamic>{
      'nombre': instance.nombre,
      'precio': instance.precio,
    };

BusinessApiModel _$BusinessApiModelFromJson(Map<String, dynamic> json) =>
    BusinessApiModel(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      imagenUrl: json['imagen_url'] as String?,
      zona: json['zona'] as String? ?? '',
      colonia: json['colonia'] as String?,
      direccion: json['direccion'] as String? ?? '',
      categoria: json['categoria'] as String? ?? '',
      productos: (json['productos'] as List<dynamic>?)
              ?.map((e) => ProductApiModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      abierto: json['abierto'] as bool? ?? true,
      verificado: json['verificado'] as bool? ?? true,
      score: (json['score'] as num?)?.toDouble(),
      matchReasons: (json['match_reasons'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$BusinessApiModelToJson(BusinessApiModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'descripcion': instance.descripcion,
      'imagen_url': instance.imagenUrl,
      'zona': instance.zona,
      'colonia': instance.colonia,
      'direccion': instance.direccion,
      'categoria': instance.categoria,
      'productos': instance.productos.map((e) => e.toJson()).toList(),
      'abierto': instance.abierto,
      'verificado': instance.verificado,
      'score': instance.score,
      'match_reasons': instance.matchReasons,
    };

AgentSearchMeta _$AgentSearchMetaFromJson(Map<String, dynamic> json) =>
    AgentSearchMeta(
      answer: json['answer'] as String? ??
          'Te muestro coincidencias del catálogo disponible.',
      mode: json['mode'] as String? ?? 'deterministic',
      retrieved: (json['retrieved'] as num?)?.toInt() ?? 0,
      filters: json['filters'] as Map<String, dynamic>? ?? {},
    );

Map<String, dynamic> _$AgentSearchMetaToJson(AgentSearchMeta instance) =>
    <String, dynamic>{
      'answer': instance.answer,
      'mode': instance.mode,
      'retrieved': instance.retrieved,
      'filters': instance.filters,
    };

AgentSearchResponse _$AgentSearchResponseFromJson(Map<String, dynamic> json) =>
    AgentSearchResponse(
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => BusinessApiModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      meta: json['meta'] == null
          ? null
          : AgentSearchMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AgentSearchResponseToJson(
        AgentSearchResponse instance) =>
    <String, dynamic>{
      'data': instance.data.map((e) => e.toJson()).toList(),
      'meta': instance.meta?.toJson(),
    };

BadgeApiModel _$BadgeApiModelFromJson(Map<String, dynamic> json) =>
    BadgeApiModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      nivel: json['nivel'] as String?,
      detalle: json['detalle'] as String? ?? '',
      avance: (json['avance'] as num?)?.toInt() ?? 0,
      meta: (json['meta'] as num?)?.toInt() ?? 0,
      obtenida: json['obtenida'] as bool? ?? false,
    );

Map<String, dynamic> _$BadgeApiModelToJson(BadgeApiModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'nivel': instance.nivel,
      'detalle': instance.detalle,
      'avance': instance.avance,
      'meta': instance.meta,
      'obtenida': instance.obtenida,
    };

BoroughBadgeApiModel _$BoroughBadgeApiModelFromJson(
        Map<String, dynamic> json) =>
    BoroughBadgeApiModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      zona: json['zona'] as String? ?? '',
      nivel: json['nivel'] as String?,
      avance: (json['avance'] as num?)?.toInt() ?? 0,
      meta: (json['meta'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$BoroughBadgeApiModelToJson(
        BoroughBadgeApiModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'zona': instance.zona,
      'nombre': instance.nombre,
      'nivel': instance.nivel,
      'avance': instance.avance,
      'meta': instance.meta,
    };

FirstPurchaseRewardApiModel _$FirstPurchaseRewardApiModelFromJson(
        Map<String, dynamic> json) =>
    FirstPurchaseRewardApiModel(
      negocioId: (json['negocio_id'] as num).toInt(),
      negocio: json['negocio'] as String?,
      titulo: json['titulo'] as String,
      minCompraMinor: (json['min_compra_minor'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$FirstPurchaseRewardApiModelToJson(
        FirstPurchaseRewardApiModel instance) =>
    <String, dynamic>{
      'negocio_id': instance.negocioId,
      'negocio': instance.negocio,
      'titulo': instance.titulo,
      'min_compra_minor': instance.minCompraMinor,
    };

BuyerProfileResponse _$BuyerProfileResponseFromJson(
        Map<String, dynamic> json) =>
    BuyerProfileResponse(
      nombre: json['nombre'] as String?,
      pedidosPagados: (json['pedidos_pagados'] as num?)?.toInt() ?? 0,
      insignias: (json['insignias'] as List<dynamic>?)
              ?.map((e) => BadgeApiModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      premio: json['premio'] == null
          ? null
          : FirstPurchaseRewardApiModel.fromJson(
              json['premio'] as Map<String, dynamic>),
      alcaldias: (json['alcaldias'] as List<dynamic>?)
              ?.map((e) =>
                  BoroughBadgeApiModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      cdmx: json['cdmx'] == null
          ? null
          : BoroughBadgeApiModel.fromJson(json['cdmx'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BuyerProfileResponseToJson(
        BuyerProfileResponse instance) =>
    <String, dynamic>{
      'nombre': instance.nombre,
      'pedidos_pagados': instance.pedidosPagados,
      'insignias': instance.insignias.map((e) => e.toJson()).toList(),
      'premio': instance.premio?.toJson(),
      'alcaldias': instance.alcaldias.map((e) => e.toJson()).toList(),
      'cdmx': instance.cdmx?.toJson(),
    };

QuoteResponse _$QuoteResponseFromJson(Map<String, dynamic> json) =>
    QuoteResponse(
      quoteId: (json['quote_id'] as num).toInt(),
      business:
          QuoteBusiness.fromJson(json['business'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>?)
              ?.map(
                  (e) => QuoteItemResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subtotalMinor: (json['subtotal_minor'] as num?)?.toInt() ?? 0,
      descuentoMinor: (json['descuento_minor'] as num?)?.toInt() ?? 0,
      coupon: json['coupon'] == null
          ? null
          : QuoteCoupon.fromJson(json['coupon'] as Map<String, dynamic>),
      totalMinor: (json['total_minor'] as num?)?.toInt() ?? 0,
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
    );

Map<String, dynamic> _$QuoteResponseToJson(QuoteResponse instance) =>
    <String, dynamic>{
      'quote_id': instance.quoteId,
      'business': instance.business.toJson(),
      'items': instance.items.map((e) => e.toJson()).toList(),
      'subtotal_minor': instance.subtotalMinor,
      'descuento_minor': instance.descuentoMinor,
      'coupon': instance.coupon?.toJson(),
      'total_minor': instance.totalMinor,
      'expires_at': instance.expiresAt?.toIso8601String(),
    };

QuoteCoupon _$QuoteCouponFromJson(Map<String, dynamic> json) => QuoteCoupon(
      titulo: json['titulo'] as String,
    );

Map<String, dynamic> _$QuoteCouponToJson(QuoteCoupon instance) =>
    <String, dynamic>{
      'titulo': instance.titulo,
    };

QuoteBusiness _$QuoteBusinessFromJson(Map<String, dynamic> json) =>
    QuoteBusiness(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre'] as String,
    );

Map<String, dynamic> _$QuoteBusinessToJson(QuoteBusiness instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
    };

QuoteItemResponse _$QuoteItemResponseFromJson(Map<String, dynamic> json) =>
    QuoteItemResponse(
      nombre: json['nombre'] as String,
      precioMinor: (json['precio_minor'] as num).toInt(),
      cantidad: (json['cantidad'] as num).toInt(),
    );

Map<String, dynamic> _$QuoteItemResponseToJson(QuoteItemResponse instance) =>
    <String, dynamic>{
      'nombre': instance.nombre,
      'precio_minor': instance.precioMinor,
      'cantidad': instance.cantidad,
    };

OrderResponse _$OrderResponseFromJson(Map<String, dynamic> json) =>
    OrderResponse(
      id: (json['id'] as num).toInt(),
      negocioId: (json['negocio_id'] as num).toInt(),
      estado: json['estado'] as String,
      items: (json['items'] as List<dynamic>?)
              ?.map(
                  (e) => QuoteItemResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalMinor: (json['total_minor'] as num?)?.toInt() ?? 0,
      descuentoMinor: (json['descuento_minor'] as num?)?.toInt() ?? 0,
      notas: json['notas'] as String?,
      creado: json['creado'] == null
          ? null
          : DateTime.parse(json['creado'] as String),
      codigo: json['codigo'] as String?,
    );

Map<String, dynamic> _$OrderResponseToJson(OrderResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'negocio_id': instance.negocioId,
      'estado': instance.estado,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total_minor': instance.totalMinor,
      'descuento_minor': instance.descuentoMinor,
      'notas': instance.notas,
      'creado': instance.creado?.toIso8601String(),
      'codigo': instance.codigo,
    };

PaymentAttemptResponse _$PaymentAttemptResponseFromJson(
        Map<String, dynamic> json) =>
    PaymentAttemptResponse(
      id: (_paymentId(json, 'id') as num?)?.toInt(),
      via: json['via'] as String?,
      estado: json['estado'] as String? ?? '',
      vence: json['vence'] == null
          ? null
          : DateTime.parse(json['vence'] as String),
      link: json['link'] as String?,
      qrImage: json['qr_image'] as String?,
      amountMinor: (_amountMinor(json, 'amount_minor') as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PaymentAttemptResponseToJson(
        PaymentAttemptResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'via': instance.via,
      'estado': instance.estado,
      'vence': instance.vence?.toIso8601String(),
      'link': instance.link,
      'qr_image': instance.qrImage,
      'amount_minor': instance.amountMinor,
    };
