# bazzite-surface

[Bazzite](https://bazzite.gg) (KDE, Intel/AMD graphics) for the **Intel Surface Pro 9**, with the touchscreen and pen working.

Built daily on top of `ghcr.io/ublue-os/bazzite:stable`, so it keeps Bazzite's own kernel and updates. It adds:

| Piece | What it does |
| --- | --- |
| `ithc` kernel module ([quo/ithc-linux](https://github.com/quo/ithc-linux), pinned) | Driver for the Intel Touch Host Controller the SP9 touchscreen and pen sit behind. Built against Bazzite's kernel and signed for Secure Boot. |
| `iptsd` ([linux-surface](https://github.com/linux-surface/iptsd)) | Turns the raw touch data into multitouch, palm rejection, and pen pressure, tilt, buttons, and eraser. |
| `surface-pro9.tablet` | libwacom data so the pen and touch are treated as part of the built-in screen. |

Already handled by Bazzite's stock kernel: Type Cover keyboard and touchpad, battery and charging, tablet-mode switch, and platform power profiles. Wi-Fi, Bluetooth, audio, and suspend work as well.

**Not working:** the front and rear cameras (Intel IPU6, which has no usable Linux driver on this device). The 5G/SQ3 (ARM) Surface Pro 9 is not supported.

## Installing on the Surface

You need a USB keyboard or the Type Cover attached. Touch does not work in the firmware screens.

1. **Allow Linux to boot.** Hold **Volume Up** and press **Power** to open Surface UEFI. Under **Security → Secure Boot**, choose **Microsoft & 3rd party CA**. Leave Secure Boot on.
2. **Install regular Bazzite.** Download the ISO from https://bazzite.gg/#image-picker: pick *Laptop/Desktop*, *Intel*, *KDE*. Write it to a USB stick, then hold **Volume Down** and press **Power** to boot from it. When the installer asks you to enroll a key, the password is `universalblue`.
3. **Switch to this image.** After the first boot, open Konsole and run:

   ```bash
   sudo bootc switch ghcr.io/john-s-reddick/bazzite-surface:latest
   ```

4. **Enroll the driver's signing key** so the touch driver can load under Secure Boot:

   ```bash
   sudo mokutil --import /usr/share/bazzite-surface/bazzite-surface-mok.der
   ```

   Choose a short one-time password, then reboot. A blue **MOK management** screen appears: choose **Enroll MOK → Continue → Yes**, type the password, then **Reboot**.

   Run the `mokutil` command after you've rebooted into this image. The key file is in this image, not in stock Bazzite.

5. **Check it.** Touch and the pen should work at the login screen. To confirm from a terminal:

   ```bash
   lsmod | grep ithc                       # driver loaded
   systemctl list-units 'iptsd@*'          # touch daemon running
   ```

Updates arrive the same way as on stock Bazzite (automatic, or `ujust update`). To go back to stock Bazzite: `sudo bootc switch ghcr.io/ublue-os/bazzite:stable`.

## Troubleshooting

- **No touch, and `dmesg | grep -i ithc` mentions a signature or "Key was rejected":** the signing key isn't enrolled. Redo step 4.
- **Touch works but only with one finger:** `iptsd` isn't running. Check `journalctl -b -u 'iptsd@*'`.

## Maintaining

- The module signing key and cosign key are the GitHub secrets `MOK_KEY` and `SIGNING_SECRET`. Local copies live in `~/.local/share/bazzite-surface-keys/` on the machine that set this repo up. Never commit them.
- If a build fails at `dnf5 install -y iptsd`, the Fedora 43 iptsd package has drifted from Bazzite's libraries. Check whether linux-surface has published a repo for the current Fedora release (https://pkg.surfacelinux.com/fedora/), and update the `baseurl` in `build_files/build.sh`.
- If a build fails compiling `ithc` after a Bazzite kernel jump, bump `ITHC_COMMIT` in `build_files/build-ithc.sh` to a newer upstream commit.
