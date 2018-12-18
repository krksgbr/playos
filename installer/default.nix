# Build NixOS system
{config, lib, pkgs,
 version, grubCfg, toplevel
 }:
let

  nixos = pkgs.importFromNixos "";

  install-playos = (import ./install-playos) {
    inherit (pkgs) stdenv substituteAll makeWrapper python36 utillinux e2fsprogs dosfstools closureInfo pv;
    inherit grubCfg toplevel version;
    grub2 = (pkgs.grub2.override { efiSupport = true; });
  };

  configuration = (import ./configuration.nix) {
    inherit config pkgs lib install-playos version;
  };

in
  {
    inherit install-playos;

    isoImage = (nixos {
      inherit configuration;
      system = "x86_64-linux";
    }).config.system.build.isoImage;

  }

