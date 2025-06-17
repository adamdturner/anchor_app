class NavigationState {
  final int currentPageIndex;

  NavigationState({
    required this.currentPageIndex,
  });

  NavigationState copyWith({
    int? currentPageIndex,
    bool? isScanTabActive,
  }) {
    return NavigationState(
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
    );
  }
}
