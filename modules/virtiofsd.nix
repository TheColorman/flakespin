{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) int str;
  inherit (lib.modules) mkIf;
  inherit (config) name;

  cfg = config.virtiofsd;
in {
  options.virtiofsd = {
    enable = mkEnableOption "virtiofsd";
    stateDirectory = mkOption {
      type = str;
      description = ''
        Path to directory where metadata about virtiofsd will be stored.
      '';
      default = "/tmp/virtiofsd-${name}";
    };
    sharedDir = mkOption {
      type = str;
      description = "Path to directory shared by virtiofsd";
    };
    socketWaitTimeout = mkOption {
      type = int;
      description = ''
        Timeout in seconds to wait for virtiofsd socket to be created.
      '';
      default = 10;
      apply = value: builtins.toString value;
    };
    shareName = mkOption {
      type = str;
      description = "Name of the shared directory as seen by the guest.";
      default = "virtiofsd";
    };
  };

  config = let
    socketPath = "${cfg.stateDirectory}.sock";
    pidPath = "${cfg.stateDirectory}.pid";
    pidFile = "${cfg.stateDirectory}_pid";
  in
    mkIf cfg.enable {
      runtimeInputs = [pkgs.virtiofsd];

      preStartup = ''
        echo "Setting up virtiofsd..."
        echo "Deleting old files..."
        sudo rm -f ${socketPath} ${pidPath} ${pidFile}

        echo "Authenticating with sudo"
        sudo -v

        echo "Starting virtiofsd..."
        sudo virtiofsd --socket-path="${socketPath}" --shared-dir="${cfg.sharedDir}" &

        VIRTIO_PID=$!
        echo "$VIRTIO_PID" > "${pidFile}"

        start_wait=$(date +%s)
        while [ ! -S "${socketPath}" ]; do
          if [ $(($(date +%s) - start_wait)) -gt "${cfg.socketWaitTimeout}" ]; then
            echo "Error: Timeout waiting for virtiofsd socket ${socketPath}"
            # No need to call cleanup explicitly, trap will handle it via EXIT
            exit 1
          fi
          sleep 0.1
        done

        echo "virtiofsd started with PID $VIRTIO_PID, socket at ${socketPath}"
      '';

      cleanupScripts = ''
        if [ -f "${pidFile}" ]; then
        	VIRTIOFSD_PID=$(<"${pidFile}")
        	echo "Shutting down virtiofsd (PID: $VIRTIOFSD_PID)..."
        	if [ -n "$VIRTIOFSD_PID" ]; then
        		sudo kill -TERM "$VIRTIOFSD_PID" 2>/dev/null
        		sleep 2
        		if ps -p "$VIRTIOFSD_PID" > /dev/null; then
        			echo "virtiofsd did not shut down gracefully, killing it..."
        			sudo kill -KILL "$VIRTIOFSD_PID" 2>/dev/null
        		fi
        	fi

        else
        	echo "No virtiofsd PID file found (${pidFile}), nothing to kill."
        fi

        echo "Removing socket file: ${socketPath}"
        sudo rm -rf "${socketPath}" "${pidPath}" "${pidFile}"
      '';

      qemuArgs = [
        "-chardev socket,id=char0,path=${socketPath}"
        "-device vhost-user-fs-pci,chardev=char0,tag=${cfg.shareName}"
      ];
    };
}
