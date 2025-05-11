{
  config,
  lib,
  ...
}: let
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) enum;
  inherit (lib.modules) mkIf;

  devices = {
    "intel-hda" = [
      "-device intel-hda"
      "-device hda-duplex,audiodev=pw0"
    ];
    "virtio" = [
      "-device virtio-sound-pci,audiodev=pw0"
    ];
  };

  cfg = config.audio;
in {
  options.audio = {
    enable = mkEnableOption "audio";
    device = mkOption {
      type = enum (builtins.attrNames devices);
      description = ''
        Which audio device to use. Windows guests only support intel-hda.
      '';
      default = "intel-hda";
    };
  };

  config.qemuArgs = mkIf cfg.enable (
    [
      "-audiodev pipewire,id=pw0,out.name=VM_Playback,in.name=VM_Capture,out.latency=20000,in.latency=20000"
    ]
    ++ devices.${cfg.device}
  );
}
