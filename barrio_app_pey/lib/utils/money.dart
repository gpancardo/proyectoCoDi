String formatMoney(dynamic minor) =>
    '\$${((minor as num) / 100).toStringAsFixed(0)}';
