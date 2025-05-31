import csv
import os
from collections import defaultdict

csv_file_path = os.path.expanduser('~/Downloads/新北市國中里鄰學區.csv')
output_csv_path = os.path.expanduser('~/hackathon/Taipei-City-Dashboard/tim-scripts//新北市每區學區數量.csv')

# Dictionary to hold counts per district
district_counts = defaultdict(int)

with open(csv_file_path, mode='r', encoding='utf-8') as file:
    reader = csv.DictReader(file)
    
    for row in reader:
        district_field = row['district']  # 區域
        if district_field != "":
            district_counts[district_field] += 1

# Write the results to a new CSV file
with open(output_csv_path, mode='w', encoding='utf-8-sig', newline='') as outfile:
    writer = csv.writer(outfile)
    writer.writerow(['district', 'count'])  # header
    for district, count in sorted(district_counts.items()):
        writer.writerow([district, count])

