# To learn more about how to use Nix to configure your environment
# see: https://firebase.google.com/docs/studio/customize-workspace
{ pkgs, ... }: {
  # Which nixpkgs channel to use.
  channel = "stable-24.05"; # or "unstable"
  # Use https://search.nixos.org/packages to find packages
  packages = [
    pkgs.jdk17
    pkgs.jdk11
    pkgs.unzip
    pkgs.cmake
    pkgs.ninja
    pkgs.clang
    pkgs.pkg-config
    pkgs.libgtkflow3
    pkgs.gtk3-x11
    pkgs.gtk3
    pkgs.flutter
  ];
  # Sets environment variables in the workspace
  env = {JDK11 = "${pkgs.jdk11}";
  };
  idx = {
    # Search for the extensions you want on https://open-vsx.org/ and use "publisher.id"
    extensions = [
      "Dart-Code.flutter"
      "Dart-Code.dart-code"
    ];
    workspace = {
      # Runs when a workspace is first created with this `dev.nix` file
      onCreate = {          # Runs when a workspace is first created with this \`dev.nix\` file
          shellScript = ''
            cd flutter
            dart pub global activate melos
            melos clean
            melos bootstrap
            melos build --no-select
            melos l10n --no-select
            cd ../moqui
            export JAVA_HOME=$JDK11
            ./gradlew build
            $JDK11/bin/java -jar moqui.war load types=seed,seed-initial,install no-run-es
          '';
          };
      onStart = {
         shellScript = ''
            cd moqui
            $JDK11/bin/java -jar moqui.war no-run-es
          '';
          };
    };
    # Enable previews and customize configuration
    previews = {
      enable = true;
      previews = {
        web = {
          cwd = "flutter/packages/admin";
          command = ["flutter" "run" "--machine" "-d" "web-server" "--web-hostname" "0.0.0.0" "--web-port" "$PORT"];
          manager = "flutter";
        };
        android = {
          cwd = "flutter/packages/admin";
          command = ["flutter" "run" "--machine" "-d" "android" "-d" "localhost:5555"];
          manager = "flutter";
        };
      };
    };
  };
}
