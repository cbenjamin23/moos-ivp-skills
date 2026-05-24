#!/bin/bash
#------------------------------------------------------------
#   Script: harness_teardown.sh
#   Author: Charles Benjamin
#------------------------------------------------------------
# Shared teardown helpers for harness-owned MOOS mission runs.
#
# Source this file from a harness and call:
#
#   harness_teardown_stop_root /path/to/mission-or-run-root
#
# The helper only targets known MOOS apps whose current working directory is
# the supplied root or a descendant of that root.

HARNESS_TEARDOWN_GRACE_INT="${HARNESS_TEARDOWN_GRACE_INT:-8}"
HARNESS_TEARDOWN_GRACE_TERM="${HARNESS_TEARDOWN_GRACE_TERM:-8}"
HARNESS_TEARDOWN_SLEEP="${HARNESS_TEARDOWN_SLEEP:-0.125}"
HARNESS_TEARDOWN_QUIET="${HARNESS_TEARDOWN_QUIET:-yes}"

harness_teardown_log() {
    if [ "$HARNESS_TEARDOWN_QUIET" != "yes" ]; then
        echo "harness_teardown: $*"
    fi
}

harness_teardown_apps_for_root() {
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
        echo "$HARNESS_TEARDOWN_EXTRA_APPS"
    } | tr ' ' '\n' | sed '/^$/d' | sort -u
}

harness_teardown_app_match() {
    local command="$1"
    local apps="$2"

    [ "$command" != "" ] || return 1
    case "$apps" in
        *" $command "*) return 0 ;;
    esac
    return 1
}

harness_teardown_path_in_root() {
    local path="$1"
    local root="$2"

    [ "$path" = "$root" ] || [ "${path#"$root"/}" != "$path" ]
}

harness_teardown_pids_for_root_procfs() {
    local root="$1"
    local apps
    local proc_dir
    local pid
    local cwd
    local command
    local exe
    local argv0

    [ -d /proc ] || return 1

    root=$(cd "$root" 2>/dev/null && pwd -P)
    [ "$root" != "" ] || return 1

    apps=$(harness_teardown_apps_for_root "$root" | tr '\n' ' ')

    for proc_dir in /proc/[0-9]*; do
        [ -d "$proc_dir" ] || continue
        pid="${proc_dir##*/}"
        cwd=$(readlink "$proc_dir/cwd" 2>/dev/null) || continue
        harness_teardown_path_in_root "$cwd" "$root" || continue

        command=""
        exe=$(readlink "$proc_dir/exe" 2>/dev/null) || exe=""
        if [ "$exe" != "" ]; then
            command="${exe##*/}"
        fi
        if ! harness_teardown_app_match "$command" " $apps "; then
            argv0=$(tr '\000' '\n' < "$proc_dir/cmdline" 2>/dev/null | sed -n '1p') || argv0=""
            if [ "$argv0" != "" ]; then
                command="${argv0##*/}"
            fi
        fi
        if ! harness_teardown_app_match "$command" " $apps "; then
            command=$(sed -n '1p' "$proc_dir/comm" 2>/dev/null) || command=""
        fi
        if harness_teardown_app_match "$command" " $apps "; then
            echo "$pid"
        fi
    done | sort -nu
}

harness_teardown_pids_for_root_lsof() {
    local root="$1"
    local apps

    command -v lsof >/dev/null 2>&1 || return 1

    root=$(cd "$root" 2>/dev/null && pwd -P)
    [ "$root" != "" ] || return 1

    apps=$(harness_teardown_apps_for_root "$root" | tr '\n' ' ')

    lsof -n -P -w +D "$root" -Fnpc 2>/dev/null | \
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

harness_teardown_pids_for_root() {
    local root="$1"

    harness_teardown_pids_for_root_procfs "$root" && return 0
    harness_teardown_pids_for_root_lsof "$root" && return 0
    return 0
}

harness_teardown_wait_clear() {
    local root="$1"
    local attempts="$2"
    local pids
    local attempt

    attempt=0
    while [ "$attempt" -lt "$attempts" ]; do
        pids=$(harness_teardown_pids_for_root "$root")
        if [ "$pids" = "" ]; then
            return 0
        fi
        sleep "$HARNESS_TEARDOWN_SLEEP"
        attempt=$((attempt + 1))
    done

    return 1
}

harness_teardown_signal_pids() {
    local signal="$1"
    local pids="$2"
    local pid

    for pid in $pids; do
        kill "-$signal" "$pid" >/dev/null 2>&1 || true
    done
}

harness_teardown_stop_root() {
    local root="$1"
    local pids

    if [ "$root" = "" ] || [ ! -d "$root" ]; then
        return 0
    fi

    pids=$(harness_teardown_pids_for_root "$root")
    if [ "$pids" = "" ]; then
        return 0
    fi

    harness_teardown_log "INT $root: $pids"
    harness_teardown_signal_pids INT "$pids"
    harness_teardown_wait_clear "$root" "$HARNESS_TEARDOWN_GRACE_INT" && return 0

    pids=$(harness_teardown_pids_for_root "$root")
    if [ "$pids" != "" ]; then
        harness_teardown_log "TERM $root: $pids"
        harness_teardown_signal_pids TERM "$pids"
        harness_teardown_wait_clear "$root" "$HARNESS_TEARDOWN_GRACE_TERM" && return 0
    fi

    pids=$(harness_teardown_pids_for_root "$root")
    if [ "$pids" != "" ]; then
        harness_teardown_log "KILL $root: $pids"
        harness_teardown_signal_pids KILL "$pids"
        harness_teardown_wait_clear "$root" 4 && return 0
    fi

    pids=$(harness_teardown_pids_for_root "$root")
    if [ "$pids" != "" ]; then
        echo "harness_teardown: warning: leftover scoped PIDs under $root: $pids" >&2
        return 1
    fi

    return 0
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ "$1" = "" ]; then
        echo "harness_teardown.sh ROOT"
        echo ""
        echo "Stops known MOOS mission apps whose cwd is ROOT or below."
        exit 0
    fi
    harness_teardown_stop_root "$1"
fi
