{
  description = "Hunspell dictionary utility flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs =
    { self, ... }@inputs:
    let
      inherit (inputs.nixpkgs) lib;

      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      forEachSupportedSystem =
        f:
        lib.genAttrs supportedSystems (
          system:
          f {
            inherit system;
            pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs, system }:
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              self.formatter.${system}
              pkgs.hunspell
            ];
          };
        }
      );

      legacyPackages = forEachSupportedSystem (
        { pkgs, system }:
        {
          mkHunspellDictionary = pkgs.callPackage ./pkgs/hunspell-dictionary { };
        }
      );

      packages = forEachSupportedSystem (
        { pkgs, system }:
        {
          cloud-services = self.outputs.legacyPackages.${system}.mkHunspellDictionary {
            name = "cloud-services";
            terms = [
              "EC2"
              "S3"
            ];
          };

          demo-hunspell = pkgs.hunspell.withDicts (d: [ self.outputs.packages.${system}.cloud-services ]);
        }
      );

      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt);
    };
}
