{ pkgs, ... }:

let
  gpuVideo = "0000:01:00.0";
  gpuAudio = "0000:01:00.1";

  gpu-switch = pkgs.writeShellScriptBin "gpu-switch" ''
    set -euo pipefail

    GPU_VIDEO="${gpuVideo}"
    GPU_AUDIO="${gpuAudio}"

    get_driver() {
      local dev="/sys/bus/pci/devices/$1/driver"
      [ -L "$dev" ] && basename "$(readlink "$dev")" || echo "none"
    }

    enable_nvidia() {
      echo "Unbinding from vfio-pci..."
      echo "$GPU_VIDEO" > /sys/bus/pci/drivers/vfio-pci/unbind
      echo "$GPU_AUDIO" > /sys/bus/pci/drivers/vfio-pci/unbind 2>/dev/null || true

      echo "Setting driver overrides..."
      echo "nvidia"        > /sys/bus/pci/devices/$GPU_VIDEO/driver_override
      echo "snd_hda_intel" > /sys/bus/pci/devices/$GPU_AUDIO/driver_override

      echo "Loading nvidia modules..."
      modprobe nvidia
      modprobe nvidia_modeset
      modprobe nvidia_uvm
      modprobe nvidia_drm modeset=1

      echo "Probing drivers..."
      echo "$GPU_VIDEO" > /sys/bus/pci/drivers_probe
      echo "$GPU_AUDIO" > /sys/bus/pci/drivers_probe 2>/dev/null || true

      echo "Done. Verify with: nvidia-smi"
    }

    disable_nvidia() {
      local force="''${1:-}"

      if command -v nvidia-smi &>/dev/null; then
        pids=$(nvidia-smi --query-compute-apps=pid --format=csv,noheader 2>/dev/null || true)
        if [ -n "$pids" ]; then
          echo "GPU in use by PIDs: $pids"
          [ "$force" = "--force" ] || { echo "Pass --force to kill them."; exit 1; }
          echo "$pids" | xargs -r kill -9
          sleep 1
        fi
      fi

      echo "Unloading nvidia modules..."
      modprobe -r nvidia_drm    2>/dev/null || true
      modprobe -r nvidia_modeset 2>/dev/null || true
      modprobe -r nvidia_uvm    2>/dev/null || true
      modprobe -r nvidia        2>/dev/null || true

      echo "Resetting driver overrides..."
      printf '' > /sys/bus/pci/devices/$GPU_VIDEO/driver_override
      printf '' > /sys/bus/pci/devices/$GPU_AUDIO/driver_override 2>/dev/null || true

      echo "Binding back to vfio-pci..."
      echo "$GPU_VIDEO" > /sys/bus/pci/drivers/vfio-pci/bind
      echo "$GPU_AUDIO" > /sys/bus/pci/drivers/vfio-pci/bind 2>/dev/null || true

      echo "Done. GPU returned to vfio-pci."
    }

    current=$(get_driver "$GPU_VIDEO")
    cmd="''${1:-toggle}"

    case "$cmd" in
      enable|on)
        if [ "$current" = "nvidia" ]; then
          echo "Already on nvidia (driver: $current)."
        else
          enable_nvidia
        fi ;;
      disable|off)
        if [ "$current" = "vfio-pci" ]; then
          echo "Already on vfio-pci."
        else
          disable_nvidia "''${2:-}"
        fi ;;
      toggle)
        if [ "$current" = "vfio-pci" ] || [ "$current" = "none" ]; then
          enable_nvidia
        else
          disable_nvidia
        fi ;;
      status)
        echo "GPU video (${gpuVideo}): $(get_driver "$GPU_VIDEO")"
        echo "GPU audio (${gpuAudio}): $(get_driver "$GPU_AUDIO")"
        ;;
      *)
        echo "Usage: gpu-switch [enable|disable [--force]|toggle|status]"
        exit 1 ;;
    esac
  '';
in
{
  environment.systemPackages = [ gpu-switch ];
}
