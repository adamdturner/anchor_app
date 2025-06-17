abstract class NavigationEvent {}

class SelectPageEvent extends NavigationEvent {
  final int index;
  SelectPageEvent(this.index);
}
