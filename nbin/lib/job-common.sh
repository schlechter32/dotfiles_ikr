#!/run/current-system/sw/bin/bash

set -euo pipefail

JOB_LIB_DIR="$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")" && pwd -P)"
JOB_BROKER_STATE_DIR="${JOB_BROKER_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.cache/job-broker}}"
JOB_REMOTE_HELPER="${JOB_REMOTE_HELPER:-$JOB_LIB_DIR/job-remote-helper.sh}"
JOB_DEFAULT_HOST="${JOB_DEFAULT_HOST:-cobra2}"
JOB_SSH_CONNECT_TIMEOUT="${JOB_SSH_CONNECT_TIMEOUT:-5}"

readonly JOB_ALLOWED_HOSTS=(cobra0 cobra1 cobra2 cobra3 cobra4)

job_state_dir() {
    mkdir -p "$JOB_BROKER_STATE_DIR/jobs" "$JOB_BROKER_STATE_DIR/latest"
    printf '%s\n' "$JOB_BROKER_STATE_DIR"
}

job_usage_error() {
    echo "$*" >&2
    exit 1
}

job_require_remote_helper() {
    if [[ ! -r "$JOB_REMOTE_HELPER" ]]; then
        job_usage_error "remote helper not found at $JOB_REMOTE_HELPER"
    fi
}

job_is_allowed_host() {
    local host="$1"
    local candidate
    for candidate in "${JOB_ALLOWED_HOSTS[@]}"; do
        if [[ "$candidate" == "$host" ]]; then
            return 0
        fi
    done
    return 1
}

job_require_allowed_host() {
    local host="$1"
    if ! job_is_allowed_host "$host"; then
        job_usage_error "host '$host' is not allowed; allowed hosts: ${JOB_ALLOWED_HOSTS[*]}"
    fi
}

job_current_workdir() {
    pwd -P
}

job_task_key() {
    local workdir
    workdir="${1:-$(job_current_workdir)}"
    printf '%s' "$workdir" | sha256sum | cut -c1-16
}

job_latest_file() {
    local workdir
    workdir="${1:-$(job_current_workdir)}"
    printf '%s/latest/%s\n' "$(job_state_dir)" "$(job_task_key "$workdir")"
}

job_set_latest() {
    local job_id="$1"
    local workdir
    workdir="${2:-$(job_current_workdir)}"
    printf '%s\n' "$job_id" >"$(job_latest_file "$workdir")"
}

job_get_latest() {
    local workdir
    local latest_file
    workdir="${1:-$(job_current_workdir)}"
    latest_file="$(job_latest_file "$workdir")"
    [[ -r "$latest_file" ]] || return 1
    tr -d '\n' <"$latest_file"
}

job_metadata_path() {
    local job_id="$1"
    printf '%s/jobs/%s.env\n' "$(job_state_dir)" "$job_id"
}

job_require_metadata() {
    local metadata_path="$1"
    [[ -r "$metadata_path" ]] || job_usage_error "unknown job metadata: $metadata_path"
}

job_write_metadata() {
    local job_id="$1"
    local host="$2"
    local kind="$3"
    local workdir="$4"
    local remote_state_dir="$5"
    local command_string="$6"
    local metadata_path
    metadata_path="$(job_metadata_path "$job_id")"
    mkdir -p "$(dirname "$metadata_path")"
    {
        printf 'job_id=%q\n' "$job_id"
        printf 'host=%q\n' "$host"
        printf 'kind=%q\n' "$kind"
        printf 'workdir=%q\n' "$workdir"
        printf 'remote_state_dir=%q\n' "$remote_state_dir"
        printf 'command_string=%q\n' "$command_string"
    } >"$metadata_path"
}

job_load_metadata() {
    local job_id="$1"
    local metadata_path
    metadata_path="$(job_metadata_path "$job_id")"
    job_require_metadata "$metadata_path"
    # shellcheck disable=SC1090
    source "$metadata_path"
}

job_quote_words() {
    local out=()
    local item
    for item in "$@"; do
        out+=("$(printf '%q' "$item")")
    done
    printf '%s' "${out[*]}"
}

job_remote_invoke() {
    local host="$1"
    shift
    job_require_allowed_host "$host"
    job_require_remote_helper
    local remote_command
    remote_command="bash -s -- $(job_quote_words "$@")"
    ssh -T \
        -o BatchMode=yes \
        -o ConnectTimeout="$JOB_SSH_CONNECT_TIMEOUT" \
        -o ClearAllForwardings=yes \
        -o ForwardAgent=no \
        -o ForwardX11=no \
        "$host" "$remote_command" <"$JOB_REMOTE_HELPER"
}

job_generate_id() {
    printf 'job-%s-%04d\n' "$(date +%Y%m%d%H%M%S)" "$RANDOM"
}

job_json_escape() {
    local value="$1"
    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    value=${value//$'\n'/\\n}
    value=${value//$'\r'/\\r}
    value=${value//$'\t'/\\t}
    printf '%s' "$value"
}

job_print_json_kv() {
    local key="$1"
    local value="$2"
    printf '"%s":"%s"' "$(job_json_escape "$key")" "$(job_json_escape "$value")"
}
