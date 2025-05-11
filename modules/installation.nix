{
  config,
  lib,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.types) str nullOr;
  inherit (lib.modules) mkIf;

  cfg = config.installation;
in {
  options.installation = mkOption {
    type = nullOr str;
    description = ''
      Path to an image file that contains installation media. The VM will boot
      from this file when the option is specified. Used for initial
      installation.
    '';
    default = null;
  };

  config = mkIf (cfg != null) {
    drive.cdroms = [cfg];
    qemuArgs = [
      "-boot d"
    ];
  };
}
