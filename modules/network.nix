{
  config,
  lib,
  ...
}: let
  inherit (lib.types) bool;
  inherit (lib.options) mkOption;
  inherit (lib.modules) mkIf;

  cfg = config.network;
in {
  options.network.enable = mkOption {
    type = bool;
    description = ''
      Enable networking. If set to true, the VM will be without
      internet. Useful for Windows installations.
    '';
    default = true;
  };

  config.qemuArgs = mkIf (!cfg.enable) [
    "-nic none"
  ];
}
