#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ========================== CONFIGURATION ==========================
WP_DIRS=(/home /home1 /home2 /home3)
CPANEL_USERS_DIR="/var/cpanel/users"

# ============================ UTILITIES ============================
log() {
    tput bold; tput setaf "$1";
    echo -e "$2"
    tput sgr0
}

print_line() {
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
}

bold_green() {
    log 2 "$1"
}

bold_red() {
    log 1 "$1"
}

bold_blue() {
    log 4 "$1"
}

# ========================== WP HELPERS =============================
rootpermissions() {
    [[ "${1:-}" == "root" ]] && echo "--allow-root"
}

get_site_url() {
    local path="$1" allow="$2"
    wp option get siteurl --path="$path" $(rootpermissions "$allow") || echo "[Invalid site]"
}

# ===================== UPDATE FUNCTIONS ============================
update_core() {
    local path="$1" allow="$2" force="${3:-}"
    if [[ -z "$force" ]]; then
        wp core update --path="$path" $(rootpermissions "$allow") || true
    else
        wp core download --force --path="$path" $(rootpermissions "$allow") || true
    fi
}

update_plugins_and_themes() {
    local path="$1" allow="$2" force="${3:-}"
    local inactive_themes
    inactive_themes=$(wp theme list --status=inactive --field=name --path="$path" $(rootpermissions "$allow"))

    wp plugin delete wp-file-manager hello akismet better-search-replace classic-editor loginizer really-simple-ssl \
        --path="$path" $(rootpermissions "$allow") || true

    if [[ -z "$force" ]]; then
        wp plugin update --all --path="$path" $(rootpermissions "$allow") || true
    else
        wp plugin install $(wp plugin list --field=name --path="$path" $(rootpermissions "$allow")) --force --path="$path" $(rootpermissions "$allow") || true
    fi

    for theme in $inactive_themes; do
        if ! wp theme is-child-theme "$theme" --path="$path" $(rootpermissions "$allow") 2>/dev/null; then
            wp theme delete "$theme" --path="$path" $(rootpermissions "$allow") || true
        fi
    done
}

fix_permissions() {
    local path="$1" user="$2"
    chown -R "$user:$user" "$path"/* || true
    chown "$user:nobody" "$path" || true
    chmod 750 "$path" || true
}

update_single_wp() {
    local wp_config_path="$1" allow="$2" force="$3" user="$4"
    local wp_path
    wp_path="$(dirname "$wp_config_path")"

    update_core "$wp_path" "$allow" "$force"
    update_plugins_and_themes "$wp_path" "$allow" "$force"

    bold_green "Updated: $(get_site_url "$wp_path" "$allow")"
    fix_permissions "$wp_path" "$user"
    print_line
}

# ======================== MAIN OPERATIONS ===========================
find_all_wp_configs() {
    for dir in "${WP_DIRS[@]}"; do
        find "$dir" -mindepth 2 -maxdepth 4 -type f -name wp-config.php 2>/dev/null
    done
}

doupdate_user() {
    local allow="$1" user="$2" force="$3"
    local wp_paths

    mapfile -t wp_paths < <(find_all_wp_configs | grep "/home.*/$user/.*wp-config.php")

    for wp_config in "${wp_paths[@]}"; do
        # Try to update the user, and check for errors.
        update_single_wp "$wp_config" "$allow" "$force" "$user"
        
        # Check if the update_single_wp returned an error.
        if [[ $? -ne 0 ]]; then
            bold_red "Error updating user $user. Skipping this user."
            print_line
            continue  # Skip this user and continue with the next
        fi
    done
}

update_all_users() {
    local force="$1"
    for user in "$CPANEL_USERS_DIR"/*; do
        [[ -f "$user" ]] || continue
        user=$(basename "$user")

        # Attempt to update the user and check for errors
        doupdate_user root "$user" "$force"
        
        if [[ $? -ne 0 ]]; then
            bold_red "Skipping user $user due to errors."
            continue  # Continue with the next user if there's an error
        fi
    done
}

# ============================= HELP ================================
show_help() {
    bold_blue "\nWordPress Auto Updater"
    echo "Usage: oswp [options]"
    echo "Options:"
    echo "  -a username           Update single user normally"
    echo "  -a username --force   Update single user forcefully"
    echo "  --all                 Update all users normally"
    echo "  --all --force         Update all users forcefully"
    echo "  -h, --help            Show this help"
    exit 0
}

# ========================== ENTRY POINT ============================
main() {
    case "$1" in
        -h|--help) show_help ;;
        --all)
            if [[ "${2:-}" == "--force" ]]; then
                update_all_users "force"
            else
                update_all_users ""
            fi
            ;;
        -a)
            if [[ -z "${2:-}" ]]; then
                bold_red "Username required!"
                show_help
            elif [[ "${3:-}" == "--force" ]]; then
                doupdate_user root "$2" force
            else
                doupdate_user root "$2" ""
            fi
            ;;
        *)
            bold_red "Invalid option: $1"
            show_help
            ;;
    esac
}

main "$@"
