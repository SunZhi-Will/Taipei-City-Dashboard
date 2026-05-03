#!/usr/bin/env python3
"""
黑客松功能整合 - CSV 資料匯入腳本
將 my-data/ 下的 CSV 透過 docker exec psql COPY 匯入 dashboard DB
用法: python3 02_import_csv_data.py [--dry-run]
"""

import subprocess
import csv
import sys
import io
from pathlib import Path

DRY_RUN = "--dry-run" in sys.argv

DATA_DIR = Path(__file__).parent.parent
CONTAINER = "postgres-data"
DB = "dashboard"
DB_USER = "postgres"

def psql(sql: str, description: str):
    """執行 SQL 到 postgres-data 容器"""
    print(f"  → {description}")
    if DRY_RUN:
        print(f"    [DRY-RUN] {sql[:100]}...")
        return True
    cmd = ["wsl", "docker", "exec", "-i", CONTAINER,
           "psql", "-U", DB_USER, "-d", DB, "-c", sql]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"    ✗ ERROR: {result.stderr.strip()}")
        return False
    print(f"    ✓ OK: {result.stdout.strip()}")
    return True

def copy_csv(table: str, csv_path: Path, columns: list[str], description: str,
             transform=None):
    """透過 COPY FROM STDIN 匯入 CSV (跳過 header)"""
    if not csv_path.exists():
        print(f"  ✗ 找不到 {csv_path}")
        return False
    print(f"  → {description}: {csv_path.name}")
    if DRY_RUN:
        with open(csv_path, encoding="utf-8") as f:
            rows = sum(1 for _ in f) - 1
        print(f"    [DRY-RUN] 會插入 {rows} 筆")
        return True

    # 讀 CSV，跳過 header，做必要轉換
    rows = []
    with open(csv_path, encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        for row in reader:
            if transform:
                row = transform(row)
            rows.append(row)

    # 清空再插入 (冪等操作)
    psql(f"TRUNCATE TABLE public.{table};", f"清空 {table}")

    # 透過 COPY 匯入
    col_str = ", ".join(columns)
    copy_sql = f"COPY public.{table} ({col_str}) FROM STDIN WITH CSV"
    stdin_data = io.StringIO()
    writer = csv.writer(stdin_data)
    for row in rows:
        writer.writerow([row.get(c, "") for c in columns])
    stdin_data.seek(0)

    cmd = ["wsl", "docker", "exec", "-i", CONTAINER,
           "psql", "-U", DB_USER, "-d", DB, "-c", copy_sql]
    result = subprocess.run(cmd, input=stdin_data.read(),
                            capture_output=True, text=True, encoding="utf-8")
    if result.returncode != 0:
        print(f"    ✗ COPY ERROR: {result.stderr.strip()}")
        return False
    print(f"    ✓ 匯入 {len(rows)} 筆")
    return True

def main():
    print("=" * 60)
    print("  黑客松功能 CSV 資料匯入")
    print("=" * 60)
    if DRY_RUN:
        print("  [DRY-RUN 模式 - 不實際執行]\n")

    # 1. AED 台北市
    aed_tpe = DATA_DIR / "AED" / "aed_tpe.csv"
    copy_csv(
        table="aed_tpe",
        csv_path=aed_tpe,
        columns=["name", "address", "district", "latitude", "longitude",
                 "category", "type", "location_desc"],
        description="AED 台北市"
    )

    # 2. 原住民族人口 - 行政區別
    ind_dist = DATA_DIR / "原住民族人口" / "by_district_TPE_combined.csv"
    copy_csv(
        table="indigenous_by_district_tpe",
        csv_path=ind_dist,
        columns=["year", "month", "district", "gender", "total",
                 "population_plains", "population_mountains"],
        description="原住民族人口-行政區別(台北)"
    )

    # 3. 原住民族人口 - 族別
    ind_grp = DATA_DIR / "原住民族人口" / "by_group_TPE_combined.csv"
    copy_csv(
        table="indigenous_by_group_tpe",
        csv_path=ind_grp,
        columns=["year", "month", "gender", "total",
                 "population_amis", "population_atayal", "population_paiwan",
                 "population_bunun", "population_rukai", "population_pinan",
                 "population_tsou", "population_saisiyat", "population_yami",
                 "population_thao", "population_kavalan", "population_truku",
                 "population_sakizaya", "population_seediq",
                 "population_laaruwa", "population_kanakanavu", "unreported"],
        description="原住民族人口-族別(台北)"
    )

    # 4. 受聘僱移工 台北市
    mig_tpe = DATA_DIR / "移工" / "migrant_workers_employed_tpe.csv"
    copy_csv(
        table="migrant_workers_employed_tpe",
        csv_path=mig_tpe,
        columns=["year", "month", "nationality", "job_type", "count"],
        description="受聘僱移工(台北市)"
    )

    # 5. 受聘僱移工 新北市
    mig_ntpc = DATA_DIR / "移工" / "migrant_workers_employed_ntpc.csv"
    copy_csv(
        table="migrant_workers_employed_ntpc",
        csv_path=mig_ntpc,
        columns=["year", "month", "nationality", "job_type", "count"],
        description="受聘僱移工(新北市)"
    )

    # 6. 長照ABC據點 台北市
    ltc_csv = DATA_DIR / "長照" / "長照ABC據點_臺北市_處理後.csv"
    def ltc_transform(row):
        return {
            "name":      row.get("機構名稱", ""),
            "code":      row.get("機構代碼", ""),
            "type":      row.get("機構種類", ""),
            "city":      row.get("縣市", ""),
            "district":  row.get("區", ""),
            "address":   row.get("地址全址", ""),
            "longitude": row.get("經度", ""),
            "latitude":  row.get("緯度", ""),
            "o_abc":     row.get("O_ABC", ""),
            "services":  row.get("特約服務項目", ""),
        }
    copy_csv(
        table="long_term_care_abc_tpe",
        csv_path=ltc_csv,
        columns=["name", "code", "type", "city", "district", "address",
                 "longitude", "latitude", "o_abc", "services"],
        description="長照ABC據點(台北市)",
        transform=ltc_transform
    )

    print("\n✅ 所有 CSV 匯入完成")

if __name__ == "__main__":
    main()
