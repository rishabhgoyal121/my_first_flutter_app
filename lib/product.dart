class Product {
  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String imageUri;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.imageUri,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      title: json['title'],
      price: json['price'],
      description: json['description'],
      category: json['category'],
      imageUri: json['image'],
    );
  }
}
