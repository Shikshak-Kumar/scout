class Opportunity {
  final String id,
      title,
      organization,
      category,
      description,
      sourceUrl,
      verification;
  final String? applicationUrl, location, deadlineText;
  final DateTime firstSeen, lastSeen;
  final double qualityScore;
  final bool? remote;
  const Opportunity({
    required this.id,
    required this.title,
    required this.organization,
    required this.category,
    required this.description,
    required this.sourceUrl,
    required this.verification,
    required this.firstSeen,
    required this.lastSeen,
    required this.qualityScore,
    this.applicationUrl,
    this.location,
    this.deadlineText,
    this.remote,
  });
  factory Opportunity.fromJson(Map<String, dynamic> j) => Opportunity(
    id: j['id'],
    title: j['title'],
    organization: j['organization'],
    category: j['category'],
    description: j['description'],
    sourceUrl: j['source_url'],
    verification: j['verification'],
    firstSeen: DateTime.parse(j['first_seen_at']),
    lastSeen: DateTime.parse(j['last_seen_at']),
    qualityScore: (j['quality_score'] as num).toDouble(),
    applicationUrl: j['application_url'],
    location: j['location'],
    deadlineText: j['deadline_text'],
    remote: j['remote'],
  );
}
