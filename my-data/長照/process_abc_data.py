#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pandas as pd
from pathlib import Path
from typing import Dict, Any, Optional
import json

def process_single_file(input_file: Path, output_file: Path) -> bool:
    """
    處理單一長照ABC據點CSV檔案，保留指定欄位
    
    Args:
        input_file: 輸入的CSV檔案路徑
        output_file: 輸出的CSV檔案路徑
        
    Returns:
        bool: 處理是否成功
    """
    # 定義要保留的欄位
    target_columns = [
        "機構名稱", "機構代碼", "機構種類", "縣市", "區", 
        "地址全址", "經度", "緯度", "O_ABC", "特約服務項目"
    ]
    
    print(f"\n正在處理檔案: {input_file}")
    
    try:
        # 讀取CSV檔案
        df = pd.read_csv(input_file, encoding='utf-8')
        print(f"  成功讀取 {len(df)} 筆資料")
        
        # 檢查必要欄位是否存在
        missing_columns = [col for col in target_columns if col not in df.columns]
        if missing_columns:
            print(f"  錯誤: 缺少必要欄位: {', '.join(missing_columns)}")
            return False
            
        # 選取需要的欄位
        df = df[target_columns].copy()
        
        # 將特約服務項目轉換為列表（如果尚未轉換）
        if len(df) > 0 and isinstance(df.iloc[0]["特約服務項目"], str):
            df["特約服務項目"] = df["特約服務項目"].str.split(';').apply(
                lambda x: [item.strip() for item in x] if isinstance(x, list) else []
            )
        
        # 定義用於分組的欄位（排除特約服務項目）
        group_columns = [col for col in df.columns if col != "特約服務項目"]
        
        # 將特約服務項目轉換為集合以去除重複，然後再轉回列表
        df_merged = df.explode('特約服務項目')
        df_merged = df_merged.groupby(group_columns)['特約服務項目'] \
            .apply(lambda x: ';'.join(sorted(set(x), key=list(x).index))) \
            .reset_index()
        
        # 確保目錄存在
        output_file.parent.mkdir(parents=True, exist_ok=True)
        
        # 儲存為CSV
        df_merged.to_csv(output_file, index=False, encoding='utf-8-sig')
        
        print(f"處理完成！已儲存到 {output_file}")
        print(f"合併前筆數: {len(df)}, 合併後筆數: {len(df_merged)}")
        
        # 顯示前幾筆資料作為預覽
        print("\n處理後的資料預覽:")
        print(df_merged.head().to_string())
        
        return True
        
    except Exception as e:
        print(f"  處理檔案時發生錯誤: {e}")
        return False

def main():
    # 設定檔案路徑
    data_dir = Path("/Users/siniuho/Labs/Taipei-City-Dashboard/my-data/長照/")
    
    # 處理臺北市的檔案
    tpe_input = data_dir / "長照ABC據點_臺北市.csv"
    tpe_output = data_dir / "長照ABC據點_臺北市_處理後.csv"
    
    # 處理新北市的檔案
    ntp_input = data_dir / "長照ABC據點_新北市.csv"
    ntp_output = data_dir / "長照ABC據點_新北市_處理後.csv"
    
    # 處理臺北市檔案
    print("="*50)
    print("開始處理臺北市資料")
    print("="*50)
    process_single_file(tpe_input, tpe_output)
    
    # 處理新北市檔案
    print("\n" + "="*50)
    print("開始處理新北市資料")
    print("="*50)
    process_single_file(ntp_input, ntp_output)
    
    print("\n所有處理完成！")


if __name__ == "__main__":
    main()
