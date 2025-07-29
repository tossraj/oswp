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
    local path="$1" allow="$2" user="$3"
    local url
    url=$(wp option get siteurl --path="$path" $(rootpermissions "$allow") 2>/dev/null || true)
    if [[ -z "$url" ]]; then
        echo "[Invalid site] ($user)"
    else
        echo "$url"
    fi
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

    bold_green "Updated: $(get_site_url "$wp_path" "$allow" "$user")"
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
    local allow="$1" force="$2"; shift 2
    local users=("$@")

    for user in "${users[@]}"; do
        mapfile -t wp_paths < <(find_all_wp_configs | grep "/home.*/$user/.*wp-config.php")

        if [[ "${#wp_paths[@]}" -eq 0 ]]; then
            bold_red "No WordPress installations found for user: $user"
            continue
        fi

        for wp_config in "${wp_paths[@]}"; do
            wp_path="$(dirname "$wp_config")"

            if ! wp core is-installed --path="$wp_path" $(rootpermissions "$allow") &>/dev/null; then
                bold_red "Skipping: Not a WordPress installation at $wp_path"
                continue
            fi

            update_single_wp "$wp_config" "$allow" "$force" "$user"
        done
    done
}

update_all_users() {
    local force="$1"
    local usernames=()
    for file in "$CPANEL_USERS_DIR"/*; do
        [[ -f "$file" ]] || continue
        usernames+=("$(basename "$file")")
    done
    doupdate_user root "$force" "${usernames[@]}"
}

# ============================= HELP ================================
show_help() {
    bold_blue "\nWordPress Auto Updater"
    echo -e "Usage: \e[1moswp\e[0m [options]\n"
    echo -e "\e[1mOptions:\e[0m"
    echo -e "  \e[32m-a user1 user2 [--force]\e[0m    Update specified users (with optional force)"
    echo -e "  \e[32m--all [--force]\e[0m              Update all users (with optional force)"
    echo -e "  \e[32m-h, --help\e[0m                   Show this help message"
    exit 0
}

# ========================== ENTRY POINT ============================
main() {
    if [[ $# -lt 1 ]]; then
        bold_red "Missing options"
        show_help
    fi

    case "$1" in
        -h|--help) show_help ;;
        --all)
            force=""
            [[ "${2:-}" == "--force" ]] && force="force"
            update_all_users "$force"
            ;;
        -a)
            shift
            users=()
            force=""
            while [[ $# -gt 0 ]]; do
                if [[ "$1" == "--force" ]]; then
                    force="force"
                else
                    users+=("$1")
                fi
                shift
            done

            if [[ "${#users[@]}" -eq 0 ]]; then
                bold_red "At least one username is required!"
                show_help
            fi

            doupdate_user root "$force" "${users[@]}"
            ;;
        *)
            bold_red "Invalid option: $1"
            show_help
            ;;
    esac
}

main "$@"
