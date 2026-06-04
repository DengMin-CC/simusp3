#!/usr/bin/env python3
"""run_simusp3.py - Automated SP3 orbit/clock error simulation pipeline

Usage:
    python run_simusp3.py <year> <doy_start> [doy_end] [--force]
    python run_simusp3.py 2025 314 315       # DOY 314-315
    python run_simusp3.py 2025 314           # single day
    python run_simusp3.py 2025 314 315 --force  # overwrite existing

Pipeline per day:
    1. Find input file in csp3 output directory
    2. Check if output already exists (skip if present, unless --force)
    3. Call MATLAB batch_simusp3 with input/output paths
    4. Archive to gnssdata/data/projects/simusp3/
"""

import os
import sys
import subprocess
import time
from datetime import datetime, timedelta

# ===== Path Constants =====
SIMUSP3_DIR = os.path.dirname(os.path.abspath(__file__))
GNSSDATA = r"F:\LeoSingle\gnssdata\data"

CSP3_OUTPUT = os.path.join(GNSSDATA, "projects", "csp3", "output")
OBS_SIMU_SP3 = os.path.join(GNSSDATA, "projects", "obs_simu", "simu_sp3")
SIMUSP3_OUT = os.path.join(GNSSDATA, "projects", "simusp3")

MATLAB = r"D:\matlab\bin\matlab.exe"
BATCH_M = os.path.join(SIMUSP3_DIR, "batch_simusp3.m")

INPUT_DIRS = [CSP3_OUTPUT, OBS_SIMU_SP3]


def doy_to_gps_week(year, doy):
    """Convert year+DOY to GPS week number and weekday (Sun=0)."""
    dt = datetime(year, 1, 1) + timedelta(days=doy - 1)
    mjd = 51544 + (dt - datetime(2000, 1, 1)).days
    gps_week = (mjd - 44244) // 7
    weekday = (mjd - 44244) % 7
    return gps_week, weekday


def find_input_file(year, doy):
    """Find input SP3 file from csp3 output directories.

    Tries new format (whu{week}{weekday}_obs_simu.sp3) first,
    then legacy format (whu{week}{doy}_new.sp3) in project root.
    """
    week, weekday = doy_to_gps_week(year, doy)

    # New format: whu{week}{weekday}_obs_simu.sp3
    new_name = f"whu{week}{weekday}_obs_simu.sp3"
    for d in INPUT_DIRS:
        path = os.path.join(d, new_name)
        if os.path.exists(path):
            return path

    # Legacy format: whu{week}{doy}_new.sp3
    legacy_name = f"whu{week}{doy:03d}_new.sp3"
    for d in INPUT_DIRS:
        path = os.path.join(d, legacy_name)
        if os.path.exists(path):
            return path

    # Legacy in project root
    path = os.path.join(SIMUSP3_DIR, legacy_name)
    if os.path.exists(path):
        return path

    return None


def output_filename(week, weekday):
    """Generate output filename: Cwhu{week}{weekday}_obs_simu.sp3"""
    return f"Cwhu{week}{weekday}_obs_simu.sp3"


def run_matlab(input_path, output_path):
    """Call MATLAB batch_simusp3 with input/output file paths."""
    print("  Running MATLAB (~45s per file)...")
    t0 = time.time()
    cmd = [
        MATLAB, "-batch",
        f"batch_simusp3('{input_path.replace(chr(92), '/')}', '{output_path.replace(chr(92), '/')}')"
    ]
    r = subprocess.run(cmd, capture_output=True, text=True,
                       cwd=SIMUSP3_DIR, timeout=600)
    elapsed = time.time() - t0
    if r.returncode != 0:
        stderr_tail = r.stderr.strip().split("\n")[-5:] if r.stderr else []
        print(f"  MATLAB FAILED ({elapsed:.0f}s): {'; '.join(stderr_tail)}")
        return False
    print(f"  MATLAB done ({elapsed:.0f}s)")
    return True


def main():
    argv = sys.argv[1:]
    force = "--force" in argv
    argv = [a for a in argv if a != "--force"]

    if len(argv) < 2:
        print(__doc__)
        sys.exit(1)

    year = int(argv[0])
    doy_start = int(argv[1])
    doy_end = int(argv[2]) if len(argv) > 2 else doy_start

    print(f"{'=' * 60}")
    print(f"  SP3 Error Simulation: {year} DOY {doy_start}"
          + (f"-{doy_end}" if doy_end != doy_start else ""))
    print(f"{'=' * 60}\n")

    # Pre-flight checks
    if not os.path.exists(MATLAB):
        print(f"ERROR: MATLAB not found at {MATLAB}")
        sys.exit(1)
    if not os.path.exists(BATCH_M):
        print(f"ERROR: batch_simusp3.m not found at {BATCH_M}")
        sys.exit(1)

    os.makedirs(SIMUSP3_OUT, exist_ok=True)

    results = []
    t_total = time.time()

    for doy in range(doy_start, doy_end + 1):
        dt = datetime(year, 1, 1) + timedelta(days=doy - 1)
        week, weekday = doy_to_gps_week(year, doy)
        out_name = output_filename(week, weekday)
        out_path = os.path.join(SIMUSP3_OUT, out_name)

        print(f"--- DOY {doy:03d} ({dt.strftime('%Y-%m-%d')}, "
              f"week {week}, wd {weekday}) ---")

        # Skip if exists
        if os.path.exists(out_path) and not force:
            size_mb = os.path.getsize(out_path) / 1e6
            print(f"  Already exists: {out_name} ({size_mb:.1f} MB) [skipped]")
            results.append(("skip", doy))
            continue

        # Find input
        in_path = find_input_file(year, doy)
        if in_path is None:
            print(f"  WARNING: No input file found for DOY {doy:03d}")
            results.append(("missing", doy))
            continue

        size_mb = os.path.getsize(in_path) / 1e6
        print(f"  Input:  {os.path.basename(in_path)} ({size_mb:.1f} MB)")
        print(f"  Output: {out_name}")

        # Run MATLAB
        if not run_matlab(in_path, out_path):
            results.append(("fail", doy))
            continue

        # Verify output
        if os.path.exists(out_path):
            size_mb = os.path.getsize(out_path) / 1e6
            print(f"  >>> Done: {out_name} ({size_mb:.1f} MB)")
            results.append(("ok", doy))
        else:
            print(f"  ERROR: Output not generated")
            results.append(("fail", doy))

    # Summary
    elapsed = time.time() - t_total
    print(f"\n{'=' * 60}")
    ok = sum(1 for s, _ in results if s == "ok")
    skip = sum(1 for s, _ in results if s == "skip")
    miss = sum(1 for s, _ in results if s == "missing")
    fail = sum(1 for s, _ in results if s == "fail")
    print(f"  Done in {elapsed:.0f}s: {ok} generated, {skip} skipped, "
          f"{miss} missing input, {fail} failed")
    if miss:
        for s, d in results:
            if s == "missing":
                print(f"  MISSING INPUT: DOY {d:03d}")
    if fail:
        for s, d in results:
            if s == "fail":
                print(f"  FAILED: DOY {d:03d}")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()
