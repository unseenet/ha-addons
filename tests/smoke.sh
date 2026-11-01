#!/bin/sh
# Build the add-ons and start them against fake options, as the Supervisor would
# (its /data with options.json, a tmpfs /tmp) - but without Tor.
#
#   tests/smoke.sh [node|replica]...      (default: both)
#
# The base image is the one pinned in each add-on's build.yaml (amd64); set
# NODE_BASE or REPLICA_BASE to test another.
set -eu
cd "$(dirname "$0")/.."
WORK=$(mktemp -d)
cleanup() {
    docker rm -f ha-smoke-node ha-smoke-replica >/dev/null 2>&1 || true
    # the services' files are uid 10001's: remove them as root in a container
    for img in ha-addon-node:smoke ha-addon-replica:smoke; do
        docker run --rm --entrypoint rm -v "$WORK:/w" "$img" -rf /w/node /w/replica \
            >/dev/null 2>&1 && break
    done
    rm -rf "$WORK"
}
trap cleanup EXIT

base() {   # the amd64 image in an add-on's build.yaml
    sed -n 's/^ *amd64: *//p' "$1/build.yaml"
}
say() { printf '\n== %s\n' "$*"; }
ok() { printf 'ok - %s\n' "$*"; }
no() { printf 'not ok - %s\n' "$*" >&2; exit 1; }

opts() {   # opts DIR JSON: the Supervisor's options.json in a fresh /data
    mkdir -p "$1" && printf '%s\n' "$2" > "$1/options.json"
}

wait_log() {   # wait_log CONTAINER PATTERN [SECONDS]
    i=0
    while [ "$i" -lt "${3:-60}" ]; do
        docker logs "$1" 2>&1 | grep -q "$2" && return 0
        i=$((i + 1)); sleep 1
    done
    docker logs "$1" 2>&1 | tail -20 >&2
    return 1
}

as_user() {   # as_user CONTAINER COMMAND: run as the service's user
    docker exec "$1" su-exec unseenet sh -c "$2"
}

node() {
    img=ha-addon-node:smoke
    say "build unseenet-node on ${NODE_BASE:-$(base unseenet-node)}"
    docker build -q --build-arg BUILD_FROM="${NODE_BASE:-$(base unseenet-node)}" \
        --build-arg BUILD_ARCH=amd64 --build-arg BUILD_VERSION=smoke -t "$img" unseenet-node >/dev/null
    ok "built"

    D=$WORK/node
    run="docker run --rm --tmpfs /tmp -e UNSEENET_NO_TOR=1 -v $D:/data"

    opts "$D" '{"passphrase": ""}'
    $run "$img" >/dev/null 2>&1 && no "starts without a passphrase" || [ $? -eq 64 ] || no "exit code"
    ok "no passphrase: exit 64"

    opts "$D" '{"node_name": "ha-smoke", "passphrase": "ci passphrase 1", "peers": [{"name": "p1",
        "address": "abcdefghijklmnopqrstuvwxyz234567abcdefghijklmnopqrstuvwx.onion",
        "key": "ed25519:bjhcf6tbf2yt37vn7iomsdg5o4xlvdvudjndnm4prrveiur3cukq", "groups": "alt.*"}],
        "carries": ["*"], "auto_peers": 3, "announce": true, "retention_days": 30, "min_pow": 18,
        "new_groups": "accept", "files": true, "encrypted_files": false, "profile_pictures": true,
        "sites": false, "listen_internal": false, "manage_config": true}'
    docker run -d --name ha-smoke-node --tmpfs /tmp -e UNSEENET_NO_TOR=1 -v "$D:/data" "$img" >/dev/null
    wait_log ha-smoke-node "node key: ed25519:" || no "the node key is not in the log"
    KEY=$(docker logs ha-smoke-node 2>&1 | sed -n 's/.*node key: \(ed25519:[a-z2-7]*\).*/\1/p' | head -1)
    ok "node key in the log: $KEY"
    for i in $(seq 1 30); do
        docker exec ha-smoke-node python3 -c "import asyncio; from unseenet.node.stats import fetch; \
            asyncio.run(fetch('/data/node/monitor.sock'))" 2>/dev/null && break
        sleep 2
    done
    docker exec ha-smoke-node unseenet-monitor --version >/dev/null || no "monitor"
    ok "the node answers on its monitor socket"
    docker exec ha-smoke-node ps -o user,args | grep -q "^unseenet .*unseenet-node" || no "node not as unseenet"
    ok "the node runs as unseenet"
    docker exec ha-smoke-node grep -q 'name = "p1"' /data/node/node.toml || no "peer not in node.toml"
    docker exec ha-smoke-node grep -q 'retention_days = 30' /data/node/node.toml || no "retention"
    docker exec ha-smoke-node grep -q 'avatars = "accept"' /data/node/node.toml || no "avatars"
    docker exec ha-smoke-node python3 -c "import tomllib; tomllib.load(open('/data/node/node.toml', 'rb'))"
    ok "node.toml written from the options, and valid TOML"
    as_user ha-smoke-node 'cat /data/options.json' 2>/dev/null && no "the node's user reads options.json"
    as_user ha-smoke-node 'ls /data' >/dev/null 2>&1 && no "the node's user lists /data"
    docker exec ha-smoke-node sh -c 'stat -c "%a %U" /tmp/addon/passphrase' | grep -qx "600 unseenet" \
        || no "the passphrase file"
    ok "the options stay out of the node's reach; the passphrase is a mode-600 file in /tmp"
    docker rm -f ha-smoke-node >/dev/null

    opts "$D" '{"node_name": "ha-smoke", "passphrase": "ci passphrase 1", "peers": [],
        "carries": ["alt.*", "dk.*"], "auto_peers": 0, "announce": false, "retention_days": 90,
        "min_pow": 18, "new_groups": "manual", "files": false, "encrypted_files": false,
        "profile_pictures": false, "sites": false, "listen_internal": true, "manage_config": true}'
    docker run -d --name ha-smoke-node --tmpfs /tmp -e UNSEENET_NO_TOR=1 -v "$D:/data" "$img" >/dev/null
    wait_log ha-smoke-node "node key: $KEY" || no "a new key after a restart"
    wait_log ha-smoke-node "listening on 0.0.0.0:1119" || no "listen_internal"
    ok "listen_internal opens port 1119 to the add-on network"
    docker exec ha-smoke-node grep -q '\[\[peer\]\]' /data/node/node.toml && no "the removed peer stayed"
    docker exec ha-smoke-node grep -q 'carries = \["alt.\*", "dk.\*"\]' /data/node/node.toml || no "carries"
    ok "a restart keeps the key and applies changed options"
    docker rm -f ha-smoke-node >/dev/null

    opts "$D" '{"passphrase": "not the passphrase", "manage_config": false}'
    $run "$img" >/dev/null 2>&1 && no "starts with a wrong passphrase"
    ok "a wrong passphrase stops it"
}

