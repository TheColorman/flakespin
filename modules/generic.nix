{
  pkgs,
  config,
  ...
}: {
  options = let
    inherit (pkgs.lib.options) mkOption;
    inherit (pkgs.lib.types) str lines strMatching listOf package;
  in {
    name = mkOption {
      type = str;
      description = ''
        Name of the executable that will boot the VM and its configuration
        files
      '';
    };

    cleanupScripts = mkOption {
      type = lines;
      description = ''
        Script to run after a VM has shut down for cleanup up residual files
      '';
      default = "";
    };

    preStartup = mkOption {
      type = lines;
      description = ''
        Script to run before starting the VM
      '';
      default = "";
    };

    qemuArgs = mkOption {
      type = listOf str;
      description = ''
        List of arguments to pass to QEMU
      '';
      apply = value: builtins.concatStringsSep " " value;
      example = [
        "-netdev socket,id=mynet0,liste=:1234"
      ];
    };

    runtimeInputs = mkOption {
      type = listOf package;
      description = ''
        List of packages to include as runtime inputs for the final script
      '';
    };

    drive.cdroms = mkOption {
      type = listOf str;
      description = ''
        List of paths to image files that will be attached to the VM as CDROMs
      '';
      default = [];
    };

    base = {
      disk = {
        size = mkOption {
          type = strMatching "[0-9]+G";
          description = ''
            Size of the VM disk image. This is the size of the virtual disk
            that will be created if it does not exist.
          '';
          default = "20G";
        };
        path = mkOption {
          type = str;
          description = ''
            Path to the VM disk image that will be created. Defaults to
            working directory
          '';
          default = "./${config.name}.qcow2";
        };
      };
      memory = mkOption {
        type = strMatching "[0-9]+M";
        description = ''
          Amount of memory to allocate to the VM in megabytes. Defaults to
          16384M, or 16G.
        '';
        default = "16384M";
      };
    };
  };

  config = {
    preStartup = let
      inherit (config.base.disk) size path;
    in ''
      if ! [ -f "${path}" ]; then
        echo "No VM disk image found, creating ${size} image..."
        qemu-img create -f qcow2 "${path}" ${size}
      fi
    '';

    runtimeInputs = [pkgs.qemu];

    qemuArgs =
      [
        "-enable-kvm"
        "-m ${config.base.memory}"
        "-cpu host"
        "-drive \"file=${config.base.disk.path},if=virtio,cache=none,aio=native\""
        "-machine type=q35,accel=kvm"
        "-smp cores=6,sockets=1,threads=1"
        "-vga virtio"
        "-display sdl,show-cursor=off"
        "-object memory-backend-memfd,id=mem,size=${config.base.memory},share=on"
        "-numa node,nodeid=0,cpus=0-5,memdev=mem"
      ]
      ++ (builtins.map (p: "-drive \"file=${p},format=raw,media=cdrom\"") config.drive.cdroms);
  };
}
