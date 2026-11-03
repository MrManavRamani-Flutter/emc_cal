#!/usr/bin/env python3
"""
OM MAVTAR GROUP — Live Hot-Reload Desktop Runner
Watches 'lib/' directory for code changes and automatically triggers Flutter Hot Reload ('r').
Also allows manual interactive commands in the Terminal ('r' = reload, 'R' = restart, 'q' = quit).
"""

import os
import sys
import time
import select
import termios
import tty
import pty
import subprocess
import threading
import shutil

PROJECT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
WATCH_DIR = os.path.join(PROJECT_DIR, "lib")

def find_flutter():
    # Check common locations
    candidates = [
        shutil.which("flutter"),
        os.path.expanduser("~/flutter/bin/flutter"),
        "/opt/homebrew/bin/flutter",
        "/usr/local/bin/flutter",
    ]
    for c in candidates:
        if c and os.path.exists(c) and os.access(c, os.X_OK):
            return c
    return "flutter"

def get_dir_mtimes(directory):
    mtimes = {}
    if not os.path.exists(directory):
        return mtimes
    for root, _, files in os.walk(directory):
        for f in files:
            if f.endswith(".dart"):
                p = os.path.join(root, f)
                try:
                    mtimes[p] = os.path.getmtime(p)
                except OSError:
                    pass
    return mtimes

def main():
    os.chdir(PROJECT_DIR)
    flutter_bin = find_flutter()

    print("=" * 65)
    print(" 🪡  OM MAVTAR GROUP — Desktop Live Development Launcher")
    print("=" * 65)
    print(f"📁 Project: {PROJECT_DIR}")
    print(f"🚀 Flutter: {flutter_bin}")
    print(f"👀 Watching: {WATCH_DIR} for live changes")
    print("-" * 65)
    print("⚡ Auto-Reload: Any file saved in 'lib/' triggers instant hot-reload!")
    print("⌨️  Manual Keys:")
    print("    r : Hot reload (refresh UI in < 1 second)")
    print("    R : Hot restart (reset app state)")
    print("    q : Quit application")
    print("=" * 65)
    print("Starting Desktop App...\n")

    master_fd, slave_fd = pty.openpty()

    env = os.environ.copy()
    flutter_dir = os.path.dirname(flutter_bin)
    if flutter_dir not in env.get("PATH", ""):
        env["PATH"] = f"{flutter_dir}:{env.get('PATH', '')}"

    proc = subprocess.Popen(
        [flutter_bin, "run", "-d", "macos"],
        stdin=slave_fd,
        stdout=slave_fd,
        stderr=slave_fd,
        close_fds=True,
        env=env,
        cwd=PROJECT_DIR,
    )
    os.close(slave_fd)

    stop_event = threading.Event()
    ready_for_reload = threading.Event()

    # Thread to watch lib directory
    def watcher():
        last_mtimes = get_dir_mtimes(WATCH_DIR)
        while not stop_event.is_set():
            time.sleep(0.5)
            if not ready_for_reload.is_set():
                continue
            current_mtimes = get_dir_mtimes(WATCH_DIR)
            changed = False
            for p, mt in current_mtimes.items():
                if p not in last_mtimes or mt > last_mtimes[p]:
                    changed = True
                    break
            if not changed and len(current_mtimes) != len(last_mtimes):
                changed = True

            if changed:
                last_mtimes = current_mtimes
                # Debounce additional saves
                time.sleep(0.3)
                last_mtimes = get_dir_mtimes(WATCH_DIR)
                try:
                    os.write(master_fd, b'r')
                    sys.stdout.write("\n\r⚡ [LIVE AUTO-RELOAD] Detected code change — hot reload triggered!\n\r")
                    sys.stdout.flush()
                except OSError:
                    break

    watcher_thread = threading.Thread(target=watcher, daemon=True)
    watcher_thread.start()

    # Save original terminal settings if running on a real tty
    is_atty = sys.stdin.isatty()
    old_termios = None
    if is_atty:
        old_termios = termios.tcgetattr(sys.stdin)
        tty.setcbreak(sys.stdin.fileno())

    try:
        while True:
            rlist = [master_fd]
            if is_atty:
                rlist.append(sys.stdin.fileno())

            readable, _, _ = select.select(rlist, [], [], 0.1)

            if proc.poll() is not None:
                break

            for fd in readable:
                if fd == master_fd:
                    try:
                        data = os.read(master_fd, 1024)
                    except OSError:
                        data = b""
                    if not data:
                        break
                    sys.stdout.buffer.write(data)
                    sys.stdout.buffer.flush()
                    # Check if Flutter app has finished launching
                    if b"Flutter run key commands" in data or b"To hot reload" in data or b"hot reload" in data:
                        ready_for_reload.set()

                elif is_atty and fd == sys.stdin.fileno():
                    user_char = sys.stdin.read(1)
                    if user_char:
                        os.write(master_fd, user_char.encode("utf-8"))
                        if user_char == 'q':
                            # Give flutter time to quit
                            time.sleep(0.5)

    except KeyboardInterrupt:
        pass
    finally:
        stop_event.set()
        if is_atty and old_termios:
            termios.tcsetattr(sys.stdin, termios.TCSADRAIN, old_termios)
        try:
            os.close(master_fd)
        except OSError:
            pass
        if proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(timeout=3)
            except subprocess.TimeoutExpired:
                proc.kill()
        print("\n\nApplication closed.")

if __name__ == "__main__":
    main()
