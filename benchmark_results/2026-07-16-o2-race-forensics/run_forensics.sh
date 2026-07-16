#!/usr/bin/env bash
set -Eeuo pipefail

readonly BASELINE_COMMIT=a57a275b4866cbc309f51f00da24dcc081030775
readonly FIXED_COMMIT=8d225cb523a92472e3141bed542a29eb53879ec1
readonly OFFICIAL_COMMIT=4bcf88762f85135e9bd46a1032e815e458de6f2e

source_repo=${SOURCE_REPO:-/root/myWebserver_didida}
official_repo=${OFFICIAL_REPO:-https://github.com/qinguoyi/TinyWebServer.git}
official_source_dir=${OFFICIAL_SOURCE_DIR:-}
work_root=${FORENSIC_ROOT:-/tmp/reactor-o2-race-forensics}
results=${RESULT_ROOT:-$work_root/results}
webbench=${WEBBENCH_BIN:-/root/myWebserver_didida/test_pressure/webbench-1.5/webbench}
clients=${BENCH_CLIENTS:-100}
seconds=${BENCH_SECONDS:-30}
port=${BENCH_PORT:-9026}

baseline_src=$work_root/baseline
volatile_src=$work_root/baseline-volatile
atomic_src=$work_root/baseline-atomic
fixed_src=$work_root/fixed
official_src=$work_root/official

sources=(
    main.cpp
    timer/lst_timer.cpp
    http/http_conn.cpp
    log/log.cpp
    CGImysql/sql_connection_pool.cpp
    webserver.cpp
    config.cpp
)

server_pid=
monitor_pid=

cleanup_server() {
    set +e
    if [[ -n "${monitor_pid:-}" ]]; then
        kill "$monitor_pid" 2>/dev/null || true
        wait "$monitor_pid" 2>/dev/null || true
        monitor_pid=
    fi
    if [[ -n "${server_pid:-}" ]]; then
        kill -TERM "$server_pid" 2>/dev/null || true
        for _ in $(seq 1 20); do
            kill -0 "$server_pid" 2>/dev/null || break
            sleep 0.1
        done
        kill -KILL "$server_pid" 2>/dev/null || true
        wait "$server_pid" 2>/dev/null || true
        server_pid=
    fi
    set -e
}

cleanup_all() {
    cleanup_server
}
trap cleanup_all EXIT INT TERM

prepare_checkout() {
    local destination=$1
    local commit=$2

    git clone --quiet --no-hardlinks "$source_repo" "$destination"
    git -C "$destination" checkout --quiet --detach "$commit"
}

prepare_official_checkout() {
    if [[ -n "$official_source_dir" ]]; then
        mkdir -p "$official_src"
        cp -a "$official_source_dir"/. "$official_src"/
        echo "$OFFICIAL_COMMIT" > "$official_src/.source_commit"
        echo 'main.cpp: database credentials only' > "$official_src/.source_diff"
    else
        git clone --quiet "$official_repo" "$official_src"
        git -C "$official_src" checkout --quiet --detach "$OFFICIAL_COMMIT"
    fi
    sed -i -E \
        -e 's/string user = "[^"]*";/string user = "webserver";/' \
        -e 's/string passwd = "[^"]*";/string passwd = "126634";/' \
        -e 's/string databasename = "[^"]*";/string databasename = "yourdb";/' \
        "$official_src/main.cpp"
}

source_commit_for() {
    local source_dir=$1
    if git -C "$source_dir" rev-parse HEAD >/dev/null 2>&1; then
        git -C "$source_dir" rev-parse HEAD
    else
        cat "$source_dir/.source_commit"
    fi
}

source_diff_for() {
    local source_dir=$1
    if git -C "$source_dir" rev-parse HEAD >/dev/null 2>&1; then
        git -C "$source_dir" diff --numstat | tr '\t' ',' | paste -sd ';' -
    else
        cat "$source_dir/.source_diff"
    fi
}

build_server() {
    local source_dir=$1
    local output_name=$2
    local optimization=$3
    local db_flags

    db_flags="$(mysql_config --cflags --libs 2>/dev/null || mariadb_config --cflags --libs)"
    (
        cd "$source_dir"
        # Keep the original argument order used for the historical binary.
        # shellcheck disable=SC2086
        g++ -std=c++11 "$optimization" -Wall "${sources[@]}" \
            -o "$output_name" -pthread $db_flags
    ) > "$results/$output_name-build.txt" 2>&1
}

db_flags_for_metadata() {
    (mysql_config --cflags --libs 2>/dev/null || mariadb_config --cflags --libs) | xargs
}

record_elf() {
    local source_dir=$1
    local binary_name=$2
    local label=$3
    local binary=$source_dir/$binary_name

    {
        echo "label=$label"
        echo "binary=$binary"
        stat --printf='size_bytes=%s\nmtime=%y\n' "$binary"
        file "$binary"
        readelf -n "$binary" | grep -A3 'Build ID' || true
        sha256sum "$binary"
    } > "$results/$label-elf.txt"

    objdump -d -C --no-show-raw-insn "$binary" | awk '
        /^[[:xdigit:]]+ <WebServer::dealwith(read|write)\(int\)>:$/ {
            remaining = 100
        }
        remaining > 0 {
            sub(/[[:space:]]+$/, "")
            print
            --remaining
        }
    ' > "$results/$label-reactor-entry-disassembly.txt"
}

capture_process_state() {
    local label=$1
    local phase=$2
    local output=$results/$label-$phase-process.txt

    {
        date --iso-8601=ns
        ps -L -p "$server_pid" -o pid,tid,psr,pcpu,stat,wchan:28,comm
        echo
        for task in /proc/"$server_pid"/task/*; do
            printf 'tid=%s wchan=' "${task##*/}"
            cat "$task/wchan" 2>/dev/null || true
        done
    } > "$output" 2>&1 || true
}

