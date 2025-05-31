#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pandas as pd
from pathlib import Path

def filter_taipei_new_taipei(input_file, output_file):
    """
    篩選出臺北市或新北市的長照據點
    
    Args:
        input_file (str): 輸入的CSV檔案路徑
        output_file (str): 輸出的CSV檔案路徑
    """
    try:
        # 讀取CSV檔案
        print(f"正在讀取檔案: {input_file}")
        df = pd.read_csv(input_file)
        
        # 篩選出臺北市或新北市的資料
        print("正在篩選臺北市和新北市的據點...")
        filtered_df = df[df['縣市'].isin(['臺北市', '新北市'])]
        
        # 儲存結果
        filtered_df.to_csv(output_file, index=False, encoding='utf-8-sig')
        print(f"篩選完成！已儲存至: {output_file}")
        print(f"總共篩選出 {len(filtered_df)} 筆資料")
        
        # 顯示各縣市的資料筆數
        print("\n各縣市資料筆數統計：")
        print(filtered_df['縣市'].value_counts())
        
        return filtered_df
        
    except Exception as e:
        print(f"處理過程中發生錯誤: {str(e)}")
        return None

def main():
    # 設定檔案路徑
    data_dir = Path("/Users/siniuho/Labs/Taipei-City-Dashboard/my-data/長照/")
    input_file = data_dir / "長照ABC據點_行政區轉換後_v2.csv"
    output_file = data_dir / "長照ABC據點_雙北地區.csv"
    
    # 執行篩選
    result_df = filter_taipei_new_taipei(input_file, output_file)
    
    if result_df is not None and not result_df.empty:
        # 顯示前幾筆資料
        print("\n篩選結果前5筆資料：")
        print(result_df[['機構名稱', '縣市', '區', '特約服務項目', '特約縣市']].head().to_string())
    else:
        print("沒有找到符合條件的資料或處理過程中發生錯誤。")

if __name__ == "__main__":
    main()