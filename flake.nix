{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  }:
    {
      lib = import ./lib;
    }
    // (
      let
        forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
      in {
        packages = forAllSystems (system: let
          mkVm = modulePath:
            self.lib.mkVm modulePath {
              pkgs = nixpkgs.legacyPackages.${system};
            };
        in {
          ubuntu = mkVm ./examples/ubuntu.nix;
          windows = mkVm ./examples/windows.nix;
        });
      }
    );
}