capture_backtrace() {
    local label=$1
    if command -v gdb >/dev/null 2>&1; then
        timeout 10s gdb --batch --quiet \
            -ex 'set pagination off' \
            -ex 'thread apply all bt' \
            -p "$server_pid" \
            > "$results/$label-post-backtrace.txt" 2>&1 || true
    else
        echo 'gdb is not installed' > "$results/$label-post-backtrace.txt"
    fi
}

run_case() {
    local label=$1
    local source_dir=$2
    local binary_name=$3
    local trigger=$4
    local build_kind=$5
    local binary=$source_dir/$binary_name
    local ready=0
    local bench_rc
    local result_complete=no
    local start_ticks
    local end_ticks
    local start_uptime
    local end_uptime
    local clk_tck
    local cpu_percent
    local pre_smoke
    local post_smoke

    cleanup_server
    if ss -lnt | awk '{print $4}' | grep -q ":${port}$"; then
        echo "port $port is already in use" >&2
        exit 1
    fi

    (
        cd "$source_dir"
        exec "$binary" -p "$port" -a 1 -m "$trigger" -c 1
    ) > "$results/$label-server.log" 2>&1 &
    server_pid=$!

    for _ in $(seq 1 40); do
        if curl --max-time 1 -sS -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null; then
            ready=1
            break
        fi
        if ! kill -0 "$server_pid" 2>/dev/null; then
            echo "$label: server exited during startup" >&2
            tail -n 30 "$results/$label-server.log" >&2
            exit 1
        fi
        sleep 0.2
    done
    if [[ $ready -ne 1 ]]; then
        echo "$label: server did not become ready" >&2
        exit 1
    fi

    pre_smoke=$(curl --max-time 2 -sS -o /dev/null \
        -w '%{http_code},%{size_download}' "http://127.0.0.1:$port/")
    start_ticks=$(awk '{print $14 + $15}' "/proc/$server_pid/stat")
    start_uptime=$(awk '{print $1}' /proc/uptime)
    clk_tck=$(getconf CLK_TCK)

    timeout --signal=TERM --kill-after=3s "$((seconds + 8))s" \
        pidstat -h -p "$server_pid" 1 "$((seconds + 2))" \
        > "$results/$label-cpu.txt" 2>&1 &
    monitor_pid=$!

    (
        sleep 5
        if kill -0 "$server_pid" 2>/dev/null; then
            capture_process_state "$label" during
        fi
    ) &

    set +e
    timeout --signal=TERM --kill-after=5s "$((seconds + 15))s" \
        stdbuf -oL "$webbench" -c "$clients" -t "$seconds" \
        "http://127.0.0.1:$port/" \
        > "$results/$label-webbench.txt" 2>&1
    bench_rc=$?
    set -e

    wait "$monitor_pid" || true
    monitor_pid=

    if kill -0 "$server_pid" 2>/dev/null; then
        end_ticks=$(awk '{print $14 + $15}' "/proc/$server_pid/stat")
        end_uptime=$(awk '{print $1}' /proc/uptime)
        post_smoke=$(curl --max-time 2 -sS -o /dev/null \
            -w '%{http_code},%{size_download}' "http://127.0.0.1:$port/" || true)
        capture_process_state "$label" post
        capture_backtrace "$label"
    else
        end_ticks=$start_ticks
        end_uptime=$start_uptime
        post_smoke=server-exited
    fi

    cpu_percent=$(awk -v st="$start_ticks" -v et="$end_ticks" \
        -v su="$start_uptime" -v eu="$end_uptime" -v hz="$clk_tck" \
        'BEGIN { elapsed=eu-su; if (elapsed > 0) printf "%.2f", ((et-st)/hz)/elapsed*100; else print "nan" }')

    if grep -q '^Speed=' "$results/$label-webbench.txt" && \
       grep -q '^Requests:' "$results/$label-webbench.txt"; then
        result_complete=yes
    fi

    {
        echo "label=$label"
        echo "source_commit=$(source_commit_for "$source_dir")"
        echo "source_diff=$(source_diff_for "$source_dir")"
        echo "build_kind=$build_kind"
        echo "compiler=$(g++ --version | head -n 1)"
        echo "host=$(hostname)"
        echo "kernel=$(uname -r)"
        echo "logical_cpus=$(nproc)"
        echo "actor=1"
        echo "trigger=$trigger"
        echo "server_command=$binary -p $port -a 1 -m $trigger -c 1"
        echo "benchmark_command=$webbench -c $clients -t $seconds http://127.0.0.1:$port/"
        echo "pre_smoke=$pre_smoke"
        echo "post_smoke=$post_smoke"
        echo "server_cpu_percent_over_interval=$cpu_percent"
        echo "webbench_exit_code=$bench_rc"
        echo "webbench_result_complete=$result_complete"
    } > "$results/$label-metadata.txt"

    cat "$results/$label-metadata.txt"
    grep -E 'Speed=|Requests:' "$results/$label-webbench.txt" || true
    cleanup_server
}

