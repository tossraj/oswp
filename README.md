# oswp
update WP | Core, Themes, Plugins for cPanel users

## Dependency

This plugin requires a WP-CLI script to work.

First install [WP-CLI](https://wp-cli.org/) and then install this plugin

## Installing 

```bash
git clone https://github.com/tossraj/oswp.git
```
```bash
cd oswp
```
```bash
chmod +x install.sh
```
```bash
./install.sh
```
## Uses

`oswp -a cpaneluser` for update user all wordpress sites core theme and plugins.

`oswp -a cpaneluser --force` for update user all wordpress sites core theme and plugins forcefully reinstall.

`oswp -h` or `oswp --help` for for help or view all options.
