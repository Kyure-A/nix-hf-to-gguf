{
  description = "llama.cpp convert_hf_to_gguf CLI wrapped for Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    llama-cpp.url = "github:ggerganov/llama.cpp";
  };

  outputs = { self, nixpkgs, flake-utils, llama-cpp }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          torch
          transformers
          safetensors
          # huggingface_hub
          sentencepiece
        ]);
        convert-cli = pkgs.stdenv.mkDerivation rec {
          pname = "convert-hf-to-gguf-cli";
          version = "0.1.0";
          src = llama-cpp;
          nativeBuildInputs = [ pkgs.makeWrapper ];
          propagatedBuildInputs = [ pythonEnv ];
          configurePhase = "true";
          buildPhase     = "true";
          installPhase = ''
            mkdir -p $out/bin
            makeWrapper ${pythonEnv}/bin/python $out/bin/${pname} --add-flags "$src/convert_hf_to_gguf.py"
          '';
        };
      in {
        packages.default = convert-cli;
        apps.convert-hf-to-gguf = flake-utils.lib.mkApp {
          drv = convert-cli;
          name = "convert-hf-to-gguf";
        };
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pythonEnv
            pkgs.cmake
            pkgs.gcc
          ];
        };
      });
}
