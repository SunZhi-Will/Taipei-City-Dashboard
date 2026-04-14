import csv
import os
from collections import defaultdict

csv_file_path = os.path.expanduser('~/Downloads/111台北市年齡分佈.csv')
output_csv_path = os.path.expanduser('~/hackathon/Taipei-City-Dashboard/tim-scripts/台北市老人分佈.csv')

# Dictionary to hold counts per district
district_counts = defaultdict(int)

with open(csv_file_path, mode='r', encoding='big5') as file:
    reader = csv.DictReader(file)
    
    for row in reader:
        year = row['年份']
        if year == '112':
            for i in range (65, 101):
                query = f"{i}歲數量"
                if i == 100:
                    query = query[:len(query)-2]
                    query += "以上"
                if row['區域別'] != '總計':
                    district_counts[row['區域別']] += int(row[query])

# Write the results to a new CSV file
with open(output_csv_path, mode='w', encoding='utf-8-sig', newline='') as outfile:
    writer = csv.writer(outfile)
    writer.writerow(['district', 'count'])  # header
    for district, count in sorted(district_counts.items()):
        writer.writerow([district, count])


