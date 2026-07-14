#!/bin/bash
#------------------------------------------------------------
#   Script: moos_scoped_teardown.sh
#   Author: Charles Benjamin
#------------------------------------------------------------
# Shared teardown helpers for scoped MOOS mission runs.
#
# Source this file from a mission or harness wrapper and call:
#
#   moos_scoped_teardown_stop_root /path/to/mission-or-run-root
#
# The helper only targets known MOOS apps whose current working directory is
# the supplied root or a descendant of that root.

MOOS_SCOPED_TEARDOWN_GRACE_INT_SECONDS="${MOOS_SCOPED_TEARDOWN_GRACE_INT_SECONDS:-3}"
MOOS_SCOPED_TEARDOWN_GRACE_TERM_SECONDS="${MOOS_SCOPED_TEARDOWN_GRACE_TERM_SECONDS:-3}"
MOOS_SCOPED_TEARDOWN_GRACE_KILL_SECONDS="${MOOS_SCOPED_TEARDOWN_GRACE_KILL_SECONDS:-1}"
MOOS_SCOPED_TEARDOWN_SLEEP="${MOOS_SCOPED_TEARDOWN_SLEEP:-0.125}"
MOOS_SCOPED_TEARDOWN_QUIET="${MOOS_SCOPED_TEARDOWN_QUIET:-yes}"
MOOS_SCOPED_TEARDOWN_EXTRA_APPS="${MOOS_SCOPED_TEARDOWN_EXTRA_APPS:-}"

moos_scoped_teardown_log() {
    if [ "$MOOS_SCOPED_TEARDOWN_QUIET" != "yes" ]; then
        echo "moos_scoped_teardown: $*"
    fi
}

moos_scoped_teardown_apps_for_root() {
    local root="$1"
    local defaults

    defaults="pAntler MOOSDB pRealm pLogger uProcessWatch pShare pHostInfo"
    defaults="$defaults uFldShoreBroker uFldNodeComms uTimerScript pMissionEval"
    defaults="$defaults pAutoPoke pMarineViewer pMissionHash uMayFinish"
    defaults="$defaults uFldNodeBroker pHelmIvP"
    defaults="$defaults pMarinePID pMarinePIDV22 pNodeReporter pNodeRepo uLoadWatch"
    defaults="$defaults uSimMarine uSimMarineV22"
    defaults="$defaults pTrafficManager pTrafficM"

    {
        if [ -d "$root" ]; then
            find "$root" -maxdepth 3 -type f \
                \( -name 'meta_*.moos' -o -name 'meta_*.moosx' -o -name 'targ_*.moos' \) \
                -print 2>/dev/null | while IFS= read -r moos_file; do
                    sed -n 's/^[[:space:]]*Run[[:space:]]*=[[:space:]]*\([^[:space:]@]*\).*/\1/p' "$moos_file"
                done
        fi
        echo "$defaults"
        echo "$MOOS_SCOPED_TEARDOWN_EXTRA_APPS"
    } | tr ' ' '\n' | sed '/^$/d' | sort -u
}

moos_scoped_teardown_app_match() {
    local command="$1"
    local apps="$2"

    [ "$command" != "" ] || return 1
    case "$apps" in
        *" $command "*) return 0 ;;
    esac
    return 1
}

moos_scoped_teardown_path_in_root() {
    local path="$1"
    local root="$2"

    [ "$path" = "$root" ] || [ "${path#"$root"/}" != "$path" ]
}

moos_scoped_teardown_pids_for_root_procfs() {
    local root="$1"
    local apps
    local proc_dir
    local pid
    local cwd
    local command
    local exe
    local argv0

    [ -d /proc ] || return 1
    [ -L "/proc/$$/cwd" ] || return 1
    readlink "/proc/$$/cwd" >/dev/null 2>&1 || return 1

    root=$(cd "$root" 2>/dev/null && pwd -P)
    [ "$root" != "" ] || return 1

    apps=$(moos_scoped_teardown_apps_for_root "$root" | tr '\n' ' ')

    for proc_dir in /proc/[0-9]*; do
        [ -d "$proc_dir" ] || continue
        pid="${proc_dir##*/}"
        cwd=$(readlink "$proc_dir/cwd" 2>/dev/null) || continue
        moos_scoped_teardown_path_in_root "$cwd" "$root" || continue

        command=""
        exe=$(readlink "$proc_dir/exe" 2>/dev/null) || exe=""
        if [ "$exe" != "" ]; then
            command="${exe##*/}"
        fi
        if ! moos_scoped_teardown_app_match "$command" " $apps "; then
            argv0=$(tr '\000' '\n' < "$proc_dir/cmdline" 2>/dev/null | sed -n '1p') || argv0=""
            if [ "$argv0" != "" ]; then
                command="${argv0##*/}"
            fi
        fi
        if ! moos_scoped_teardown_app_match "$command" " $apps "; then
            command=$(sed -n '1p' "$proc_dir/comm" 2>/dev/null) || command=""
        fi
        if moos_scoped_teardown_app_match "$command" " $apps "; then
            echo "$pid"
        fi
    done | sort -nu
}

