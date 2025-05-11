# flakespin

Flakespin is a configuration framework for configuring VMs using Nix.

This was made entirely for personal use, so many aspects may be very
opinionated, and lots of QEMU features do not have modules.

## Usage

Flakespin currently requires flakes as I have no reason to personally make it
compatible with non-flake systems. If you want to open a PR, go ahead.

Basic usage in a flake:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; 
    # Note that some versions of nixpkgs have nonfunctional QEMU versions, so
    # set 'follows = "nixpkgs"' at your own risk.
    flakespin.url = "github:thecolorman/flakespin";
  };

  outputs = { flakespin, ... }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system}.default = flakespin.lib.mkVm {
      inherit pkgs;
      modules = [ ./machine.nix ];
    };
  }
}
```

and `machine.nix`:

```nix
{
  command = "win";
  base.disk.size = "150G";
  virtiofsd = {
    enable = true;
    sharedDir = "~";
    shareName = "linux_home";
  };
  tpm.enable = true;
  audio.enable = true;
}
```

### Installing an OS

To actually boot, you need to first install an operating system by inserting a
bootable disk. This is done with the `installation` option. For example, if you
want to install Windows, you might take the above config and add the following
lines:

```diff nix
{
  command = "win";
  base.disk.size = "150G";
  virtiofsd = {
    enable = true;
    sharedDir = "~";
    shareName = "linux_home";
  };
  tpm.enable = true;
  audio.enable = true;

+  # Enable these for installation
+  network.enable = false;
+  installation = "~/Downloads/Win11_24H2_EnglishInternational_x64.iso";
+  drive.cdroms = ["~/Downloads/virtio-win-0.1.271.iso"];
}
```

This will first disable internet (to bypass online requirement), then set up the
disk at `~/Downloads/Win11_24H2_EnglishInternational_x64.iso` as the
installation disk, and finally add the disk at
`~/Downloads/virtio-win-0.1.271.iso` which will mount the necessary virtio disk
drivers that are required for installing Windows with QEMU.
