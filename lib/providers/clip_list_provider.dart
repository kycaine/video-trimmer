import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/clip_model.dart';

class ClipListNotifier extends Notifier<List<ClipModel>> {
  @override
  List<ClipModel> build() => [];

  void addClip(ClipModel clip) {
    state = [...state, clip];
  }

  void removeClip(int index) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i != index) state[i],
    ];
  }

  void updateClip(int index, ClipModel newClip) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i == index) newClip else state[i],
    ];
  }

  void clear() {
    state = [];
  }
}

final clipListProvider = NotifierProvider<ClipListNotifier, List<ClipModel>>(ClipListNotifier.new);
