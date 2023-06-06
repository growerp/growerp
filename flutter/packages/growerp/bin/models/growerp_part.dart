enum GrowerpPart {
  frontend,
  backend,
  chat,
  all,
  unknown;

  static GrowerpPart parse(String val) {
    switch (val.toLowerCase()) {
      case 'frontend':
        return frontend;
      case 'backend':
        return backend;
      case 'chat':
        return chat;
      case 'all':
      case 'full':
        return all;
      default:
        return unknown;
    }
  }
}
