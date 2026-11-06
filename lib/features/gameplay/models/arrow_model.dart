import '../../../core/utils/grid_utils.dart';

/// A single arrow on the board.
///
/// An arrow is a path of orthogonally connected cells ordered tail → head.
/// The shortest arrow occupies one cell; longer ones bend like the doodled
/// paths in the reference. When the arrow escapes, the whole body slides
/// along its own path and leaves the board through the head's straight ray.
class ArrowModel {
  ArrowModel({
    required this.id,
    required List<Cell> cells,
    required this.direction,
    required this.colorIndex,
    this.isRemoved = false,
  }) : cells = List.unmodifiable(cells);

  final int id;

  /// Ordered tail → head.
  final List<Cell> cells;

  /// Direction the arrowhead points (and the arrow escapes).
  final Direction direction;
  final int colorIndex;
  final bool isRemoved;

  Cell get head => cells.last;
  Cell get tail => cells.first;
  int get row => head.row;
  int get column => head.col;
  int get length => cells.length;

  ArrowModel copyWith({bool? isRemoved, int? colorIndex, List<Cell>? cells}) => ArrowModel(
    id: id,
    cells: cells ?? this.cells,
    direction: direction,
    colorIndex: colorIndex ?? this.colorIndex,
    isRemoved: isRemoved ?? this.isRemoved,
  );

  @override
  String toString() => 'Arrow#$id(${direction.name} $cells)';
}
