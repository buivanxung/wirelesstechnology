
set -eou pipefail
IFS=$'\n\t'

url=${1:-http://localhost:3000/api/v1/todos}
db=${2:-todo}
duration=${3:-10}
users=${4:-20}

pg_connections() {
    db=${1:-$USER}
    user=${2:-$USER}
    query='SELECT sum(numbackends) FROM pg_stat_database;'
    conn=$(psql -U "$user" -t "$db" -c "$query" -w -q | sed -e '/^$/d;s/ //g')
    echo "$conn"
}

ps_running() {
    pid=${1:-0}
    # shellcheck disable=SC2009
    psout=$(ps "$pid" | grep -v '  PID' | awk '{ print $1}')
    if [[ -n "$psout" ]]; then return 0; else return 1; fi
}

ab -c "$users" -t "$duration" "$url" & WAITPID=$!
loop=1
 while ps_running "$WAITPID"; do
    conn=$(pg_connections todo)
    echo "$((loop++))s:	$conn connections"
    sleep 1
done
