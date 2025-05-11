{
  command = "ubu";
  virtiofsd = {
    enable = true;
    sharedDir = "\${HOME}";
    shareName = "host_home";
  };
}
