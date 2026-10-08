"""One-shot APK string audit. Prints contexts around sensitive markers,
masking any key-like runs. Local-only, never committed."""

import pathlib
import re
import sys

KB = (
    pathlib.Path("C:/Users/Broken Crown/AppData/Local/Temp/opencode")
    / "apkcheck" / "app" / "assets" / "flutter_assets" / "kernel_blob.bin"
)

text = KB.read_bytes().decode("utf-8", errors="ignore")


def mask(s: str) -> str:
    s = re.sub(r"AIza[A-Za-z0-9_\-]{10,}", "AIza<MASKED>", s)
    s = re.sub(r"eyJ[A-Za-z0-9_\-\.]{10,}", "eyj<MASKED>", s)
    s = re.sub(r"sb_[A-Za-z0-9_\-]{10,}", "sb_<MASKED>", s)
    return s


for pat in ("service_role", "AIza"):
    hits = list(re.finditer(pat, text))[:4]
    print(f"== {pat}: {len(hits)} shown ==")
    for m in hits:
        print(repr(mask(text[max(0, m.start() - 70):m.end() + 50]))[:260])
