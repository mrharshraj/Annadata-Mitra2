"""Apply Supabase migrations + seed to the live project, then verify.

Reads the connection string from the git-ignored project-root
credentials.txt (line starting with postgresql://). Secrets never appear
in output: errors are redacted before printing. Non-destructive: each
file runs in its own transaction; on failure we roll back that file and
stop. Never drops or resets anything.

Usage: backend/.venv/Scripts/python backend/scripts/push_migrations.py
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
FILES = [
    ROOT / "supabase" / "migrations" / "0001_schema.sql",
    ROOT / "supabase" / "migrations" / "0002_rls.sql",
    ROOT / "supabase" / "migrations" / "0003_storage.sql",
    ROOT / "supabase" / "seed.sql",
]

EXPECTED_TABLES = [
    "states", "districts", "blocks", "panchayats", "villages",
    "profiles", "fields", "crops", "field_crops", "tasks",
    "weather_advisories", "crop_advice", "ai_conversations",
    "ai_messages", "crop_scans",
]


def redact(text: str) -> str:
    text = re.sub(r"postgresql://\S+", "postgresql://<redacted>", text)
    text = re.sub(r"sb_[A-Za-z0-9_\-]{10,}", "sb_<redacted>", text)
    text = re.sub(r"eyJ[A-Za-z0-9_\-\.]{10,}", "eyj_<redacted>", text)
    return text


def connect_db(conninfo: str):
    """Connect preferring IPv6 (this network's IPv4 path to Supabase
    times out while IPv6 succeeds). Falls back to default resolution."""
    import socket
    import psycopg

    from urllib.parse import urlsplit

    host = urlsplit(conninfo.replace("postgresql://", "postgres://")).hostname
    try:
        infos = socket.getaddrinfo(host, 5432, socket.AF_INET6, socket.SOCK_STREAM)
        hostaddr = infos[0][4][0]
    except OSError:
        hostaddr = None
    kwargs = {"connect_timeout": 30, "sslmode": "require"}
    if hostaddr:
        kwargs["hostaddr"] = hostaddr
    return psycopg.connect(conninfo, **kwargs)


def load_conninfo() -> str:
    from urllib.parse import quote

    for line in (ROOT / "credentials.txt").read_text().splitlines():
        line = line.strip()
        if not line.startswith("postgresql://"):
            continue
        rest = line[len("postgresql://"):]
        # Split userinfo from host at "@db." but KEEP the "db." hostname part
        # (it is the real database host; passwords may contain '@').
        userpass, sep, hostpart = rest.partition("@db.")
        if sep:
            hostpart = "db." + hostpart
        else:
            # Fallback: split on last '@' (passwords may contain '@').
            userpass, _, hostpart = rest.rpartition("@")
        user, _, password = userpass.partition(":")
        return (
            f"postgresql://{user}:{quote(password, safe='')}"
            f"@{hostpart}"
        )
    raise SystemExit("ERROR: no postgresql:// connection string found.")


def apply(cur, path: pathlib.Path) -> None:
    sql = path.read_text(encoding="utf-8")
    cur.execute(sql)


def main() -> int:
    import psycopg

    conninfo = load_conninfo()
    try:
        conn = connect_db(conninfo)
    except Exception as e:
        print(f"CONNECT FAILED: {redact(str(e))}")
        return 1

    with conn:
        with conn.cursor() as cur:
            for path in FILES:
                try:
                    apply(cur, path)
                    conn.commit()
                    print(f"APPLIED: {path.name}")
                except Exception as e:
                    conn.rollback()
                    print(f"FAILED: {path.name}: {redact(str(e))}")
                    return 2

            checks: list[tuple[str, str, object]] = [
                ("tables_present", """
                    select count(*) from information_schema.tables
                    where table_schema='public'
                    and table_name = any(%s)
                """, EXPECTED_TABLES),
                ("rls_enabled", """
                    select count(*) from pg_tables
                    where schemaname='public' and rowsecurity
                    and tablename = any(%s)
                """, EXPECTED_TABLES),
                ("policies_total", """
                    select count(*) from pg_policies
                    where schemaname in ('public', 'storage')
                """, None),
                ("bucket_private", """
                    select public from storage.buckets where id='crop-scans'
                """, None),
                ("seed_states", "select count(*) from public.states", None),
                ("seed_districts_br", """
                    select count(*) from public.districts d
                    join public.states s on s.id = d.state_id
                    where s.code='BR'
                """, None),
                ("seed_crops", "select count(*) from public.crops", None),
                ("seed_villages", "select count(*) from public.villages", None),
            ]
            ok = True
            for name, query, param in checks:
                try:
                    cur.execute(query, (param,) if param is not None else None)
                    print(f"CHECK {name}: {cur.fetchone()[0]}")
                except Exception as e:
                    ok = False
                    print(f"CHECK {name} FAILED: {redact(str(e))}")
            conn.commit()
    print("VERIFY: " + ("PASS" if ok else "REVIEW"))
    return 0 if ok else 3


if __name__ == "__main__":
    sys.exit(main())
