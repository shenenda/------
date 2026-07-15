#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 3 ]]; then
    echo "usage: $0 <name> <actor> <trigger>" >&2
    exit 2
fi

name=$1
actor=$2
trigger=$3
root=${BENCH_ROOT:-/tmp/tinywebserver-official-benchmark-4bcf887}
results=$root/benchmark_results
webbench=/root/myWebserver_didida/test_pressure/webbench-1.5/webbench
port=9016
server_pid=
monitor_pid=

cleanup() {
    set +e
    if [[ -n "${monitor_pid:-}" ]]; then
        kill "$monitor_pid" 2>/dev/null || true
        wait "$monitor_pid" 2>/dev/null || true
    fi
    if [[ -n "${server_pid:-}" ]]; then
        kill -TERM "$server_pid" 2>/dev/null || true
        for _ in $(seq 1 20); do
            kill -0 "$server_pid" 2>/dev/null || break
            sleep 0.25
        done
        kill -KILL "$server_pid" 2>/dev/null || true
        wait "$server_pid" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

mkdir -p "$results"
cd "$root"

if ss -lnt | awk '{print $4}' | grep -q ":${port}$"; then
    echo "port $port is already in use" >&2
    exit 1
fi

rm -f "$results/$name-server.log" \
      "$results/$name-webbench.txt" \
      "$results/$name-cpu.txt" \
      "$results/$name-metadata.txt"

./server -p "$port" -a "$actor" -m "$trigger" -c 1 \
    > "$results/$name-server.log" 2>&1 &
server_pid=$!

ready=0
for _ in $(seq 1 30); do
    if curl --max-time 1 -sS -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null; then
        ready=1
        break
    fi
    if ! kill -0 "$server_pid" 2>/dev/null; then
        echo "server exited during startup" >&2
        tail -n 30 "$results/$name-server.log" >&2
        exit 1
    fi
    sleep 0.2
done

if [[ $ready -ne 1 ]]; then
    echo "server did not become ready" >&2
    exit 1
fi

smoke=$(curl --max-time 2 -sS -o /dev/null \
    -w '%{http_code},%{size_download}' "http://127.0.0.1:$port/")
start_ticks=$(awk '{print $14 + $15}' "/proc/$server_pid/stat")
start_uptime=$(awk '{print $1}' /proc/uptime)
clk_tck=$(getconf CLK_TCK)

timeout --signal=TERM --kill-after=3s 38s \
    pidstat -h -p "$server_pid" 1 32 > "$results/$name-cpu.txt" 2>&1 &
monitor_pid=$!

set +e
timeout --signal=TERM --kill-after=5s 45s \
    stdbuf -oL "$webbench" -c 100 -t 30 "http://127.0.0.1:$port/" \
    > "$results/$name-webbench.txt" 2>&1
bench_rc=$?
set -e

wait "$monitor_pid" || true
monitor_pid=

if kill -0 "$server_pid" 2>/dev/null; then
    end_ticks=$(awk '{print $14 + $15}' "/proc/$server_pid/stat")
    end_uptime=$(awk '{print $1}' /proc/uptime)
    post_smoke=$(curl --max-time 2 -sS -o /dev/null \
        -w '%{http_code},%{size_download}' "http://127.0.0.1:$port/" || true)
    server_alive=yes
else
    end_ticks=$start_ticks
    end_uptime=$start_uptime
    post_smoke=unavailable
    server_alive=no
fi

cpu_percent=$(awk -v st="$start_ticks" -v et="$end_ticks" \
    -v su="$start_uptime" -v eu="$end_uptime" -v hz="$clk_tck" \
    'BEGIN { elapsed=eu-su; if (elapsed > 0) printf "%.2f", ((et-st)/hz)/elapsed*100; else print "nan" }')

if grep -q '^Speed=' "$results/$name-webbench.txt" && \
   grep -q '^Requests:' "$results/$name-webbench.txt"; then
    result_complete=yes
else
    result_complete=no
fi

{
    echo "name=$name"
    echo "official_commit=$(git rev-parse HEAD)"
    echo "source_commit=$(git rev-parse HEAD)"
    echo "source_diff=$(git diff --numstat | tr '\t' ',' | paste -sd ';' -)"
    echo "build_command=g++ official sources -g -lpthread -lmysqlclient"
    echo "host=$(hostname)"
    echo "kernel=$(uname -r)"
    echo "logical_cpus=$(nproc)"
    echo "actor=$actor"
    echo "trigger=$trigger"
    echo "server_command=./server -p $port -a $actor -m $trigger -c 1"
    echo "benchmark_command=webbench -c 100 -t 30 http://127.0.0.1:$port/"
    echo "pre_smoke=$smoke"
    echo "post_smoke=$post_smoke"
    echo "server_alive_after_benchmark=$server_alive"
    echo "server_cpu_percent_over_interval=$cpu_percent"
    echo "webbench_exit_code=$bench_rc"
    echo "webbench_result_complete=$result_complete"
} > "$results/$name-metadata.txt"

cat "$results/$name-metadata.txt"
grep -E 'Speed=|Requests:' "$results/$name-webbench.txt" || true

if [[ $result_complete == yes ]]; then
    exit 0
fi
exit "$bench_rc"
