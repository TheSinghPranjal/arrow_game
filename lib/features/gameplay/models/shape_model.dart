enum ShapeType {
  heart('Heart'),
  diamond('Diamond'),
  square('Square'),
  rectangle('Rectangle'),
  oval('Oval'),
  circle('Circle'),
  star('Star'),
  triangle('Triangle'),
  hexagon('Hexagon'),
  pentagon('Pentagon'),
  butterfly('Butterfly'),
  shield('Shield'),
  flower('Flower'),
  crescent('Crescent'),
  cloud('Cloud'),
  leaf('Leaf'),
  cross('Cross'),
  arrow('Arrow'),
  spiral('Spiral'),
  doubleHeart('Double Heart'),
  doubleDiamond('Double Diamond'),
  tiers('Tiers');

  const ShapeType(this.label);
  final String label;
}

/// A silhouette request: which shape, which variation of it, and the size of
/// the sampling grid. The concrete occupancy mask is produced by `ShapeUtils`.
class ShapeModel {
  const ShapeModel(this.type, {this.variant = 0, required this.rows, required this.cols});

  final ShapeType type;
  final int variant;
  final int rows;
  final int cols;
}
