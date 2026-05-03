import pandas as pd
import os

# 建立輸出目錄
output_dir = 'processed_data'
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

# 讀取台北市資料
taipei_df = pd.read_csv('sun-data/臺北市老人福利機構名冊.csv')

# 讀取新北市資料
newtaipei_df = pd.read_csv('sun-data/新北市老人福利機構.csv')

# 處理台北市資料
taipei_processed = pd.DataFrame({
    'town': taipei_df['區域別'],
    'bed_for_caring': taipei_df['養護床位數量'],
    'bed_for_nursing': taipei_df['安養床位數量'],
    'bed_for_longterm': taipei_df['長照床位數量'],
    'bed_for_azh': taipei_df['失智床位數量']
})

# 處理新北市資料
newtaipei_processed = pd.DataFrame({
    'town': newtaipei_df['town'],
    'bed_for_caring': newtaipei_df['bed_for_caring'],
    'bed_for_nursing': newtaipei_df['bed_for_nursing'],
    'bed_for_longterm': newtaipei_df['bed_for_longterm'],
    'bed_for_azh': newtaipei_df['bed_for_azh']
})

# 依照行政區統計台北市資料
taipei_summary = taipei_processed.groupby('town').sum().reset_index()

# 依照行政區統計新北市資料
newtaipei_summary = newtaipei_processed.groupby('town').sum().reset_index()

# 將數值轉換為整數
numeric_columns = ['bed_for_caring', 'bed_for_nursing', 'bed_for_longterm', 'bed_for_azh']
taipei_summary[numeric_columns] = taipei_summary[numeric_columns].fillna(0).astype(int)
newtaipei_summary[numeric_columns] = newtaipei_summary[numeric_columns].fillna(0).astype(int)

# 儲存處理後的資料
taipei_summary.to_csv(f'{output_dir}/taipei_summary.csv', index=False)
newtaipei_summary.to_csv(f'{output_dir}/newtaipei_summary.csv', index=False)

print('資料處理完成！檔案已儲存在 processed_data 目錄中。')
print('\n台北市各行政區床位統計：')
print(taipei_summary.to_string(index=False))
print('\n新北市各行政區床位統計：')
print(newtaipei_summary.to_string(index=False)) 