"""Interactively configure the local PostgreSQL WRDS service."""

import getpass
import os
from pathlib import Path
import re
import sys
import tempfile


def main():
    if not sys.stdin.isatty():
        raise SystemExit("Run python3 scripts/configure_wrds.py in an interactive terminal.")
    username = input("WRDS username: ").strip()
    password = getpass.getpass("WRDS password: ")
    if not username or not password or any(c in username + password for c in "\r\n\x00"):
        raise SystemExit("Username and password must be nonempty single-line values.")

    path = Path.home() / ".pg_service.conf"
    # Avoid following a link to a different file when updating credentials.
    if path.is_symlink():
        raise SystemExit("Refusing to replace a symlink at ~/.pg_service.conf.")
    if path.exists():
        path.chmod(0o600)
        existing = path.read_text()
    else:
        existing = ""
    section = (
        "[wrds]\n"
        "host=wrds-pgdata.wharton.upenn.edu\n"
        "port=9737\n"
        "dbname=wrds\n"
        "sslmode=verify-full\n"
        "sslrootcert=system\n"
        f"user={username}\n"
        f"password={password}\n"
    )
    pattern = re.compile(r"^\[wrds\][ \t]*\r?\n.*?(?=^\[|\Z)", re.MULTILINE | re.DOTALL)
    if pattern.search(existing):
        updated = pattern.sub(lambda match: section + "\n", existing)
    else:
        updated = existing.rstrip("\n") + ("\n\n" if existing else "") + section

    # mkstemp creates a private file; replace atomically after writing succeeds.
    descriptor, temporary = tempfile.mkstemp(prefix=".pg_service.", dir=path.parent)
    try:
        with os.fdopen(descriptor, "w") as stream:
            os.fchmod(stream.fileno(), 0o600)
            stream.write(updated)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)
    print("Saved WRDS service to ~/.pg_service.conf (mode 600).")


if __name__ == "__main__":
    main()
