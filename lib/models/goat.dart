class Goat {
  final String tagNo;
  final String? name;
  final String? breed;
  final String gender;
  final String? goatStage;
  final String? dateOfBirth;
  final String? dateOfEntry;
  final String? weight;
  final String? group;
  final String? obtained;
  final String? motherTag;
  final String? fatherTag;
  final String? notes;
  final String? photoPath;
  final List<Map<String, dynamic>>? weightHistory;

  Goat({
    required this.tagNo,
    this.name,
    this.breed,
    required this.gender,
    this.goatStage,
    this.dateOfBirth,
    this.dateOfEntry,
    this.weight,
    this.group,
    this.obtained,
    this.motherTag,
    this.fatherTag,
    this.notes,
    this.photoPath,
    this.weightHistory,
  });

  // Convert Goat to JSON
  Map<String, dynamic> toJson() {
    return {
      'tagNo': tagNo,
      'name': name,
      'breed': breed,
      'gender': gender,
      'goatStage': goatStage,
      'dateOfBirth': dateOfBirth,
      'dateOfEntry': dateOfEntry,
      'weight': weight,
      'group': group,
      'obtained': obtained,
      'motherTag': motherTag,
      'fatherTag': fatherTag,
      'notes': notes,
      'photoPath': photoPath,
      'weightHistory': weightHistory,
    };
  }

  // Create Goat from JSON
  factory Goat.fromJson(Map<String, dynamic> json) {
    return Goat(
      tagNo: json['tagNo'] as String,
      name: json['name'] as String?,
      breed: json['breed'] as String?,
      gender: json['gender'] as String,
      goatStage: json['goatStage'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      dateOfEntry: json['dateOfEntry'] as String?,
      weight: json['weight'] as String?,
      group: json['group'] as String?,
      obtained: json['obtained'] as String?,
      motherTag: json['motherTag'] as String?,
      fatherTag: json['fatherTag'] as String?,
      notes: json['notes'] as String?,
      photoPath: json['photoPath'] as String?,
      weightHistory: json['weightHistory'] != null 
          ? List<Map<String, dynamic>>.from(json['weightHistory']) 
          : null,
    );
  }
}