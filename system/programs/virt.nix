{ pkgs, ... }:

{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      swtpm.enable = true;  # TPM 2.0 emulation — required for Windows 11
      runAsRoot = false;
    };
  };

  # SPICE USB redirection daemon (lets virt-viewer pass USB devices into the VM)
  virtualisation.spiceUSBRedirection.enable = true;

  users.users.fred.extraGroups = [ "libvirtd" ];

  environment.systemPackages = with pkgs; [
    virt-manager    # full GUI for VM setup/config
    virt-viewer     # lightweight SPICE window for daily use
    spice-gtk       # SPICE client libs (needed by virt-viewer)
    virtio-win      # VirtIO drivers ISO to load during Tiny11 install
    virtiofsd       # host-side daemon for virtiofs shared folders
  ];

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
      Restart = "on-failure";
    };
  };
}
