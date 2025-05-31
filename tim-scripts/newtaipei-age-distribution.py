import csv
import os
from collections import defaultdict

csv_file_path = os.path.expanduser('~/Downloads/新北市年齡分佈.csv')
output_csv_path = os.path.expanduser('~/hackathon/Taipei-City-Dashboard/tim-scripts/新北市老人分佈.csv')

# Dictionary to hold counts per district
district_counts = defaultdict(int)

with open(csv_file_path, mode='r', encoding='utf-8') as file:
    reader = csv.DictReader(file)
    
    for row in reader:
        field1 = row['\ufefffield1']  # 年度 & 區域
        parts = field1.split(" ")
        if parts[0] == '2023年':
            district = parts[1].split("-")[0]
            if district != '新北市':
                district_counts[district] = int(row['percent28'])

# Write the results to a new CSV file
with open(output_csv_path, mode='w', encoding='utf-8-sig', newline='') as outfile:
    writer = csv.writer(outfile)
    writer.writerow(['district', 'count'])  # header
    for district, count in sorted(district_counts.items()):
        writer.writerow([district, count])


