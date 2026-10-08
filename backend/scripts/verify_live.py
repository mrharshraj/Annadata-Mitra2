"""Read-only live verification: policy breakdown per table + storage."""

import sys

sys.path.insert(0, "backend/scripts")

from push_migrations import connect_db, load_conninfo, redact

try:
    conn = connect_db(load_conninfo())
except Exception as e:
    print(f"CONNECT FAILED: {redact(str(e))}")
    sys.exit(1)

cur = conn.cursor()
cur.execute(
    "select tablename, count(*) from pg_policies "
    "where schemaname = 'public' group by 1 order by 1"
)
for table, count in cur.fetchall():
    print(f"TABLE {table}: {count} policies")
cur.execute(
    "select policyname from pg_policies "
    "where schemaname = 'storage' order by 1"
)
for (name,) in cur.fetchall():
    print(f"STORAGE POLICY: {name}")
conn.close()
print("DONE")
