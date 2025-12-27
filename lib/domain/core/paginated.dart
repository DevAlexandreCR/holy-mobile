class Paginated<T> {
  const Paginated({required this.items, this.nextCursor});

  final List<T> items;
  final String? nextCursor;
}
