import 'package:cloud_firestore/cloud_firestore.dart';

/// Minimal user profile stored in /users/{uid}
class UserProfile {
  final String uid;
  final String? displayName;
  final bool? setupComplete;
  final String? photoURL;
  final String? city;
  final String? bio;
  final Timestamp? createdAt;
  final double? totalDistanceKm;
  final int? totalRuns;
  final List<String>? clubsJoined;

  UserProfile({
    required this.uid,
    this.displayName,
    this.setupComplete,
    this.photoURL,
    this.city,
    this.bio,
    this.createdAt,
    this.totalDistanceKm,
    this.totalRuns,
    this.clubsJoined,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    return UserProfile(
      uid: uid,
      displayName: map['displayName'],
      setupComplete: map['setupComplete'],
      photoURL: map['photoURL'],
      city: map['city'],
      bio: map['bio'],
      createdAt: map['createdAt'],
      totalDistanceKm: (map['totalDistanceKm'] as num?)?.toDouble(),
      totalRuns: map['totalRuns'],
      clubsJoined: List<String>.from(map['clubsJoined'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'setupComplete': setupComplete,
      'photoURL': photoURL,
      'city': city,
      'bio': bio,
      'createdAt': createdAt,
      'totalDistanceKm': totalDistanceKm,
      'totalRuns': totalRuns,
      'clubsJoined': clubsJoined,
    };
  }
}

/// Club document stored in /clubs/{clubId}
class Club {
  final String? id;
  final String name;
  final String? city;
  final String? description;
  final String? logoURL;
  final String organizerUid;
  final Timestamp? createdAt;
  final int? memberCount;
  final List<String>? tags;

  Club({
    this.id,
    required this.name,
    this.city,
    this.description,
    this.logoURL,
    required this.organizerUid,
    this.createdAt,
    this.memberCount,
    this.tags,
  });

  factory Club.fromMap(Map<String, dynamic> map, String id) {
    return Club(
      id: id,
      name: map['name'],
      city: map['city'],
      description: map['description'],
      logoURL: map['logoURL'],
      organizerUid: map['organizerUid'],
      createdAt: map['createdAt'],
      memberCount: map['memberCount'],
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'city': city,
      'description': description,
      'logoURL': logoURL,
      'organizerUid': organizerUid,
      'createdAt': createdAt,
      'memberCount': memberCount,
      'tags': tags,
    };
  }
}

/// Post document stored in /posts
class Post {
  final String? id;
  final String authorUid;
  final String content;
  final Timestamp? createdAt;
  final String visibility;
  final String? linkedRunId;
  final String? clubId;
  final int? likeCount;
  final int? commentCount;

  Post({
    this.id,
    required this.authorUid,
    required this.content,
    this.createdAt,
    required this.visibility,
    this.linkedRunId,
    this.clubId,
    this.likeCount,
    this.commentCount,
  });

  factory Post.fromMap(Map<String, dynamic> map, String id) {
    return Post(
      id: id,
      authorUid: map['authorUid'],
      content: map['content'],
      createdAt: map['createdAt'],
      visibility: map['visibility'],
      linkedRunId: map['linkedRunId'],
      clubId: map['clubId'],
      likeCount: map['likeCount'],
      commentCount: map['commentCount'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorUid': authorUid,
      'content': content,
      'createdAt': createdAt,
      'visibility': visibility,
      'linkedRunId': linkedRunId,
      'clubId': clubId,
      'likeCount': likeCount,
      'commentCount': commentCount,
    };
  }
}

/// Run data
class Run {
  final String? id;
  final String? uid;
  final double distance;
  final int time;
  final double pace;
  final List<Map<String, double>> path;
  final Timestamp? createdAt;

  Run({
    this.id,
    this.uid,
    required this.distance,
    required this.time,
    required this.pace,
    required this.path,
    this.createdAt,
  });

  factory Run.fromMap(Map<String, dynamic> map, String id) {
    // Convert path items to Map<String, double>
    final pathList = (map['path'] as List?)?.map((item) {
      if (item is Map) {
        return {
          'latitude': (item['latitude'] as num).toDouble(),
          'longitude': (item['longitude'] as num).toDouble(),
        };
      }
      return item as Map<String, double>;
    }).toList() ?? [];
    
    return Run(
      id: id,
      uid: map['uid'],
      distance: (map['distance'] as num).toDouble(),
      time: map['time'],
      pace: (map['pace'] as num).toDouble(),
      path: List<Map<String, double>>.from(pathList),
      createdAt: map['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'distance': distance,
      'time': time,
      'pace': pace,
      'path': path,
      'createdAt': createdAt,
    };
  }
}
