enum Role { owner, driver }

class User {
  const User({required this.id, required this.role, required this.name, required this.login});

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] as int,
        role: j['role'] == 'owner' ? Role.owner : Role.driver,
        name: j['name'] as String,
        login: j['login'] as String,
      );

  final int id;
  final Role role;
  final String name;
  final String login;

  String get firstName => name.split(' ').first;
}

class Session {
  const Session({required this.token, required this.user});
  final String token;
  final User user;
}
