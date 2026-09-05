String legalMarkdownToPlain(String markdown) {
  final withoutHeadingMarks = markdown.replaceAll(
    RegExp(r'^#+\s*', multiLine: true),
    '',
  );
  final withoutLinks = withoutHeadingMarks.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
    (match) => match.group(1) ?? '',
  );
  final withoutBold = withoutLinks.replaceAllMapped(
    RegExp(r'\*\*([^*]+)\*\*'),
    (match) => match.group(1) ?? '',
  );
  return withoutBold.replaceAll('`', '').trim();
}
