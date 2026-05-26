#!/usr/bin/env python3
import json
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path


OUTPUT = Path.home() / ".claude" / "token-cat" / "claude-telemetry.jsonl"


def attr_value(value):
    if not isinstance(value, dict):
        return value
    for key in ("stringValue", "intValue", "doubleValue", "boolValue"):
        if key in value:
            raw = value[key]
            if key == "intValue":
                return int(raw)
            if key == "doubleValue":
                return float(raw)
            return raw
    return None


def direct_attributes(node):
    attributes = {}
    if isinstance(node, dict):
        for item in node.get("attributes", []):
            key = item.get("key")
            if key:
                attributes[key] = attr_value(item.get("value"))
    return attributes


def find_api_requests(node):
    requests = []
    if isinstance(node, dict):
        attributes = direct_attributes(node)
        event_name = attributes.get("event.name") or attributes.get("event")
        if event_name == "api_request":
            requests.append(attributes)
        for value in node.values():
            requests.extend(find_api_requests(value))
    elif isinstance(node, list):
        for item in node:
            requests.extend(find_api_requests(item))
    return requests


def timestamp_from(attributes):
    return (
        attributes.get("event.timestamp")
        or attributes.get("timestamp")
        or attributes.get("time_unix_nano")
    )


def int_attr(attributes, key):
    value = attributes.get(key)
    if value is None:
        return 0
    return int(value)


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("content-length", "0"))
        payload = self.rfile.read(length)

        try:
            body = json.loads(payload)
        except json.JSONDecodeError:
            self.send_response(400)
            self.end_headers()
            return

        OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        with OUTPUT.open("a", encoding="utf-8") as out:
            for attributes in find_api_requests(body):
                row = {
                    "timestamp": timestamp_from(attributes),
                    "event": "claude_code.api_request",
                    "input_tokens": int_attr(attributes, "input_tokens"),
                    "output_tokens": int_attr(attributes, "output_tokens"),
                    "cache_read_tokens": int_attr(attributes, "cache_read_tokens"),
                    "cache_creation_tokens": int_attr(attributes, "cache_creation_tokens"),
                }
                if row["timestamp"]:
                    out.write(json.dumps(row, separators=(",", ":")) + "\n")

        self.send_response(200)
        self.end_headers()

    def log_message(self, format, *args):
        return


if __name__ == "__main__":
    server = HTTPServer(("127.0.0.1", 4318), Handler)
    print(f"Claude telemetry collector writing {OUTPUT}")
    print("Listening on http://127.0.0.1:4318/v1/logs")
    server.serve_forever()
