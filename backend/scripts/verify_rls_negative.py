"""RLS negative test: unauthenticated + anon-keyed writes must be denied.

Read-only except for INSERT attempts that RLS must reject (nothing is
written on success of the test — rejection IS the pass). Prints verdicts
only, never keys.
"""

import pathlib

import httpx

from push_migrations import redact

ROOT = pathlib.Path(__file__).resolve().parents[2]


def load_public() -> tuple[str, str]:
    url = key = ""
    for line in (ROOT / "credentials.txt").read_text().splitlines():
        line = line.strip()
        if line.startswith("https://") and "supabase.co" in line:
            url = line
        elif line.startswith("sb_publishable_"):
            key = line
    if not url or not key:
        raise SystemExit("public config missing")
    return url, key


def main() -> int:
    url, key = load_public()
    headers = {"apikey": key, "Content-Type": "application/json"}
    ok = True

    # 1. Reference read as anon must leak NOTHING (RLS filters to []).
    r = httpx.get(f"{url}/rest/v1/states?select=name&limit=1", headers=headers, timeout=20)
    body = r.json()
    print(f"ANON states read: HTTP {r.status_code}, rows={len(body) if isinstance(body, list) else '?'} (expect [])")
    if not isinstance(body, list) or body:
        print("FAIL: anon saw reference rows")
        ok = False

    # 2. Private insert must be DENIED.
    r = httpx.post(
        f"{url}/rest/v1/profiles",
        headers={**headers, "Prefer": "return=representation"},
        json={"id": "00000000-0000-0000-0000-000000000000", "full_name": "x"},
        timeout=20,
    )
    print(f"ANON profiles insert: HTTP {r.status_code} (expect 401)")
    if r.status_code != 401:
        print("FAIL: anon insert was not rejected")
        ok = False

    # 3. Private read as anon must leak NOTHING.
    r = httpx.get(f"{url}/rest/v1/fields?select=id&limit=1", headers=headers, timeout=20)
    body = r.json()
    print(f"ANON fields read: HTTP {r.status_code}, rows={len(body) if isinstance(body, list) else '?'} (expect [])")
    if not isinstance(body, list) or body:
        print("FAIL: anon saw private rows")
        ok = False

    print("RLS NEGATIVE: " + ("PASS" if ok else "REVIEW"))
    return 0 if ok else 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as e:
        print(f"ERROR: {redact(str(e))}")
        raise SystemExit(1)
