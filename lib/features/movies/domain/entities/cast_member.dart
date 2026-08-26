/// A single cast member credited on a movie, as returned by TMDB.
class CastMember {
  const CastMember({
    required this.id,
    required this.name,
    this.character,
    this.profilePath,
  });

  final int id;
  final String name;
  final String? character;
  final String? profilePath;
}
