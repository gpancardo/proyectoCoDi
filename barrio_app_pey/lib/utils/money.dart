/// Centavos a texto: `$1,240` si es cerrado y `$0.01` si no.
String formatMoney(dynamic minor) {
  final cents = (minor as num).round();
  final whole = (cents.abs() ~/ 100)
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => ',');
  final rest = cents.abs() % 100;
  return '${cents < 0 ? '-' : ''}\$$whole'
      '${rest == 0 ? '' : '.${rest.toString().padLeft(2, '0')}'}';
}
