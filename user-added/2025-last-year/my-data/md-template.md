# XXX（index: `xxx`）

## 1. `dashboardmanager` 資料庫

### 1.1 插入 `components` 資料表

```sql

```

### 1.2 插入 `component_charts` 資料表

```sql

```

### 1.3 插入 `component_maps` 資料表

```sql

```

### 1.4 插入 `query_charts` 資料表

#### 1.4.1 台北市

```sql

```

#### 1.4.2 雙北

```sql

```

## 2. `dashboard` 資料庫

### 2.1 `xxx_tpe` 資料表

#### Metadata

- 資料來源：台北市資料大平台
- URL：
- 資料筆數：
- 更新頻率：
- 資料集提供機關：臺北市政府 XX 局

#### 資料轉換

#### 資料庫操作

1. **建立資料表**

```sql
CREATE TABLE xxx_tpe (
  your_fields
);
```

2. **匯入 CSV 檔案**

```bash
docker cp ./xxx_tpe.csv postgres-data:/tmp/xxx_tpe.csv
```

```sql
COPY xxx_tpe (
  your_fields
)
FROM '/tmp/xxx_tpe.csv'
WITH (
  FORMAT csv,
  HEADER,
  ENCODING 'UTF8'
);
```

### 2.2 `xxx_ntpc` 資料表

#### Metadata

- 資料來源：新北市政府資料開放平台
- URL：
- 資料筆數：
- 更新頻率：
- 資料集提供機關：新北市政府 XX 局

#### 資料轉換

#### 資料庫操作

1. **建立資料表**

```sql
CREATE TABLE xxx_ntpc (
  your_fields
);
```

2. **匯入 CSV 檔案**

```bash
docker cp ./xxx_tpe.csv postgres-data:/tmp/xxx_tpe.csv
```

```sql
COPY xxx_ntpc (
  your_fields
)
FROM '/tmp/xxx_ntpc.csv'
WITH (
  FORMAT csv,
  HEADER,
  ENCODING 'UTF8'
);
```
