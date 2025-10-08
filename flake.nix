{
  description = "SEGGER xtc-tools";

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs.lib) genAttrs;

      systems = [ "x86_64-linux" ];

      packages = genAttrs systems (
        system:
        let
          xtc-tools =
            (import nixpkgs {
              inherit system;
              overlays = [ self.overlays.default ];
              config.allowUnfree = true;
            }).xtc-tools;
        in
        {
          inherit xtc-tools;
          default = xtc-tools;
        }
      );

      overlay = final: prev: {
        xtc-tools = final.callPackage ./pkgs/xtc-tools { };
      };

      nixosModule =
        { pkgs, ... }:
        {
          nixpkgs.overlays = [ self.overlays.default ];
          services.udev.packages = [ pkgs.xtc-tools ];
          environment.systemPackages = [ pkgs.xtc-tools ];
        };
    in
    {
      inherit packages overlay nixosModule;

      nixosModules.default = nixosModule;

      overlays.default = overlay;

      apps = genAttrs systems (
        system:
        let
          mkApp = program: {
            type = "app";
            program = "${packages.${system}.xtc-tools}/bin/${program}";
          };
        in
        {
          xflash = mkApp "xflash";
        }
      );
    };
}
