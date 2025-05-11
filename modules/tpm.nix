{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) str int;
  inherit (lib.modules) mkIf;
  inherit (config) name;

  cfg = config.tpm;

  socketPath = "${cfg.stateDirectory}/swtpm-sock";
  pidFile = "${cfg.stateDirectory}/swtpm.pid";
in {
  options.tpm = {
    enable = mkEnableOption "tpm";
    stateDirectory = mkOption {
      type = str;
      description = ''
        Path the directory the swtpm service will store state in.
      '';
      default = "/tmp/vm/${name}/tpm_state";
    };
    socketWaitTimeout = mkOption {
      type = int;
      default = 10;
      apply = value: builtins.toString value;
    };
  };

  config = mkIf cfg.enable {
    runtimeInputs = [pkgs.swtpm];

    preStartup = ''
      echo "Setting up swtpm..."
      echo "Ensuring directories exist"
      mkdir -p "${cfg.stateDirectory}"

      echo "Cleaning up old files..."
      rm -f "${socketPath}"

      echo "Starting swtpm..."
      swtpm socket --daemon --tpm2 --tpmstate dir=${cfg.stateDirectory} \
        --ctrl type=unixio,path="${socketPath}" --pid file=${pidFile}

      start_wait=$(date +%s)
      while [ ! -S "${socketPath}" ]; do
        if [ $(($(date +%s) - start_wait)) -gt "${cfg.socketWaitTimeout}" ]; then
          echo "Error: Timeout waiting for swtpm socket ${socketPath}"
          # No need to call cleanup explicitly, trap will handle it via EXIT
          exit 1
        fi
        sleep 0.1
      done

      SWTPM_PID=$(<"${pidFile}")
      echo "swtpm started with PID $SWTPM_PID, socket at ${socketPath}"
    '';

    cleanupScripts = ''
      if [ -f "${pidFile}" ]; then
      	SWTPM_PID=$(<"${pidFile}")
      	echo "Shutting down swtpm (PID: $SWTPM_PID)..."
      	if [ -n "$SWTPM_PID" ]; then
      		sudo kill -TERM "$SWTPM_PID" 2>/dev/null
      		sleep 2
      		if ps -p "$SWTPM_PID" > /dev/null; then
      			echo "swtpm did not shut down gracefully, killing it..."
      			sudo kill -KILL "$SWTPM_PID" 2>/dev/null
      		fi
      	fi

      else
      	echo "No swtpm PID file found (${pidFile}), nothing to kill."
      fi

      echo "Removing socket file: ${socketPath}"
      sudo rm -rf "${socketPath}"
    '';

    qemuArgs = [
      "-chardev socket,id=chartpm,path=${socketPath}"
      "-tpmdev emulator,id=tpm0,chardev=chartpm"
      "-device tpm-tis,tpmdev=tpm0"
    ];
  };
}
