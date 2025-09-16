class RecentExercises {
  static final Set<String> _names = <String>{};

  static List<String> getAll() {
    final list = _names.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  static void add(String name) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return;
    _names.add(cleaned);
  }
}


