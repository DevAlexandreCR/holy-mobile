enum UserRole {
  user('user', 'Usuario', 'Acceso normal a la aplicación'),
  editor('editor', 'Editor', 'Gestión de contenido'),
  lead('lead', 'Líder', 'Gestión de equipo y analíticas'),
  admin('admin', 'Administrador', 'Acceso completo al sistema');

  final String value;
  final String displayName;
  final String description;

  const UserRole(this.value, this.displayName, this.description);

  static UserRole fromString(String value) {
    final normalized = value.toLowerCase();
    for (final role in UserRole.values) {
      if (role.value == normalized) return role;
    }
    return UserRole.user;
  }

  bool get isAdmin => this == UserRole.admin;
  bool get canManageUsers => this == UserRole.admin || this == UserRole.lead;
  bool get canEditContent =>
      this == UserRole.admin || this == UserRole.lead || this == UserRole.editor;
}