replica() {
    img=ha-addon-replica:smoke
    say "build unseenet-replica on ${REPLICA_BASE:-$(base unseenet-replica)}"
    docker build -q --build-arg BUILD_FROM="${REPLICA_BASE:-$(base unseenet-replica)}" \
        --build-arg BUILD_ARCH=amd64 --build-arg BUILD_VERSION=smoke -t "$img" unseenet-replica >/dev/null
    ok "built"

    D=$WORK/replica
    opts "$D" '{"passphrase": "", "nodes": [], "hold": []}'
    docker run --rm --tmpfs /tmp -v "$D:/data" "$img" >/dev/null 2>&1 && no "starts without a passphrase" \
        || [ $? -eq 64 ] || no "exit code"
    ok "no passphrase: exit 64"

    opts "$D" '{"passphrase": "ci passphrase 1", "nodes": ["127.0.0.1:9"], "hold": ["removal"]}'
    docker run -d --name ha-smoke-replica --tmpfs /tmp -v "$D:/data" "$img" >/dev/null
    wait_log ha-smoke-replica "INFO replica ed25519:" 120 || no "the replica's key is not in the log"
    ok "first start made the key"
    docker exec ha-smoke-replica ps -o user,args | grep -q "^unseenet .*unseenet-replica run" \
        || no "replica not as unseenet"
    ok "the replica runs as unseenet"
    docker exec ha-smoke-replica unseenet-replica status | grep -q "You hold: removal" || no "status/hold"
    ok "unseenet-replica status works through docker exec"
    as_user ha-smoke-replica 'cat /data/options.json' 2>/dev/null && no "the replica's user reads options.json"
    ok "the options stay out of the replica's reach"
    docker rm -f ha-smoke-replica >/dev/null

    opts "$D" '{"passphrase": "ci passphrase 1", "nodes": ["127.0.0.1:9", "127.0.0.1:10"], "hold": [],
        "group": "something.else@x"}'
    docker run -d --name ha-smoke-replica --tmpfs /tmp -v "$D:/data" "$img" >/dev/null
    wait_log ha-smoke-replica "starting the replica" || no "second start"
    docker exec ha-smoke-replica python3 -c "import json; c = json.load(open('/data/replica/config.json')); \
        assert c['hold'] == [] and c['nodes'] == ['127.0.0.1:9', '127.0.0.1:10'] \
        and c['group'] != 'something.else@x', c" || no "config.json"
    docker exec ha-smoke-replica stat -c %U /data/replica/config.json | grep -qx unseenet || no "owner"
    docker logs ha-smoke-replica 2>&1 | grep -q "keeps the group it was made for" || no "group warning"
    ok "a restart applies hold and nodes, and keeps the group"
}

[ $# -gt 0 ] || set -- node replica
for what in "$@"; do
    case "$what" in
        node) node ;;
        replica) replica ;;
        *) echo "usage: $0 [node|replica]..." >&2; exit 2 ;;
    esac
done
say "all good"
