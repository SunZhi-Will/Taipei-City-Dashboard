#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pandas as pd
from pathlib import Path

def generate_area_mapping(input_file, output_file):
    """
    從縣市鄉鎮區代碼對照表生成完整的代碼對照表
    
    Args:
        input_file (str): 輸入的Excel檔案路徑
        output_file (str): 輸出的CSV檔案路徑
    """
    print(f"正在讀取檔案: {input_file}")
    xls = pd.ExcelFile(input_file)
    all_dfs = []
    
    # 處理每個工作表的資料
    for sheet_name in xls.sheet_names:
        df = pd.read_excel(input_file, sheet_name=sheet_name)
        
        # 檢查資料框是否為空
        if df.empty:
            continue
            
        # 取得所有縣市和鄉鎮區代碼的欄位組
        city_cols = [col for col in df.columns if '縣市代碼' in str(col)]
        area_cols = [col for col in df.columns if '鄉鎮區代碼' in str(col) and '縣市' not in str(col)]
        city_name_cols = [col for col in df.columns if '縣市' in str(col) and '代碼' not in str(col)]
        area_name_cols = [col for col in df.columns if '鄉鎮區' in str(col) and '代碼' not in str(col)]
        
        # 確保每組都有對應的欄位
        min_len = min(len(city_cols), len(area_cols), len(city_name_cols), len(area_name_cols))
        city_cols = city_cols[:min_len]
        area_cols = area_cols[:min_len]
        city_name_cols = city_name_cols[:min_len]
        area_name_cols = area_name_cols[:min_len]
        
        # 重新命名欄位並合併
        for city_col, city_name_col, area_col, area_name_col in zip(city_cols, city_name_cols, area_cols, area_name_cols):
            temp_df = df[[city_col, city_name_col, area_col, area_name_col]].copy()
            temp_df.columns = ['縣市代碼', '縣市', '鄉鎮區代碼', '鄉鎮區']
            all_dfs.append(temp_df)
    
    # 合併所有資料框
    if not all_dfs:
        raise ValueError("沒有找到有效的代碼資料")
    
    code_df = pd.concat(all_dfs, ignore_index=True)
    
    # 清理資料
    code_df = code_df.dropna(subset=['縣市代碼', '鄉鎮區代碼'])
    
    # 將縣市代碼轉換為字串並清理
    code_df['縣市代碼'] = code_df['縣市代碼'].astype(str).str.strip()
    code_df['縣市代碼'] = code_df['縣市代碼'].apply(lambda x: x.split('.')[0].zfill(5))
    code_df['縣市代碼'] = code_df['縣市代碼'].str[:5]
    
    # 處理鄉鎮區代碼
    code_df['鄉鎮區代碼'] = code_df['鄉鎮區代碼'].astype(str).str.strip().str.split('.').str[0]
    
    # 移除重複的資料
    code_df = code_df.drop_duplicates(subset=['縣市代碼', '鄉鎮區代碼'])
    
    # 重新排序欄位
    code_df = code_df[['縣市代碼', '縣市', '鄉鎮區代碼', '鄉鎮區']]
    
    # 儲存結果
    code_df.to_csv(output_file, index=False, encoding='utf-8-sig')
    print(f"\n代碼對照表已儲存至: {output_file}")
    print(f"總共 {len(code_df)} 筆資料")
    
    # 顯示部分資料
    print("\n代碼對照表示例：")
    print(code_df.head(10).to_string())
    
    # 顯示各縣市的鄉鎮區數量
    print("\n各縣市鄉鎮區數量統計：")
    print(code_df.groupby(['縣市代碼', '縣市']).size().sort_values(ascending=False).head(15))
    
    return code_df

def main():
    # 設定檔案路徑
    data_dir = Path("/Users/siniuho/Labs/Taipei-City-Dashboard/my-data/長照/")
    input_file = data_dir / "縣市鄉鎮區代碼對照表.xls"
    output_file = data_dir / "縣市鄉鎮區代碼對照表.csv"
    
    try:
        # 生成代碼對照表
        code_df = generate_area_mapping(input_file, output_file)
        
        # 顯示一些統計資訊
        print("\n代碼對照表統計：")
        print(f"總共 {len(code_df['縣市代碼'].unique())} 個縣市")
        print(f"總共 {len(code_df['鄉鎮區代碼'].unique())} 個鄉鎮區")
        
        # 檢查是否有重複的鄉鎮區代碼
        duplicate_areas = code_df[code_df.duplicated('鄉鎮區代碼', keep=False)].sort_values('鄉鎮區代碼')
        if not duplicate_areas.empty:
            print("\n注意：以下鄉鎮區代碼可能有多個對應的縣市：")
            print(duplicate_areas.to_string())
        else:
            print("\n所有鄉鎮區代碼都是唯一的")
            
    except Exception as e:
        print(f"處理過程中發生錯誤: {str(e)}")

if __name__ == "__main__":
    main()