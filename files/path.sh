sanitize_path() {
    local oldIFS=$IFS
    local IFS=':'
    local path=( $PATH )
    local IFS=$oldIFS

    local newpath=''

    local dir
    for dir in "${path[@]}" ; do
        if [[ ! "$dir" =~ ^/ ]] ; then
            echo "$dir is a relative directory" >&2
            continue
        fi

        if [ ! -d "$dir" ] ; then
            echo "$dir is not a directory"
            continue
        fi

        local owner="$( stat -L -c '%u' "$dir" )"
        local perms="$( stat -L -c '0%a' "$dir" )"

        if [ "$owner" -ne "$UID" ] ; then
            if [ "$UID" -eq 0 ] ; then
                echo "$dir is not owned by root" >&2
                continue
            elif [ "$owner" -ne 0 ] ; then
                echo "$dir is owned by another user" >&2
                continue
            fi
        fi

        if [ $[ $perms & 020 ] -ne 0 -a "$UID" -eq 0 ] ; then
            echo "$dir is group writable" >&2
            continue
        fi

        if [ $[ $perms & 02 ] -ne 0 ] ; then
            echo "$dir is world writable" >&2
            continue
        fi

        if [ -n "$newpath" ] ; then
            newpath+=':'
        fi
        newpath+="$dir"
    done

    export PATH=$newpath
}

sanitize_path