if [[ ! -x "$webbench" ]]; then
    echo "webbench is not executable: $webbench" >&2
    exit 1
fi

rm -rf "$work_root"
mkdir -p "$results"

if [[ ${FORENSIC_SCOPE:-all} == official ]]; then
    prepare_official_checkout
    build_server "$official_src" server-official-o2 -O2
    record_elf "$official_src" server-official-o2 official-o2
    {
        echo "run_at=$(date --iso-8601=seconds)"
        echo "official_repo=$official_repo"
        echo "official_commit=$OFFICIAL_COMMIT"
        echo "source_diff=$(source_diff_for "$official_src")"
        echo "build_command=g++ -std=c++11 -O2 -Wall main.cpp timer/lst_timer.cpp http/http_conn.cpp log/log.cpp CGImysql/sql_connection_pool.cpp webserver.cpp config.cpp -o server -pthread \$DB_FLAGS"
        echo "db_flags=$(db_flags_for_metadata)"
    } > "$results/environment.txt"
    run_case official-o2-reactor-ltlt "$official_src" server-official-o2 0 official-O2
    run_case official-o2-reactor-etet "$official_src" server-official-o2 3 official-O2
    echo "official forensic results: $results"
    exit 0
fi

if [[ ${FORENSIC_SCOPE:-all} == atomic ]]; then
    prepare_checkout "$atomic_src" "$BASELINE_COMMIT"
    sed -i \
        -e '/#include <map>/a #include <atomic>' \
        -e 's/^    int timer_flag;/    std::atomic<int> timer_flag;/' \
        -e 's/^    int improv;/    std::atomic<int> improv;/' \
        "$atomic_src/http/http_conn.h"
    build_server "$atomic_src" server-a57-o2-atomic -O2
    record_elf "$atomic_src" server-a57-o2-atomic a57-o2-atomic
    {
        echo "run_at=$(date --iso-8601=seconds)"
        echo "source_repo=$source_repo"
        echo "baseline_commit=$BASELINE_COMMIT"
        echo "source_diff=$(source_diff_for "$atomic_src")"
        echo "build_command=g++ -std=c++11 -O2 -Wall historical sources with atomic flags"
        echo "db_flags=$(db_flags_for_metadata)"
    } > "$results/environment.txt"
    run_case a57-o2-atomic-reactor-ltlt "$atomic_src" server-a57-o2-atomic 0 O2-atomic-diagnostic
    run_case a57-o2-atomic-reactor-etet "$atomic_src" server-a57-o2-atomic 3 O2-atomic-diagnostic
    echo "atomic forensic results: $results"
    exit 0
