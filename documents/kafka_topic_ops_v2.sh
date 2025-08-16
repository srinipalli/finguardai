#!/bin/sh
# kafka_topic_ops_v2.sh — BusyBox-friendly Kafka topic ops inside container
# Works across Apache/Confluent/Bitnami images; avoids brittle quoting.
# Usage (inside Windows host using docker exec):
#   docker cp kafka_topic_ops_v2.sh <container>:/tmp/kafka_topic_ops_v2.sh
#   docker exec <container> sh -c "chmod +x /tmp/kafka_topic_ops_v2.sh"
#   docker exec -e BOOTSTRAP=localhost:9092 <container> sh /tmp/kafka_topic_ops_v2.sh list
#
# Commands:
#   create   <topic> [partitions] [replication]
#   list
#   describe <topic>
#   delete   <topic>
#   produce  <topic>
#   consume  <topic>
#
# Env:
#   BOOTSTRAP (default: localhost:9092)
#   EXTRA_CREATE_FLAGS

set -e

BOOT="${BOOTSTRAP:-localhost:9092}"

# Try typical paths first (no 'find' needed). Fallback to command -v, then find.
resolve_cli() {
  TOPICS_CLI=""
  PRODUCER_CLI=""
  CONSUMER_CLI=""

  for f in \
    /opt/kafka/bin/kafka-topics.sh \
    /opt/kafka/bin/kafka-topics \
    /opt/bitnami/kafka/bin/kafka-topics.sh \
    /opt/bitnami/kafka/bin/kafka-topics \
    /usr/bin/kafka-topics.sh \
    /usr/bin/kafka-topics \
    /kafka/bin/kafka-topics.sh \
    /kafka/bin/kafka-topics
  do
    [ -x "$f" ] && { TOPICS_CLI="$f"; break; }
  done

  [ -n "$TOPICS_CLI" ] || TOPICS_CLI="$(command -v kafka-topics.sh 2>/dev/null || command -v kafka-topics 2>/dev/null || true)"
  if [ -z "$TOPICS_CLI" ]; then
    # BusyBox find with stderr suppressed
    TOPICS_CLI="$(find / -name kafka-topics.sh -type f 2>/dev/null | head -n1)"
  fi
  [ -n "$TOPICS_CLI" ] || { echo "ERROR: kafka-topics(.sh) not found in container." >&2; exit 1; }

  BIN_DIR="$(dirname "$TOPICS_CLI")"

  # Producer/consumer
  for p in kafka-console-producer.sh kafka-console-producer; do
    if [ -x "$BIN_DIR/$p" ]; then PRODUCER_CLI="$BIN_DIR/$p"; break; fi
  done
  [ -n "$PRODUCER_CLI" ] || PRODUCER_CLI="$(command -v kafka-console-producer.sh 2>/dev/null || command -v kafka-console-producer 2>/dev/null || true)"
  if [ -z "$PRODUCER_CLI" ]; then
    PRODUCER_CLI="$(find / -name kafka-console-producer.sh -type f 2>/dev/null | head -n1)"
  fi

  for c in kafka-console-consumer.sh kafka-console-consumer; do
    if [ -x "$BIN_DIR/$c" ]; then CONSUMER_CLI="$BIN_DIR/$c"; break; fi
  done
  [ -n "$CONSUMER_CLI" ] || CONSUMER_CLI="$(command -v kafka-console-consumer.sh 2>/dev/null || command -v kafka-console-consumer 2>/dev/null || true)"
  if [ -z "$CONSUMER_CLI" ]; then
    CONSUMER_CLI="$(find / -name kafka-console-consumer.sh -type f 2>/dev/null | head -n1)"
  fi
}

cmd_create() {
  topic="$1"; parts="${2:-1}"; repl="${3:-1}"
  [ -n "$topic" ] || { echo "Usage: $0 create <topic> [partitions] [replication]"; exit 2; }
  "$TOPICS_CLI" --bootstrap-server "$BOOT" --create --topic "$topic" \
    --partitions "$parts" --replication-factor "$repl" $EXTRA_CREATE_FLAGS
}

cmd_list() {
  "$TOPICS_CLI" --bootstrap-server "$BOOT" --list
}

cmd_describe() {
  topic="$1"; [ -n "$topic" ] || { echo "Usage: $0 describe <topic>"; exit 2; }
  "$TOPICS_CLI" --bootstrap-server "$BOOT" --describe --topic "$topic"
}

cmd_delete() {
  topic="$1"; [ -n "$topic" ] || { echo "Usage: $0 delete <topic>"; exit 2; }
  "$TOPICS_CLI" --bootstrap-server "$BOOT" --delete --topic "$topic"
}

cmd_produce() {
  topic="$1"; [ -n "$topic" ] || { echo "Usage: $0 produce <topic>"; exit 2; }
  if [ -n "$PRODUCER_CLI" ]; then
    printf "hello\nfrom\nkafka\n" | "$PRODUCER_CLI" --bootstrap-server "$BOOT" --topic "$topic"
  else
    echo "WARN: producer CLI not found; skipping." >&2
  fi
}

cmd_consume() {
  topic="$1"; [ -n "$topic" ] || { echo "Usage: $0 consume <topic>"; exit 2; }
  if [ -n "$CONSUMER_CLI" ]; then
    "$CONSUMER_CLI" --bootstrap-server "$BOOT" --topic "$topic" --from-beginning --timeout-ms 5000
  else
    echo "WARN: consumer CLI not found; skipping." >&2
  fi
}

usage() {
  cat <<EOF
Usage: $0 <command> [args]
Commands:
  create   <topic> [partitions] [replication]
  list
  describe <topic>
  delete   <topic>
  produce  <topic>
  consume  <topic>
Env:
  BOOTSTRAP (default: localhost:9092)
  EXTRA_CREATE_FLAGS
EOF
}

main() {
  resolve_cli
  case "$1" in
    create)   shift; cmd_create "$@";;
    list)     shift; cmd_list "$@";;
    describe) shift; cmd_describe "$@";;
    delete)   shift; cmd_delete "$@";;
    produce)  shift; cmd_produce "$@";;
    consume)  shift; cmd_consume "$@";;
    ""|help|-h|--help) usage;;
    *) echo "Unknown command: $1"; usage; exit 2;;
  esac
}

main "$@"
