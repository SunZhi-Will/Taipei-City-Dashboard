import csv
import os
from collections import defaultdict

csv_file_path = os.path.expanduser('~/Downloads/臺北市110學年度國民中學里鄰學區對照表_rev3.csv')
output_csv_path = os.path.expanduser('~/hackathon/Taipei-City-Dashboard/tim-scripts/台北市每區學區數量.csv')

# Dictionary to hold counts per district
district_counts = defaultdict(int)

with open(csv_file_path, mode='r', encoding='utf-8') as file:
    reader = csv.DictReader(file)
    
    for row in reader:
        district_field = row['行政區']  # 區域
        study_zone = row['學校學區']
        if len(study_zone) == 2:
            district_counts[district_field] += 1

# Write the results to a new CSV file
with open(output_csv_path, mode='w', encoding='utf-8-sig', newline='') as outfile:
    writer = csv.writer(outfile)
    writer.writerow(['district', 'count'])  # header
    for district, count in sorted(district_counts.items()):
        writer.writerow([district, count])

