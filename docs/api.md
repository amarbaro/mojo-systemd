# API

`from systemd import ...`

| Function | Sends | Returns |
|---|---|---|
| `notify(state: String) raises -> Bool` | `state` as one datagram | `True` sent, `False` no `$NOTIFY_SOCKET`; raises on a bad or unreachable socket |
| `ready(msg: String = "") raises -> Bool` | `READY=1`, plus `\nSTATUS=msg` when set | as `notify` |
| `status(msg: String) raises -> Bool` | `STATUS=msg` | as `notify` |
| `watchdog() raises -> Bool` | `WATCHDOG=1` | as `notify` |
| `stopping() raises -> Bool` | `STOPPING=1` | as `notify` |
| `reloading() raises -> Bool` | `RELOADING=1\nMONOTONIC_USEC=<now>` | as `notify` |
| `watchdog_usec() -> Int` | nothing | `$WATCHDOG_USEC`, or 0 when unset, unparsable, or `$WATCHDOG_PID` is not this process |

Notes:

- `$NOTIFY_SOCKET` must start with `/` (a path) or `@` (abstract namespace). Anything else raises.
- The unit needs `NotifyAccess=main` (the default for `Type=notify`) unless a child sends.
- Ping at about half of `watchdog_usec()`.
- No file descriptor stays open: each call opens, sends and closes one datagram socket.
