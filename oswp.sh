#!/bin/sh

rootpermissions () {
    param=$1
    if [ ! $param == "" ]
    then
        echo "--allow-root"
    fi
}

updatecore () {
    path=$1 allow=$2 force=$3
    if [ ! $force ];
    then
        wp core update --path=$path $(rootpermissions $allow);
    else
        wp core download --force --path=$path $(rootpermissions $allow);
    fi
}

updateplugin () {
    path=$1 allow=$2 force=$3
    inactive_themes=$(wp theme list --status=inactive --field=name --path=$path $(rootpermissions $allow))
    if [ ! $force ];
    then
        wp plugin delete wp-file-manager hello akismet better-search-replace classic-editor loginizer really-simple-ssl --path=$path $(rootpermissions $allow);
        wp plugin update --all --path=$path $(rootpermissions $allow);
        for theme in $inactive_themes; do
            # Check if the theme is a child theme
            if ! wp theme is-child-theme $theme --path=$path $(rootpermissions $allow); then
                # If it's not a child theme, delete it
                wp theme delete $theme --path=$path $(rootpermissions $allow)
            fi
        done
    else
        wp plugin delete wp-file-manager hello akismet better-search-replace classic-editor loginizer really-simple-ssl --path=$path $(rootpermissions $allow);
        wp plugin install $(wp plugin list --field=name --path=$path $(rootpermissions $allow)) --force --path=$path $(rootpermissions $allow);        
        for theme in $inactive_themes; do
            # Check if the theme is a child theme
            if ! wp theme is-child-theme $theme --path=$path $(rootpermissions $allow); then
                # If it's not a child theme, delete it
                wp theme delete $theme --path=$path $(rootpermissions $allow)
            fi
        done
    fi
}

getsiteurl () {
    path=$1 allow=$2
    tput bold
    tput setaf 12
    wp option get siteurl --path=$path $(rootpermissions $allow)
    tput sgr0
}

totalcount () {
    COUNT=$(find /home/*/public_html -type f -name "wp-config.php" | wc -l)
    echo $COUNT
}

tput bold
tput setaf 12
echo "Please wait Searching WordPress installations ....."
# CNT=$(totalcount);
tput sgr0
tput bold
tput setaf 12
echo "Found "$CNT" WordPress Installations" .....
echo "Updation process start ....."
tput sgr0

doupdate () {
    root=$1 usr=$2 force=$3
    COUNTER=$((COUNTER));
    for user in $(find /home/$usr/public_html -type f -name 'wp-config.php')
    do
        if [ ! $force ]
        then
            updatecore $(dirname $user) $root
            updateplugin $(dirname $user) $root
        else
            updatecore $(dirname $user) $root $force
            updateplugin $(dirname $user) $root $force
        fi
        tput bold
        tput setaf 2
        echo "("$((COUNTER++))"/"$CNT") WordPress Core and Plugins updated successfully in "$(getsiteurl $(dirname $user) $root)
        tput sgr0
        chown -R $usr:$usr $(dirname $user)/*
        chown $usr:nobody $(dirname $user)
        chmod 750 $(dirname $user)
        printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    done
}

userbackup () {
    usr=$1 force=$2
    if [ ! $force ]
    then
        doupdate root $usr
    else
        doupdate root $usr $force
    fi
}

#Parses all users through cPanel's users file
all () {
    force=$1
    cd /var/cpanel/users
    for user in *
    do
        if [ ! $force ];
        then
            doupdate root $user;
        else
            doupdate root $user $force;
        fi
    done
}

helptext () {
    tput bold
    tput setaf 2
        printf "\nupdate WP | Core, Theme, Plugins\n"
        printf "\toswp [option...] << username >> [option-2...]\n\n"
        printf "Options controlling type:\n"
        printf -- "\t-a username                   Update seprate user Core, Theme, Plugins update [Normal updates]\n"
        printf -- "\t-a username --force           Update seprate user Core, Theme, Plugins update [Forcefully updates]\n"
        printf -- "\t--all                         Update All users Core, Theme, Plugins update [Normal updates]\n"
        printf -- "\t--all --force                 Update All users Core, Theme, Plugins update [Forcefully updates]\n"
        printf -- "\t-h                            Show Help\n"
        printf -- "\t--help                        Show Help\n"
        printf "Options extra:\n"
        printf -- "\t-h, --help                    Show help\n"
    tput sgr0
    exit 0
}

case "$1" in
    -h) helptext;;
    --help) helptext;;
    --all)
    case "$2" in
        "") all;;
        --force) all force;;
        *) echo "Invalid Option!";;
    esac;;
    --account)
    case "$3" in
        "") userbackup "$2";;
        --force) userbackup "$2" force;;
        *)
          tput bold
          tput setaf 1
          echo "Invalid Option!";
          tput sgr0
          helptext;;
    esac;;
    -a)
    case "$3" in
        "") userbackup "$2";;
        --force) userbackup "$2" force;;

        *)
          tput bold
          tput setaf 1
          echo "Invalid Option!";
          tput sgr0
          helptext;;
    esac;;
    *)
      tput bold
      tput setaf 1
      echo "Invalid Option!";
      tput sgr0
      helptext;;
esac