fi

prepare_checkout "$baseline_src" "$BASELINE_COMMIT"
cp -a "$baseline_src" "$volatile_src"
prepare_checkout "$fixed_src" "$FIXED_COMMIT"

# This is diagnostic only. volatile forces repeated loads but is not a valid
# replacement for C++ synchronization primitives.
sed -i \
    -e 's/^    int timer_flag;/    volatile int timer_flag;/' \
    -e 's/^    int improv;/    volatile int improv;/' \
    "$volatile_src/http/http_conn.h"

build_server "$baseline_src" server-a57-o0 -O0
build_server "$baseline_src" server-a57-o2 -O2
build_server "$volatile_src" server-a57-o2-volatile -O2
build_server "$fixed_src" server-fixed-o2 -O2

record_elf "$baseline_src" server-a57-o0 a57-o0
record_elf "$baseline_src" server-a57-o2 a57-o2
record_elf "$volatile_src" server-a57-o2-volatile a57-o2-volatile
record_elf "$fixed_src" server-fixed-o2 fixed-o2

{
    echo "run_at=$(date --iso-8601=seconds)"
    echo "source_repo=$source_repo"
    echo "baseline_commit=$BASELINE_COMMIT"
    echo "fixed_commit=$FIXED_COMMIT"
    echo "historical_build_command=g++ -std=c++11 -O2 -Wall main.cpp timer/lst_timer.cpp http/http_conn.cpp log/log.cpp CGImysql/sql_connection_pool.cpp webserver.cpp config.cpp -o server -pthread \$DB_FLAGS"
    echo "db_flags=$(db_flags_for_metadata)"
} > "$results/environment.txt"

run_case a57-o0-reactor-ltlt "$baseline_src" server-a57-o0 0 O0-control
run_case a57-o0-reactor-etet "$baseline_src" server-a57-o0 3 O0-control
run_case a57-o2-reactor-ltlt "$baseline_src" server-a57-o2 0 historical-O2
run_case a57-o2-reactor-etet "$baseline_src" server-a57-o2 3 historical-O2
run_case a57-o2-volatile-reactor-ltlt "$volatile_src" server-a57-o2-volatile 0 O2-volatile-diagnostic
run_case a57-o2-volatile-reactor-etet "$volatile_src" server-a57-o2-volatile 3 O2-volatile-diagnostic
run_case fixed-o2-reactor-ltlt "$fixed_src" server-fixed-o2 0 fixed-O2
run_case fixed-o2-reactor-etet "$fixed_src" server-fixed-o2 3 fixed-O2

echo "forensic results: $results"
