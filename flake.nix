{
  description = "Reusable Firat Ozcan command-line tools";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs, ... }: let
    supportedSystems = [
      "aarch64-darwin"
      "x86_64-darwin"
      "aarch64-linux"
      "x86_64-linux"
    ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    mkGuardedRipgrep = pkgs: let
      ps = if pkgs.stdenv.hostPlatform.isDarwin then "/bin/ps" else "${pkgs.procps}/bin/ps";
    in pkgs.writeShellApplication {
      name = "rg";
      runtimeInputs = [ pkgs.coreutils pkgs.git pkgs.jq ];
      text = ''
        export RG_GUARD_REAL_RG=${pkgs.lib.escapeShellArg "${pkgs.ripgrep}/bin/rg"}
        export RG_GUARD_TIMEOUT=${pkgs.lib.escapeShellArg "${pkgs.coreutils}/bin/timeout"}
        export RG_GUARD_JQ=${pkgs.lib.escapeShellArg "${pkgs.jq}/bin/jq"}
        export RG_GUARD_GIT=${pkgs.lib.escapeShellArg "${pkgs.git}/bin/git"}
        export RG_GUARD_PS=${pkgs.lib.escapeShellArg ps}
        ${builtins.readFile ./tools/guarded-ripgrep/rg-guard.bash}
      '';
    };
  in {
    packages = forAllSystems (system: let
      guardedRipgrep = mkGuardedRipgrep nixpkgs.legacyPackages.${system};
    in {
      default = guardedRipgrep;
      guarded-ripgrep = guardedRipgrep;
    });

    homeManagerModules.default = { config, lib, pkgs, ... }: let
      cfg = config.programs.guarded-ripgrep;
      defaultPackage = self.packages.${pkgs.stdenv.hostPlatform.system}.guarded-ripgrep;
      shellFunction = ''
        rg() {
          ${cfg.package}/bin/rg "$@"
        }
      '';
    in {
      options.programs.guarded-ripgrep = {
        enable = lib.mkEnableOption "guarded ripgrep command interception";
        package = lib.mkOption {
          type = lib.types.package;
          default = defaultPackage;
          description = "The guarded ripgrep package invoked by shell command lookup.";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ cfg.package ];
        home.file.".local/bin/rg" = {
          force = true;
          source = "${cfg.package}/bin/rg";
        };
        programs.zsh.envExtra = lib.mkBefore shellFunction;
        programs.bash.initExtra = lib.mkBefore shellFunction;
        programs.bash.profileExtra = lib.mkBefore shellFunction;
      };
    };

    homeManagerModules.guarded-ripgrep = self.homeManagerModules.default;
  };
}
