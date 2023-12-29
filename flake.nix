{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};

      pyhidapi = pkgs.python3Packages.buildPythonPackage rec {
        pname = "pyhidapi";
        version = "0.0.2";
        pyproject = true;

        src = pkgs.fetchPypi {
          inherit pname version;
          hash = "sha256-Zfk6/N787UdCTpJykLW+1ILVjCZmMobBt0EG4MCioxs=";
        };

        patches = [./pyhidapi.patch];

        nativeBuildInputs = with pkgs.python3Packages; [setuptools];
      };
      pythonEnv = pkgs.python3.withPackages (ps: with ps; [pyhidapi pillow]);

      date = inputs.self.lastModifiedDate or inputs.self.lastModified or "19700101";
      commit = inputs.self.shortRev or "dirty";
      package = pkgs.stdenv.mkDerivation {
        pname = "led-badge";
        version = "${builtins.substring 0 8 date}+${commit}";
        src = ./.;

        nativeBuildInputs = with pkgs; [makeWrapper];

        buildInputs = [pythonEnv];

        buildPhase = ''
          mkdir -p $out/bin
          cp -a led-badge-11x44.py $out/bin/led-badge-11x44.py
        '';

        installPhase = ''
          wrapProgram $out/bin/led-badge-11x44.py \
            --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [pkgs.hidapi]}
        '';
      };
    in {
      packages.default = package;
      devShells.default = pkgs.mkShell {
        packages = [
          pythonEnv
        ];

        LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (with pkgs; [hidapi]);
      };
    });
}
