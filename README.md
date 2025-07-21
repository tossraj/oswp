# oswp

**oswp** is a lightweight shell-based tool to **update WordPress Core, Themes, and Plugins** across all installations for cPanel users — using **WP-CLI** under the hood.

---

## ✨ Features

* Scans all WordPress installations under `/home`, `/home1`, `/home2`, `/home3`
* Updates WordPress Core
* Updates all active plugins
* Deletes unnecessary or unsafe plugins (like `hello`, `wp-file-manager`, etc.)
* Removes inactive themes (unless they are child themes)
* Fixes file/folder ownership and permissions
* Optionally force-reinstalls all plugins/themes/core

---

## 📦 Requirements

* [WP-CLI](https://wp-cli.org/) installed and accessible
* Bash shell (`/bin/bash`)
* Root or privileged user

---

## 🔧 Installation

```bash
git clone https://github.com/tossraj/oswp.git
cd oswp
chmod +x install.sh
./install.sh
```

This will install the script at:

```bash
/usr/local/bin/oswp
```

---

## 🚀 Usage

### Update WordPress for a Single User

* Normal update:

```bash
oswp -a cpaneluser
```

* Force update (force reinstall core/plugins/themes):

```bash
oswp -a cpaneluser --force
```

### Update WordPress for All Users

* Normal update:

```bash
oswp --all
```

* Force update:

```bash
oswp --all --force
```

### Show Help

```bash
oswp -h
```

or

```bash
oswp --help
```

---

## 📂 WordPress Path Detection

The script scans all `wp-config.php` files inside these directories:

* `/home`
* `/home1`
* `/home2`
* `/home3`

---

## ⚠️ Important Notes

* Meant for use by **system administrators** managing multiple WordPress installations
* Use `--force` with caution – it will reinstall components
* Always test on staging servers before using in production

---

## 📁 License

MIT License
