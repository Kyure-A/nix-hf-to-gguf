{
  description = "nix-hf-to-gguf";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));
    in
      {
        packages = forAllSystems (pkgs: rec {
          gguf-convert = pkgs.stdenv.mkDerivation {
            pname    = "gguf-convert";
            version  = "0.1";

            src = ./.;

            nativeBuildInputs = [ pkgs.makeWrapper ];

            buildInputs = [
              pkgs.llama-cpp
              pkgs.python3Packages.safetensors
              pkgs.python3Packages.numpy
            ];

            installPhase = ''
          mkdir -p $out/bin
          cp bin/gguf-convert $out/bin/
          substituteInPlace $out/bin/gguf-convert \
            --replace "@CONVERTPY@" "${pkgs.llama-cpp}/share/llama.cpp/convert.py"
          chmod +x $out/bin/gguf-convert
        '';
          };
        });

        defaultPackage = forAllSystems (pkgs: self.packages.${pkgs.system}.gguf-convert);

        devShells = forAllSystems (pkgs: {
          default = pkgs.mkShell {
            buildInputs = [
              pkgs.llama-cpp
              pkgs.python3Packages.safetensors
              pkgs.python3Packages.numpy
            ];
          };
        });
      };
}
