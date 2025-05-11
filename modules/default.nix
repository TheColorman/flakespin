pkgs: module: let
  result = pkgs.lib.evalModules {
    modules = [
      {_module.args = {inherit pkgs;};}
      module
      ./generic.nix
      ./virtiofsd.nix
      ./installation.nix
      ./tpm.nix
      ./audio.nix
      ./network.nix
    ];
  };
  inherit (result) config;
in
  pkgs.writeShellApplication {
    name = config.command;

    inherit (config) runtimeInputs;

    # "Command appears to be unreachable" does not work for traps
    excludeShellChecks = ["SC2317"];

    text = ''
      cleanup() {
        set +e # want to ignore errors in cleanup
        echo "Running post-exit cleanup..."
      	${config.cleanupScripts}
      }

      trap cleanup EXIT INT TERM

      echo "Running pre-startup scripts..."
      ${config.preStartup}

      echo "Starting QEMU VM..."
      sudo --preserve-env=XDG_RUNTIME_DIR \
        qemu-system-x86_64 ${config.qemuArgs}

      echo "QEMU process exited"

      exit 0
    '';
  }
