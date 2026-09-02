class Opportunity {
  final String id;
  final String title;
  final String? company;
  final String? location;
  final String? description;
  final String? source;
  final String? externalUrl;

  final String organization;
  final String verification;
  final DateTime lastSeen;
  final String? applicationUrl;
  final String sourceUrl;

  Opportunity({
    required this.id,
    required this.title,
    this.company,
    this.location,
    this.description,
    this.source,
    this.externalUrl,
    String? organization,
    String? verification,
    DateTime? lastSeen,
    this.applicationUrl,
    String? sourceUrl,
  })  : organization = organization ?? company ?? 'Unknown',
        verification = verification ?? 'unverified',
        lastSeen = lastSeen ?? DateTime.now(),
        sourceUrl = sourceUrl ?? externalUrl ?? '';

  factory Opportunity.fromJson(Map<String, dynamic> json) {
    return Opportunity(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      company: json['company'],
      location: json['location'],
      description: json['description'],
      source: json['source'],
      externalUrl: json['external_url'],
      organization: json['organization'] ?? json['company'],
      verification: json['verification_status'] ?? json['verification'] ?? 'unverified',
      lastSeen: _parseDate(json['last_seen_at'] ?? json['last_seen'] ?? json['first_seen_at'] ?? json['updated_at']),
      applicationUrl: json['application_url'] ?? json['external_url'],
      sourceUrl: json['source_url'] ?? json['external_url'] ?? '',
    );
  }
}

DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}