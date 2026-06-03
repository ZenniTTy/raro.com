enum PaymentMethod {
  apple(
    label: 'Apple Pay',
    subtitle: 'App Store · Toque para autorizar com Face ID',
    confirmHint: 'AUTORIZE COM FACE ID · APP STORE',
  ),
  google(
    label: 'Google Play',
    subtitle: 'Play Store · Cobrança na sua conta Google',
    confirmHint: 'AUTORIZE NA SUA CONTA GOOGLE · PLAY STORE',
  );

  const PaymentMethod({
    required this.label,
    required this.subtitle,
    required this.confirmHint,
  });

  final String label;
  final String subtitle;
  final String confirmHint;
}
