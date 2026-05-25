enum Resolution {
  hd720('720p'),
  fullHd1080('1080p'),
  uhd4k('4K'),
  uhd4k60('4K60');

  const Resolution(this.label);

  final String label;
}
