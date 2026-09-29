"""Build the Online Retail SQLite database from the public UCI dataset.

Downloads https://archive.ics.uci.edu/static/public/352/online+retail.zip
(~24 MB), streams Online Retail.xlsx into a raw_sales table, then runs
sql/01_build_clean.sql to produce clean_sales + product_category.

Usage:  python scripts/build_database.py [--db PATH]
Requires: openpyxl  (pip install openpyxl)
"""
import argparse
import os
import sqlite3
import sys
import urllib.request
import zipfile

URL = "https://archive.ics.uci.edu/static/public/352/online+retail.zip"
HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--db", default=os.path.join(HERE, "online_retail.db"))
    args = ap.parse_args()

    workdir = os.path.join(HERE, ".build")
    os.makedirs(workdir, exist_ok=True)
    zippath = os.path.join(workdir, "online_retail.zip")
    xlsxpath = os.path.join(workdir, "Online Retail.xlsx")

    if not os.path.exists(xlsxpath):
        print("downloading dataset ...")
        urllib.request.urlretrieve(URL, zippath)
        with zipfile.ZipFile(zippath) as z:
            z.extractall(workdir)
    print("loading workbook ...")
    from openpyxl import load_workbook
    wb = load_workbook(xlsxpath, read_only=True)
    ws = wb.active
    rows = ws.rows
    next(rows)  # header

    if os.path.exists(args.db):
        os.remove(args.db)
    con = sqlite3.connect(args.db)
    cur = con.cursor()
    cur.execute("""CREATE TABLE raw_sales (
        InvoiceNo TEXT, StockCode TEXT, Description TEXT, Quantity INTEGER,
        InvoiceDate TEXT, UnitPrice REAL, CustomerID TEXT, Country TEXT)""")

    batch, n = [], 0
    for r in rows:
        v = [c.value for c in r]
        cid = v[6]
        if cid is not None:
            cid = str(int(cid)) if float(cid).is_integer() else str(cid)
        batch.append((
            str(v[0]) if v[0] is not None else None,
            str(v[1]) if v[1] is not None else None,
            str(v[2]).strip() if v[2] else None,
            int(v[3]) if v[3] is not None else None,
            str(v[4]),
            float(v[5]) if v[5] is not None else None,
            cid,
            str(v[7]).strip() if v[7] else None,
        ))
        n += 1
        if len(batch) >= 20000:
            cur.executemany("INSERT INTO raw_sales VALUES (?,?,?,?,?,?,?,?)", batch)
            batch = []
    cur.executemany("INSERT INTO raw_sales VALUES (?,?,?,?,?,?,?,?)", batch)
    con.commit()
    print(f"loaded {n} rows into raw_sales")

    with open(os.path.join(HERE, "sql", "01_build_clean.sql")) as f:
        cur.executescript(f.read())
    con.commit()
    checks = cur.execute(
        "SELECT line_type, COUNT(*) FROM clean_sales GROUP BY line_type"
    ).fetchall()
    print("line types:", dict(checks))
    rev = cur.execute(
        "SELECT ROUND(SUM(Revenue),2) FROM clean_sales WHERE line_type='sale'"
    ).fetchone()[0]
    print(f"sales revenue: GBP {rev:,.2f}")
    con.close()
    print("done ->", args.db)


if __name__ == "__main__":
    sys.exit(main())
