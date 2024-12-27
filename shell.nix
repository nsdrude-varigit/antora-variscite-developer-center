{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.python3
    pkgs.python3Packages.pyaml
    pkgs.nodejs
  ];

  shellHook = ''
    echo "Welcome to the project shell environment!"
  '';
}
