import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  final String id;
  final String name;
  final String slug;
  final int level;
  final String? parentId;
  final List<CategoryModel> children;
  final String? sizeType;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.level,
    this.parentId,
    this.children = const [],
    this.sizeType,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      level: json['level'],
      parentId: json['parentId'],
      sizeType: json['sizeType'],
      children: json['children'] != null
          ? (json['children'] as List)
              .map((c) => CategoryModel.fromJson(c))
              .toList()
          : [],
    );
  }

  @override
  List<Object?> get props => [id, name, slug, level, parentId, children, sizeType];
}
