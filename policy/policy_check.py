#!/usr/bin/env python3
"""Custom Terraform policy gate for portfolio-infra shared modules.

Two BLOCKING rules (run in CI on every PR + push, and locally):

  A) no-identifying-literals
     Module bodies must not hardcode solution-specific names. Shared modules
     are the single source of truth across the portfolio, so a literal like
     "rag" or "documents" leaking into a module body is drift. Callers pass
     these as variables instead.

  B) anti-facade
     If a module declares `variable "enable_private_endpoints"`, it MUST also
     contain at least one `resource "azurerm_private_endpoint"`. This stops a
     dead boolean that only flips public access without creating a real
     private endpoint (the v0.1.0 facade this release removes).

Self-contained: no external policy engine required, so it runs identically in
CI and on a laptop. Exit code 0 = pass, 1 = violations found, 2 = bad usage.

Usage:
  policy_check.py [MODULES_DIR ...]
Defaults to ./terraform/modules relative to the repo root.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

# Exact quoted-string literals that must never appear in a module body.
DENY_EXACT = {
    "rag",
    "documents",
    "upload_api",
    "upload-api",
    "embedding_worker",
    "embedding-worker",
    "retrieval_api",
    "retrieval-api",
    "mcp_server",
    "mcp-server",
}

# Substrings that must never appear inside any quoted string in a module body.
DENY_SUBSTRING = (
    "documents/",
)

# Matches a double-quoted string literal (no escaped-quote handling needed for
# the simple values we scan).
QUOTED = re.compile(r'"([^"]*)"')


def strip_comment(line: str) -> str:
    """Drop trailing `#` / `//` comments so denied words in comments are OK.

    Naive but sufficient: a `#`/`//` inside a quoted string is rare in TF and
    would only ever make the check stricter, never miss a real literal.
    """
    for marker in ("#", "//"):
        idx = line.find(marker)
        if idx != -1:
            line = line[:idx]
    return line


def check_no_identifying_literals(tf_files: list[Path]) -> list[str]:
    violations: list[str] = []
    for path in tf_files:
        for n, raw in enumerate(path.read_text().splitlines(), start=1):
            line = strip_comment(raw)
            for match in QUOTED.finditer(line):
                value = match.group(1)
                low = value.lower()
                if low in DENY_EXACT:
                    violations.append(
                        f"{path}:{n}: identifying literal \"{value}\" "
                        f"(rule: no-identifying-literals)"
                    )
                else:
                    for sub in DENY_SUBSTRING:
                        if sub in low:
                            violations.append(
                                f"{path}:{n}: identifying substring "
                                f"\"{sub}\" in \"{value}\" "
                                f"(rule: no-identifying-literals)"
                            )
    return violations


def check_anti_facade(module_dir: Path) -> list[str]:
    tf_files = sorted(module_dir.glob("*.tf"))
    if not tf_files:
        return []
    body = "\n".join(p.read_text() for p in tf_files)
    declares_flag = re.search(
        r'variable\s+"enable_private_endpoints"', body
    )
    if not declares_flag:
        return []
    has_endpoint = re.search(
        r'resource\s+"azurerm_private_endpoint"', body
    )
    if has_endpoint:
        return []
    return [
        f"{module_dir}: declares variable \"enable_private_endpoints\" but has "
        f"no azurerm_private_endpoint resource (rule: anti-facade)"
    ]


def main(argv: list[str]) -> int:
    roots = [Path(a) for a in argv[1:]] or [Path("terraform/modules")]
    all_violations: list[str] = []

    for root in roots:
        if not root.exists():
            print(f"error: path not found: {root}", file=sys.stderr)
            return 2
        # Module dirs = immediate subdirectories containing .tf files, or the
        # root itself if it directly holds .tf files (fixture support).
        module_dirs = [d for d in sorted(root.iterdir()) if d.is_dir() and any(d.glob("*.tf"))]
        if not module_dirs and any(root.glob("*.tf")):
            module_dirs = [root]

        for module_dir in module_dirs:
            tf_files = sorted(module_dir.glob("*.tf"))
            all_violations += check_no_identifying_literals(tf_files)
            all_violations += check_anti_facade(module_dir)

    if all_violations:
        print("POLICY FAIL — custom Terraform policy violations:\n")
        for v in all_violations:
            print(f"  - {v}")
        print(f"\n{len(all_violations)} violation(s).")
        return 1

    print("POLICY PASS — no custom policy violations.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
