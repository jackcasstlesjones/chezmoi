# Encrypting the Root Disk In Place (LUKS2)

## Issue
The root disk is not encrypted. `nvme0n1p2` is plain ext4 mounted straight at
`/`: there's no `crypto_LUKS` partition and no `/etc/crypttab`. Anyone with the
laptop can boot a USB stick (or pull the drive) and read everything.

**Fix: `cryptsetup reencrypt --encrypt`** converts the existing partition to
LUKS2 without wiping it. It has to run from an Arch live USB, because root
can't be mounted while it's being encrypted.

## System details

- Kioxia BG6 NVMe SSD (`KBG6AZNV512G`), `nvme0n1`
- `nvme0n1p1` 1G vfat `/boot` (stays unencrypted, holds kernels/initramfs only)
- `nvme0n1p2` 475.9G ext4 `/`, PARTUUID `2000808c-0de0-4d11-af3b-16e764614088`
- ext4 UUID `992e1d56-7b0f-440e-abc8-71e724076ea4` (used by fstab)
- systemd-boot, 6 entries in `/boot/loader/entries/` (linux, lts, zen + fallbacks)
- mkinitcpio with udev-based hooks (so `encrypt` hook, not `sd-encrypt`)
- swap is zram only, so there's no swap partition to encrypt

## Before starting

- **Back up.** LUKS2 encryption can resume after a power cut, but a bug or typo
  can still lose data.
- Plug in the charger.
- Allow about 30–60 minutes for the encryption pass.

## Steps

### 1. Boot the Arch live USB and shrink the filesystem

LUKS needs room for its header, so shrink ext4 below the partition size first:

```sh
e2fsck -f /dev/nvme0n1p2
resize2fs /dev/nvme0n1p2 470G      # partition is 475.9G; leaves plenty of slack
```

### 2. Encrypt in place

Sets the passphrase. This is the long step:

```sh
cryptsetup reencrypt --encrypt --reduce-device-size 32M /dev/nvme0n1p2
```

If it's interrupted, re-run it (or `cryptsetup reencrypt --resume-only
/dev/nvme0n1p2`) and it carries on from where it stopped.

### 3. Open it, grow the filesystem back, chroot in

```sh
cryptsetup open /dev/nvme0n1p2 root
resize2fs /dev/mapper/root
mount /dev/mapper/root /mnt
mount /dev/nvme0n1p1 /mnt/boot
arch-chroot /mnt
```

### 4. Add the `encrypt` hook

In `/etc/mkinitcpio.conf`, `encrypt` goes after `block` and before `filesystems`
(`keyboard` and `keymap` are already earlier, so the passphrase prompt has a
keyboard):

```
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems fsck)
```

Rebuild all initramfs images:

```sh
mkinitcpio -P
```

### 5. Point the boot entries at the encrypted device

Updates all 6 entries in one go:

```sh
sed -i 's|root=PARTUUID=2000808c-0de0-4d11-af3b-16e764614088|cryptdevice=PARTUUID=2000808c-0de0-4d11-af3b-16e764614088:root root=/dev/mapper/root|' /boot/loader/entries/*.conf
```

Check one:

```sh
grep options /boot/loader/entries/*_linux.conf
# options cryptdevice=PARTUUID=2000808c-...:root root=/dev/mapper/root zswap.enabled=0 rw rootfstype=ext4
```

### 6. fstab: no change

fstab mounts `/` by the ext4 UUID (`992e1d56-…`). Encrypting doesn't change that
UUID, so it still matches once `/dev/mapper/root` is open.

### 7. Reboot

```sh
exit
umount -R /mnt
cryptsetup close root
reboot
```

You should get a passphrase prompt before Hyprland starts.

## Verify

```sh
lsblk -o NAME,TYPE,FSTYPE,MOUNTPOINTS
# nvme0n1p2  part  crypto_LUKS
# └─root     crypt ext4         /

sudo cryptsetup luksDump /dev/nvme0n1p2 | head   # Version: 2
```

## If it doesn't boot

The data is safe. It just means the hook or the kernel command line is wrong.
Boot the live USB again and:

```sh
cryptsetup open /dev/nvme0n1p2 root
mount /dev/mapper/root /mnt
mount /dev/nvme0n1p1 /mnt/boot
arch-chroot /mnt
```

Then re-check step 4 (hook order, `mkinitcpio -P`) and step 5 (`cryptdevice=`
in every entry).

## Notes

- Only `/boot` stays unencrypted. That's the normal setup: it holds the kernel
  and initramfs images, not user data.
- The drive might also support hardware self-encryption (OPAL). It's
  unverified and not used here. If it were on, there'd be a drive password
  prompt before the bootloader.
- Kernel upgrades need no extra steps: `mkinitcpio` picks up the `encrypt`
  hook automatically. Any new boot entry you add (e.g. another kernel) needs
  the same `cryptdevice=... root=/dev/mapper/root` options as step 5.