moos_scoped_teardown_pids_for_root_lsof() {
    local root="$1"
    local apps
    local listing

    command -v lsof >/dev/null 2>&1 || return 1

    root=$(cd "$root" 2>/dev/null && pwd -P)
    [ "$root" != "" ] || return 1

    apps=$(moos_scoped_teardown_apps_for_root "$root" | tr '\n' ' ')

    listing=$(lsof -n -P -w -d cwd -Fnpc 2>/dev/null) || return 1

    printf '%s\n' "$listing" | \
        awk -v root="$root" -v apps=" $apps " '
            /^p/ {
                pid = substr($0, 2)
                command = ""
                is_cwd = 0
                next
            }
            /^c/ {
                command = substr($0, 2)
                next
            }
            /^f/ {
                is_cwd = ($0 == "fcwd")
                next
            }
            /^n/ && is_cwd {
                path = substr($0, 2)
                if ((path == root || index(path, root "/") == 1) &&
                    index(apps, " " command " ") > 0)
                    print pid
                is_cwd = 0
                next
            }
        ' | sort -nu
}

moos_scoped_teardown_pids_for_root() {
    local root="$1"

    moos_scoped_teardown_pids_for_root_procfs "$root" && return 0
    moos_scoped_teardown_pids_for_root_lsof "$root" && return 0
    return 1
}

moos_scoped_teardown_pids_for_root_checked() {
    local root="$1"

    if ! moos_scoped_teardown_pids_for_root "$root"; then
        echo "moos_scoped_teardown: unable to inspect scoped processes under $root" >&2
        return 1
    fi
}

moos_scoped_teardown_wait_clear() {
    local root="$1"
    local grace_seconds="$2"
    local pids
    local deadline

    case "$grace_seconds" in
        ""|*[!0-9]*)
            echo "moos_scoped_teardown: invalid grace period: $grace_seconds" >&2
            return 2
            ;;
    esac

    deadline=$((SECONDS + grace_seconds))
    while :; do
        pids=$(moos_scoped_teardown_pids_for_root_checked "$root") || return 2
        if [ "$pids" = "" ]; then
            return 0
        fi
        if [ "$SECONDS" -ge "$deadline" ]; then
            break
        fi
        sleep "$MOOS_SCOPED_TEARDOWN_SLEEP"
    done

    return 1
}

moos_scoped_teardown_signal_pids() {
    local signal="$1"
    local pids="$2"
    local pid

    for pid in $pids; do
        kill "-$signal" "$pid" >/dev/null 2>&1 || true
    done
}

moos_scoped_teardown_stop_root() {
    local root="$1"
    local pids
    local wait_status

    if [ "$root" = "" ] || [ ! -d "$root" ]; then
        return 0
    fi

    pids=$(moos_scoped_teardown_pids_for_root_checked "$root") || return 1
    if [ "$pids" = "" ]; then
        return 0
    fi

    moos_scoped_teardown_log "INT $root: $pids"
    moos_scoped_teardown_signal_pids INT "$pids"
    moos_scoped_teardown_wait_clear "$root" "$MOOS_SCOPED_TEARDOWN_GRACE_INT_SECONDS" && return 0
    wait_status=$?
    if [ "$wait_status" -eq 2 ]; then
        return 1
    fi

    pids=$(moos_scoped_teardown_pids_for_root_checked "$root") || return 1
    if [ "$pids" != "" ]; then
        moos_scoped_teardown_log "TERM $root: $pids"
        moos_scoped_teardown_signal_pids TERM "$pids"
        moos_scoped_teardown_wait_clear "$root" "$MOOS_SCOPED_TEARDOWN_GRACE_TERM_SECONDS" && return 0
        wait_status=$?
        if [ "$wait_status" -eq 2 ]; then
            return 1
        fi
    fi

    pids=$(moos_scoped_teardown_pids_for_root_checked "$root") || return 1
    if [ "$pids" != "" ]; then
        moos_scoped_teardown_log "KILL $root: $pids"
        moos_scoped_teardown_signal_pids KILL "$pids"
        moos_scoped_teardown_wait_clear "$root" "$MOOS_SCOPED_TEARDOWN_GRACE_KILL_SECONDS" && return 0
        wait_status=$?
        if [ "$wait_status" -eq 2 ]; then
            return 1
        fi
    fi

    pids=$(moos_scoped_teardown_pids_for_root_checked "$root") || return 1
    if [ "$pids" != "" ]; then
        echo "moos_scoped_teardown: warning: leftover scoped PIDs under $root: $pids" >&2
        return 1
    fi

    return 0
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ "$1" = "" ]; then
        echo "moos_scoped_teardown.sh ROOT"
        echo ""
        echo "Stops known MOOS mission apps whose cwd is ROOT or below."
        exit 0
    fi
    moos_scoped_teardown_stop_root "$1"
fi
