#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pandas as pd
import numpy as np
from pathlib import Path

def load_area_mapping(mapping_file):
    """
    載入縣市鄉鎮區代碼對照表
    
    Args:
        mapping_file (str): 代碼對照表CSV檔案路徑
        
    Returns:
        tuple: (area_code_map, city_code_map)
            - area_code_map: 鄉鎮區代碼到名稱的映射
            - city_code_map: 縣市代碼到名稱的映射
    """
    print(f"正在載入代碼對照表: {mapping_file}")
    try:
        # 讀取代碼對照表
        code_df = pd.read_csv(mapping_file, dtype=str)
        
        # 清理資料
        code_df = code_df.dropna(subset=['縣市代碼', '鄉鎮區代碼'])
        code_df['縣市代碼'] = code_df['縣市代碼'].astype(str).str.strip()
        code_df['鄉鎮區代碼'] = code_df['鄉鎮區代碼'].astype(str).str.strip()
        
        # 建立縣市代碼到名稱的映射（使用最後出現的對應關係）
        city_code_map = code_df.drop_duplicates('縣市代碼', keep='last').set_index('縣市代碼')['縣市'].to_dict()
        
        # 建立鄉鎮區代碼到名稱的映射（使用最後出現的對應關係）
        area_code_map = code_df.drop_duplicates('鄉鎮區代碼', keep='last').set_index('鄉鎮區代碼')['鄉鎮區'].to_dict()
        
        print(f"已載入 {len(city_code_map)} 筆縣市代碼對照")
        print(f"已載入 {len(area_code_map)} 筆鄉鎮區代碼對照")
        
        # 顯示部分縣市代碼對照
        print("\n部分縣市代碼對照：")
        for code, name in sorted(city_code_map.items())[:10]:  # 只顯示前10筆
            print(f"{code}: {name}")
            
        return area_code_map, city_code_map
        
    except Exception as e:
        print(f"載取代碼對照表時發生錯誤: {str(e)}")
        raise

def process_data(input_file, output_file, area_code_map, city_code_map):
    """
    處理長照ABC據點資料，轉換代碼為名稱
    
    Args:
        input_file (str): 輸入的CSV檔案路徑
        output_file (str): 輸出的CSV檔案路徑
        area_code_map (dict): 鄉鎮區代碼到名稱的映射
        city_code_map (dict): 縣市代碼到名稱的映射
    """
    print(f"\n正在處理檔案: {input_file}")
    try:
        # 讀取CSV檔案
        df = pd.read_csv(input_file, dtype=str)
        
        # 轉換縣市代碼為縣市名稱
        print("\n轉換縣市代碼...")
        df['縣市'] = df['縣市'].map(lambda x: city_code_map.get(str(x).strip(), x))
        
        # 轉換特約縣市代碼為縣市名稱
        print("轉換特約縣市代碼...")
        df['特約縣市'] = df['特約縣市'].map(lambda x: city_code_map.get(str(x).strip(), x))
        
        # 轉換鄉鎮區代碼為鄉鎮區名稱
        print("轉換鄉鎮區代碼...")
        df['區'] = df['區'].map(lambda x: area_code_map.get(str(x).strip(), x))
        
        # 處理特約區域（可能包含多個代碼，以分號分隔）
        def map_area_codes(codes_str):
            if pd.isna(codes_str) or not str(codes_str).strip():
                return ''
            codes = str(codes_str).split(';')
            areas = [area_code_map.get(code.strip(), code.strip()) for code in codes]
            return ';'.join(areas)
        
        print("轉換特約區域代碼...")
        df['特約區域'] = df['特約區域'].apply(map_area_codes)
        
        # 儲存結果
        df.to_csv(output_file, index=False, encoding='utf-8-sig')
        print(f"\n處理完成！結果已儲存至: {output_file}")
        
        # 顯示前幾筆資料
        print("\n轉換後的資料預覽：")
        print(df[['機構名稱', '縣市', '區', '特約縣市', '特約區域']].head().to_string())
        
        return df
        
    except Exception as e:
        print(f"處理資料時發生錯誤: {str(e)}")
        raise

def main():
    # 設定檔案路徑
    data_dir = Path("/Users/siniuho/Labs/Taipei-City-Dashboard/my-data/長照/")
    mapping_file = data_dir / "縣市鄉鎮區代碼對照表.csv"
    input_file = data_dir / "長照ABC據點.csv"
    output_file = data_dir / "長照ABC據點_行政區轉換後_v3.csv"
    
    try:
        # 載入代碼對照表
        area_code_map, city_code_map = load_area_mapping(mapping_file)
        
        # 處理資料
        process_data(input_file, output_file, area_code_map, city_code_map)
        
    except Exception as e:
        print(f"\n程式執行失敗: {str(e)}")
        return 1
    
    return 0

if __name__ == "__main__":
    main()