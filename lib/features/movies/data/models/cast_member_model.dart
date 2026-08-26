import '../../../../core/utils/json_parsing.dart';
import '../../domain/entities/cast_member.dart';

/// Maps a single TMDB credits `cast` entry to the [CastMember] entity.
class CastMemberModel {
  const CastMemberModel._();

  static CastMember fromJson(Map<String, dynamic> json) {
    return CastMember(
      id: asIntOrNull(json['id']) ?? 0,
      name: asStringOrNull(json['name']) ?? 'Unknown',
      character: asStringOrNull(json['character']),
      profilePath: asStringOrNull(json['profile_path']),
    );
  }
}
