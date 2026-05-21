# Notes

## nixpkgs pin (2026-05-21)

`flake.nix` has nixpkgs pinned to commit `bc57abace07689cfd34203aa5fb4027514895987`
instead of tracking `nixos-unstable`.

**Why:** After running `nix flake update`, the MT7922 WiFi card (mt7921e driver) broke —
associates and completes WPA2 handshake fine, but the data TX path silently fails so no
traffic passes. The new kernel/firmware from the updated nixpkgs introduced the regression.

**To unpin:** Once the regression is fixed upstream, change `flake.nix` back to:
```nix
nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
```
then run `nix flake update && sudo nixos-rebuild switch --flake .#nixos`.
Check the nixpkgs issue tracker or kernel changelogs for mt7921e/MT7922 fixes if needed.
