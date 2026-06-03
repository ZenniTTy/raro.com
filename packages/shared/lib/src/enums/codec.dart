enum Codec {
  h264('h264'),
  h265('h265');

  const Codec(this.label);

  final String label;

  static Codec fromLabel(String label) => Codec.values.firstWhere(
    (c) => c.label == label,
    orElse: () => Codec.h265,
  );
}
