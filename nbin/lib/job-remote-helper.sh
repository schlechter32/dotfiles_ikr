#!/run/current-system/sw/bin/bash

set -euo pipefail

STATE_ROOT="${JOB_BROKER_REMOTE_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.cache/job-broker}/remote}"

mkdir -p "$STATE_ROOT/jobs"

job_dir() {
    printf '%s/jobs/%s\n' "$STATE_ROOT" "$1"
}

json_escape() {
    local value="$1"
    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    value=${value//$'\n'/\\n}
    value=${value//$'\r'/\\r}
    value=${value//$'\t'/\\t}
    printf '%s' "$value"
}

write_run_script() {
    local job_id="$1"
    local workdir="$2"
    local command_string="$3"
    local dir
    dir="$(job_dir "$job_id")"
cat >"$dir/run.sh" <<EOF
#!/run/current-system/sw/bin/bash
set -euo pipefail
job_dir=$(printf '%q' "$dir")
workdir=$(printf '%q' "$workdir")
command_string=$(printf '%q' "$command_string")
log_path="\$job_dir/log.txt"
status_path="\$job_dir/status"
exit_path="\$job_dir/exit_code"
finished_at_path="\$job_dir/finished_at"
child_pid=""

finish_job() {
    local state="\$1"
    local exit_code="\$2"
    printf '%s\n' "\$state" >"\$status_path"
    printf '%s\n' "\$exit_code" >"\$exit_path"
    date -Is >"\$finished_at_path"
    rm -f "\$job_dir/pid"
}

fail_job() {
    local exit_code="\${1:-1}"
    finish_job failed "\$exit_code"
    exit "\$exit_code"
}

cancel_job() {
    if [[ -n "\${child_pid:-}" ]]; then
        kill "\$child_pid" 2>/dev/null || true
        wait "\$child_pid" 2>/dev/null || true
    fi
    finish_job canceled 130
    exit 130
}

trap cancel_job TERM INT

run_main() {
    printf '%s\n' running >"\$status_path"
    date -Is >"\$job_dir/started_at"

    cd "\$workdir"
    set +e
    bash -lc "\$command_string" >>"\$log_path" 2>&1 &
    child_pid=\$!
    wait "\$child_pid"
    rc=\$?
    set -e

    if [[ "\$rc" -eq 0 ]]; then
        finish_job finished "\$rc"
    else
        finish_job failed "\$rc"
    fi

    exit "\$rc"
}

set +e
run_main
rc=\$?
set -e

if [[ ! -e "\$exit_path" ]]; then
    finish_job failed "\$rc"
fi

exit "\$rc"
EOF
    chmod +x "$dir/run.sh"
}

start_job() {
    local job_id="$1"
    local kind="$2"
    local workdir="$3"
    local command_string="$4"
    local dir
    dir="$(job_dir "$job_id")"
    mkdir -p "$dir"
    printf '%s\n' "$kind" >"$dir/kind"
    printf '%s\n' "$workdir" >"$dir/workdir"
    printf '%s\n' "$command_string" >"$dir/command"
    write_run_script "$job_id" "$workdir" "$command_string"
    nohup "$dir/run.sh" >/dev/null 2>&1 </dev/null &
    printf '%s\n' "$!" >"$dir/pid"
    printf 'job_id=%s\nstate=running\nhost=%s\n' "$job_id" "$(hostname -s)"
}

status_job() {
    local job_id="$1"
    local dir
    local state
    local pid
    local exit_code
    dir="$(job_dir "$job_id")"
    [[ -d "$dir" ]] || {
        printf 'job_id=%s\nstate=unknown\n' "$job_id"
        return 1
    }
    if [[ -r "$dir/status" ]]; then
        state="$(<"$dir/status")"
    else
        state="queued"
    fi
    if [[ -r "$dir/pid" ]]; then
        pid="$(<"$dir/pid")"
    else
        pid=""
    fi
    if [[ -r "$dir/exit_code" ]]; then
        exit_code="$(<"$dir/exit_code")"
    else
        exit_code=""
    fi
    if [[ -z "$exit_code" && -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        state="running"
    fi
    printf 'job_id=%s\nstate=%s\n' "$job_id" "$state"
    if [[ -n "$exit_code" ]]; then
        printf 'exit_code=%s\n' "$exit_code"
    fi
    if [[ -r "$dir/started_at" ]]; then
        printf 'started_at=%s\n' "$(<"$dir/started_at")"
    fi
    if [[ -r "$dir/finished_at" ]]; then
        printf 'finished_at=%s\n' "$(<"$dir/finished_at")"
    fi
}

tail_job() {
    local job_id="$1"
    local lines="$2"
    local dir
    dir="$(job_dir "$job_id")"
    [[ -d "$dir" ]] || return 1
    if [[ -r "$dir/log.txt" ]]; then
        tail -n "$lines" "$dir/log.txt"
    fi
}

cancel_job() {
    local job_id="$1"
    local dir
    local pid
    dir="$(job_dir "$job_id")"
    [[ -d "$dir" ]] || {
        printf 'job_id=%s\nstate=unknown\n' "$job_id"
        return 1
    }
    if [[ -r "$dir/pid" ]]; then
        pid="$(<"$dir/pid")"
    else
        pid=""
    fi
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null || true
        sleep 1
        if kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid" 2>/dev/null || true
        fi
    fi
    printf '%s\n' canceled >"$dir/status"
    printf '%s\n' 130 >"$dir/exit_code"
    date -Is >"$dir/finished_at"
    rm -f "$dir/pid"
    printf 'job_id=%s\nstate=canceled\nexit_code=130\n' "$job_id"
}

host_status() {
    local host
    local cpu_count
    local load1
    local load5
    local load15
    local mem_total_kb
    local mem_available_kb
    local gpu_json="[]"
    local gpu_count=0

    host="$(hostname -s)"
    cpu_count="$(getconf _NPROCESSORS_ONLN 2>/dev/null || nproc 2>/dev/null || printf '0')"
    read -r load1 load5 load15 _ </proc/loadavg
    mem_total_kb="$(awk '/MemTotal:/ { print $2; exit }' /proc/meminfo 2>/dev/null || printf '0')"
    mem_available_kb="$(awk '/MemAvailable:/ { print $2; exit }' /proc/meminfo 2>/dev/null || printf '0')"

    if command -v nvidia-smi >/dev/null 2>&1; then
        local first_gpu=1
        local line
        while IFS=, read -r idx name util mem_used mem_total; do
            idx="${idx//[[:space:]]/}"
            name="${name#${name%%[![:space:]]*}}"
            util="${util//[[:space:]]/}"
            mem_used="${mem_used//[[:space:]]/}"
            mem_total="${mem_total//[[:space:]]/}"
            [[ -n "$idx" ]] || continue
            if [[ "$first_gpu" -eq 1 ]]; then
                gpu_json='['
                first_gpu=0
            else
                gpu_json+=','
            fi
            gpu_json+="{\"index\":$idx,\"name\":\"$(json_escape "$name")\",\"utilization_gpu_pct\":${util:-0},\"memory_used_mb\":${mem_used:-0},\"memory_total_mb\":${mem_total:-0}}"
            gpu_count=$((gpu_count + 1))
        done < <(nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null || true)
        if [[ "$first_gpu" -eq 0 ]]; then
            gpu_json+=']'
        fi
    fi

    printf '{'
    printf '"host":"%s",' "$(json_escape "$host")"
    printf '"cpu_count":%s,' "${cpu_count:-0}"
    printf '"load1":%s,' "${load1:-0}"
    printf '"load5":%s,' "${load5:-0}"
    printf '"load15":%s,' "${load15:-0}"
    printf '"mem_total_bytes":%s,' "$(( ${mem_total_kb:-0} * 1024 ))"
    printf '"mem_available_bytes":%s,' "$(( ${mem_available_kb:-0} * 1024 ))"
    printf '"gpu_count":%s,' "$gpu_count"
    printf '"gpus":%s' "$gpu_json"
    printf '}\n'
}

verb="${1:-}"
shift || true

case "$verb" in
    start) start_job "$@" ;;
    status) status_job "$@" ;;
    tail) tail_job "$@" ;;
    cancel) cancel_job "$@" ;;
    host-status) host_status ;;
    *)
        echo "unknown verb: $verb" >&2
        exit 1
        ;;
esac
