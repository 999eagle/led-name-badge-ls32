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
        postPatch = ''
          substituteInPlace pyhidapi/pyhidapi.py \
            --replace-fail '@hidapi_libusb@' '${pkgs.hidapi}/lib/libhidapi-libusb.so'
        '';

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
          mkdir -p $out/bin $out/etc/udev/rules.d
          cp -a lednamebadge.py $out/bin/
          cp -a 99-led-badge-44x11.rules $out/etc/udev/rules.d/
        '';

        meta.mainProgram = "lednamebadge.py";
      };
    in {
      packages.default = package;
      devShells.default = pkgs.mkShell {
        packages = [
          pythonEnv
        ];
      };
    });
}
