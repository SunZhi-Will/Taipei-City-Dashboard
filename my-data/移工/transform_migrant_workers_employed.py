import pandas as pd
import re

def minguo_to_ad(minguo_str):
    # 將民國年轉為西元年
    m = re.search(r'(\d+)年', str(minguo_str))
    if m:
        return 1911 + int(m.group(1))
    return None

def extract_month(date_str):
    m = re.search(r'(\d+)月', str(date_str))
    return int(m.group(1)) if m else None

def transform_migrant_worker_data(file_path):
    # 讀取 CSV 檔案
    df = pd.read_csv(file_path, encoding='big5')
    
    # 定義 id 欄位和數值欄位
    id_vars = ['統計期', '縣市別/國籍別']
    value_vars = [col for col in df.columns if col not in id_vars]
    
    # 將寬表格轉換為長表格
    df_long = pd.melt(
        df,
        id_vars=id_vars,
        value_vars=value_vars,
        var_name='job_type',
        value_name='count'
    )
    
    # 處理國籍（取「/」後半段並去除前後空白）
    df_long['nationality'] = df_long['縣市別/國籍別'].str.split('/').str[1].str.strip()
    
    # 轉換日期
    df_long['year'] = df_long['統計期'].apply(minguo_to_ad)
    df_long['month'] = df_long['統計期'].apply(extract_month)
    
    # 處理數值（將「－」轉為 NaN，再轉為整數）
    df_long['count'] = pd.to_numeric(
        df_long['count'].replace('－', pd.NA),
        errors='coerce'
    ).astype('Int64')
    
    # 只保留需要的欄位
    result = df_long[[
        'year',
        'month',
        'nationality',
        'job_type',
        'count'
    ]].dropna(subset=['count'])  # 移除 count 為空值的列
    
    return result

if __name__ == "__main__":
    # 處理台北市資料
    df_tpe = transform_migrant_worker_data('台北市受聘僱移工.csv')
    df_tpe.to_csv('migrant_workers_tpe.csv', index=False, encoding='utf-8-sig')
    
    # 處理新北市資料
    df_ntpc = transform_migrant_worker_data('新北市受聘僱移工.csv')
    df_ntpc.to_csv('migrant_workers_ntpc.csv', index=False, encoding='utf-8-sig')
    
    print("轉換完成！產出檔案：")
    print("- migrant_workers_tpe.csv")
    print("- migrant_workers_ntpc.csv")
