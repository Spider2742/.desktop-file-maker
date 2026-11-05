# .desktop file maker

Small scripts that put apps in your Linux app menu without any manual setup.

| Script | What it does |
| --- | --- |
| [`launcher maker.sh`](launcher%20maker.sh) | Makes a `.desktop` file (app menu entry) for any program or game |
| [`discord-install.sh`](discord-install.sh) | Installs official Discord from its `.tar.gz` and adds it to your app menu |

Both run straight from the terminal with one command, in any shell (bash, zsh, fish). You don't
need to download anything first, and neither needs root (`sudo`).

## Launcher maker

```bash
curl -fsSL https://raw.githubusercontent.com/Spider2742/.desktop-file-maker/main/launcher%20maker.sh | bash
```

The script asks for a name, a comment, the program to run, an icon, whether it needs a terminal, and
menu categories. It then creates the entry in `~/.local/share/applications`.

> [!NOTE]
> For the executable and icon, you can drag and drop the file into the terminal instead of typing
> the path. Paths with spaces work.

> [!TIP]
> Add it as a simple command like `make_launcher` with an `alias`:
> ```bash
> alias make_launcher="curl -fsSL https://raw.githubusercontent.com/Spider2742/.desktop-file-maker/main/launcher%20maker.sh | bash"
> ```
> This works in bash, zsh and fish. In fish, use `alias --save` to keep it after you close the terminal.

## Discord installer

```bash
curl -fsSL https://raw.githubusercontent.com/Spider2742/.desktop-file-maker/main/discord-install.sh | bash
```

The script asks where to install Discord (default `~/.local/share/Discord`). It then downloads the
latest version from discord.com, extracts it there, and adds Discord to your app menu. It also adds
a `discord` command and makes `discord://` links open in the app.

```bash
# install to a specific folder without being asked
curl -fsSL https://raw.githubusercontent.com/Spider2742/.desktop-file-maker/main/discord-install.sh | bash -s -- --dir ~/Apps/Discord

# uninstall (add --purge to also delete your Discord data in ~/.config/discord)
curl -fsSL https://raw.githubusercontent.com/Spider2742/.desktop-file-maker/main/discord-install.sh | bash -s -- --uninstall
```

**Updates are automatic.** Discord's Linux `.tar.gz` now updates itself: on first launch it downloads
the app into `~/.config/discord` and keeps it up to date from then on. Running the script again only
refreshes the launcher files and menu entry, which you'll rarely need to do.

**Why not the Flatpak?** Flatpak Discord runs in a sandbox and can't see other programs, so it never
shows "Playing …" for games it detects automatically. This install can.

## Author

- [@Spider2742](https://www.github.com/Spider2742)
