#!/usr/bin/env bash

CUR_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../shell_config.sh
. "$CUR_DIR"/../shell_config.sh

query_id=$(echo "select queryID() from (select sum(s), k from remote('127.0.0.{1,2}', view(select sum(number) s, bitAnd(number, 3) k from numbers_mt(1000000) group by k)) group by k) limit 1 settings group_by_two_level_threshold=1, max_threads=3, prefer_localhost_replica=1" | ${CLICKHOUSE_CURL} -sS "${CLICKHOUSE_URL}" --data-binary @- 2>&1)

${CLICKHOUSE_CLIENT} --query="system flush logs"
${CLICKHOUSE_CLIENT} --query="select count() from system.text_log where event_date >= today() - 1 and query_id = '${query_id}' and message like '%Converting aggregation data to two-level%'"
