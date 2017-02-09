#!/usr/bin/env sh
#===============================================================================
#          FILE: samba.sh
#
#         USAGE: ./samba.sh
#
#   DESCRIPTION: Entrypoint for samba docker container
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: David Personette (dperson@gmail.com),
#  ORGANIZATION:
#       CREATED: 09/28/2014 12:11
#      REVISION: 1.0
#===============================================================================

set -o nounset                              # Treat unset variables as an error

### user: add a user
# Arguments:
#   name) for user
#   password) for user
#   id) for user
# Return: user added to container
user() {
    name="${1}"
    passwd="${2}"
    
    if id "$1" >/dev/null 2>&1; then
        echo "user exists"
    else
        addgroup "$name" 
        adduser -D -H -G "$name" -s /bin/false "$name"
        addgroup "$name" smb
        echo -e "$passwd\n$passwd" | smbpasswd -s -a -c /config/smb.conf "$name"
    fi
}

### usage: Help
# Arguments:
#   none)
# Return: Help text
usage() { local RC=${1:-0}
    echo "Usage: ${0##*/} [-opt] [command]
Options (fields in '[]' are optional, '<>' are required):
    -u \"<username;password>[;ID;group]\"       Add a user
                required arg: \"<username>;<passwd>\"
                <username> for user
                <password> for user
"
}

while getopts ":h:u:" opt; do
    case "$opt" in
        h) usage ;;
        u) user $(echo $OPTARG | sed 's/;/ /g') ;;
        "?") echo "Unknown option: -$OPTARG"; usage 1 ;;
        ":") echo "No argument value for option: -$OPTARG"; usage 2 ;;
    esac
done
shift $(( OPTIND - 1 ))

exit 0