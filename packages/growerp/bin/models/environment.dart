enum Environment {
  development,
  release,
  full,
  unknown;

  static Environment parse(String val) {
    switch (val.toLowerCase()) {
      case '-dev':
        return development;
      case '-rel':
        return release;
      case 'full':
        return full;
      default:
        return unknown;
    }
  }
}
