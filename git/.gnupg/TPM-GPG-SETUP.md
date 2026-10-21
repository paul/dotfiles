# TPM GPG Setup

Date: 2026-10-21
Machine: ava (Fedora 44, AMD firmware TPM 2.0)

## Keys

- Primary (certify only): `4AC051D558DC6740D06AFFAB4710279501533F02`
  - RSA 4096, expires 2028-10-20
  - UIDs: `psadauskas@gmail.com`, `paul@sadauskas.com`
- TPM signing subkey: `29C2A787E78C006EF5C0B420A72E0FF47E79D2FB`
  - RSA 2048, TPM-Protected; keygrip `CE91652750E9DC92BA44CE7B5AF0430F2FD36E73`
- Old key: `02DF4AA81F43CF58` remains for its other identities and old commits.
- Git: `~/.gitconfig.local` has `user.signingkey = 29C2A787E78C006EF5C0B420A72E0FF47E79D2FB!`

## Passphrase

- One passphrase protects the primary key and the TPM subkey.
- Stored encrypted at `~/.config/credstore.encrypted/tpm-signing-passphrase.cred`.
- Recover with:
  `systemd-creds decrypt --user --name=tpm-signing-passphrase ~/.config/credstore.encrypted/tpm-signing-passphrase.cred -`
- Passphase kept in the "ava.home TPM gpg signing key" note in bitwarden

## Unlock

- Systemd owns the agent: `gpg-agent.socket` and `gpg-agent.service` (`--supervised`).
- `gpg-agent.service.d/tpm-preset.conf` runs `gpg-unlock-tpm` as `ExecStartPost`.
- `gpg-unlock-tpm.service` presets at boot and login.
- `gpg-unlock-tpm.timer` re-presets every 5 minutes as a safety net for the start-hook race after a hard kill.
- `~/bin/gpg-unlock-tpm` reads the keygrip and credential, decrypts with `systemd-creds`, and calls `gpg-preset-passphrase`. It exits cleanly when either file is absent.
- Keygrip is machine-local: `~/.config/gpg-tpm/keygrip`. It is not in the dotfiles.
- The script and units are in the dotfiles under `linux/bin` and `linux/.config/systemd/user`.

## Config

- `gpg.conf`: `personal-digest-preferences SHA256`, `cert-digest-algo SHA256`.
- `gpg-agent.conf`: one-year cache, `allow-preset-passphrase`.
- SHA-256 is required because the TPM supports SHA-1 and SHA-256 only; GnuPG's default SHA-512 caused `Card error`.

## Backup

- `~/gpg-tpm-backup/newkey-secret.asc` (passphrase-protected)
- `~/gpg-tpm-backup/newkey-revoke.asc`
- `~/gpg-tpm-backup/newkey-public.asc`

Backups of these files are attached to the "ava.home TPM gpg signing key" note in bitwarden.

## GitHub

- Add `newkey-public.asc` as a GPG key.
- `gh` needs the `admin:gpg_key` scope, or use Settings → SSH and GPG keys → New GPG key.
- The old key remains for old commits.

## Other machines

- `gpg.conf` SHA-256 settings are portable.
- The TPM key, keygrip, and credential are per machine.
- A new Linux laptop needs its own TPM signing subkey, keygrip, credential, and enabled units.
- `gpg-agent-ssh.socket` is not used; the OpenSSH agent stays in use.

## Notes

- After a reboot, if the old key needs pinentry:
  `systemctl --user restart gpg-agent.service`
