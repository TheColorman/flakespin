{
  name = "win";
  base.disk.size = "150G";
  virtiofsd = {
    enable = true;
    sharedDir = "~";
    shareName = "linux_home";
  };
  tpm.enable = true;
  audio.enable = true;

  # Enable these for installation
  # network.enable = false;
  # installation = "~/Downloads/Win11_24H2_EnglishInternational_x64.iso";
  # drive.cdroms = ["~/Downloads/virtio-win-0.1.271.iso"];
}
