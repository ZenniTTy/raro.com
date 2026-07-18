enum PaymentMethod {
  apple(label: 'Apple Pay'),
  google(label: 'Google Play');

  const PaymentMethod({required this.label});

  final String label;
}
