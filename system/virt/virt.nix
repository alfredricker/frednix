{ pkgs, lib, ... }:

let
  # RTX 5070 Ti PCI addresses
  gpuVideo = "0000:01:00.0";
  gpuAudio = "0000:01:00.1";

  # Script run by libvirt before/after the win11 VM starts/stops.
  # prepare/begin  → strip nvidia, hand card to vfio-pci
  # release/end    → return card to nvidia
  qemuHook = pkgs.writeShellScript "qemu-hook" ''
    exit 0
  '';
in
{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      swtpm.enable = true; # TPM 2.0 emulation — required for Windows 11
      runAsRoot = false;
    };
    hooks.qemu = {
      vfio-passthrough = "${qemuHook}";
    };
  };

  users.users.fred.extraGroups = [
    "libvirtd"
    "kvm"
  ];

  # Strip the TPM-sealed credential requirement — we don't use libvirt secrets encryption.
  # The upstream unit sets LoadCredentialEncrypted which breaks after kernel param changes.
  systemd.services.libvirtd.serviceConfig.LoadCredentialEncrypted = lib.mkForce "";
  # Make the encryption-key init a no-op rather than masking it (socket depends on it existing).
  systemd.services.virt-secret-init-encryption.serviceConfig.ExecStart = lib.mkForce "${pkgs.coreutils}/bin/true";

  # /dev/shm/looking-glass — shared memory frame relay between Windows VM and client.
  # Size: 128 MiB covers up to 4K. Must match the IVSHMEM size in win11.xml.
  systemd.tmpfiles.rules = [
    "f /dev/shm/looking-glass 0666 fred kvm -"
  ];

  environment.systemPackages = with pkgs; [
    looking-glass-client
    virtiofsd
    spice-gtk
  ];

  # Sync ~/virt/win11.xml → /var/lib/libvirt/qemu/win11.xml on any save.
  systemd.services.sync-win11-xml = {
    description = "Sync win11.xml into libvirt";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/cp /etc/nixos/system/virt/win11.xml /var/lib/libvirt/qemu/win11.xml";
    };
  };

  systemd.paths.sync-win11-xml = {
    description = "Watch /etc/nixos/system/virt/win11.xml for changes";
    wantedBy = [ "multi-user.target" ];
    pathConfig.PathChanged = "/etc/nixos/system/virt/win11.xml";
  };

  # virtiofsd daemon sharing ~/Media/Music into the VM.
  # Socket at /run/virtiofsd/music.sock — reference this in the VM XML.
  systemd.services.virtiofsd-music = {
    description = "virtiofsd share: Music";
    after = [ "local-fs.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      # --shared-dir: share the whole Music tree so projects + presets are visible
      ExecStart = "${pkgs.virtiofsd}/bin/virtiofsd --socket-path=/run/virtiofsd/music.sock --shared-dir=/home/fred/Media/Music --sandbox=namespace";
      # Poll until the socket appears, then open permissions so libvirtd can connect
      ExecStartPost = pkgs.writeShellScript "virtiofsd-chmod" ''
        for i in $(seq 1 50); do
          [ -S /run/virtiofsd/music.sock ] && exec ${pkgs.coreutils}/bin/chmod 0777 /run/virtiofsd/music.sock
          sleep 0.1
        done
        echo "virtiofsd socket did not appear" >&2; exit 1
      '';
      RuntimeDirectory = "virtiofsd";
      RuntimeDirectoryMode = "0755";
      UMask = "0000";
      User = "fred";
      Group = "users";
      Restart = "always";
    };
  };
}
