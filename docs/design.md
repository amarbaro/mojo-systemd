# Design

Rules: no library to link, no state kept between calls, nothing allocated that outlives a call.

## One datagram per call

sd_notify(3) is one `sendto` on an `AF_UNIX` datagram socket named by `$NOTIFY_SOCKET`. Each call
opens a socket (`SOCK_CLOEXEC`), builds a 110-byte `sockaddr_un` in a `List`, sends with
`MSG_NOSIGNAL`, and closes. Keeping the socket open would save one `socket`/`close` pair per call;
a watchdog ping every few seconds makes that irrelevant, and a socket that is never open cannot
leak into a child process.

## Addresses

A path address includes its NUL in the length; an abstract address (`@name`) replaces `@` with
a NUL and excludes the trailing NUL. Getting this wrong is silent on one side, so the gate
receives on both kinds and compares every byte with a Python sender.

## Outside systemd

`$NOTIFY_SOCKET` unset returns `False` instead of raising, so a service runs unchanged from a shell.
A set but malformed value (not `/` or `@`, or longer than 107 bytes) raises: that is a
misconfiguration, not an absent manager.

## Watchdog

`watchdog_usec()` reads `$WATCHDOG_USEC` and honours `$WATCHDOG_PID` (systemd sets it so a forked
child does not ping on the parent's behalf). The gate proves the effect, not only the bytes: a
real user unit with `WatchdogSec=1` survives while pinging and fails with `Result=watchdog` when
it stops.
