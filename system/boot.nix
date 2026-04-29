{ config, pkgs, lib, ... }:
{ 
 # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      # do NOT remove this
      efi.canTouchEfiVariables = true;
      # can change to GRUB
      systemd-boot.enable = true;
    };
    #
    plymouth = {
      enable = true;
      theme = "rings";
      themePackages = with pkgs; [
        # install all themes
        (adi1090x-plymouth-themes.override {
          selected_themes = [ "rings" ];
        })
      ];
    };
    # enable silent boot
    consoleLogLevel = 3;
    # rd shiz
    initrd = {
      verbose = false;
      systemd.enable = true;
      kernelModules = [ "amdgpu" "vfio" "vfio_iommu_type1" "vfio_pci" ];
    };
    kernelModules = [ "kvm-amd" ];
    # Claim the RTX at boot before nvidia can touch it
    extraModprobeConfig = ''
      options vfio-pci ids=10de:2c05,10de:22e9
    '';
    kernelParams = [
      "quiet" "udev.log_level=3" "systemd.show_status=auto"
      "boot.shell_on_fail"
      "amd_iommu=on" "iommu=pt"
    ];
  };

  # --- Greetd Boot ---
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "niri-session";
        user = "fred";
      };
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
        user = "greeter";
      };
    };
  };
}
