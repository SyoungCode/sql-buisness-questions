# Olist E-Commerce: SQL Business Questions

34 business questions answered with SQL on the [Olist Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce): around 100,000 real (anonymised) orders placed on a Brazilian marketplace between 2016 and 2018.

Each query starts from a question a business stakeholder might actually ask, e.g. *"Do cross-state shipments take longer to deliver?"* or *"Which sellers are strong in both revenue and customer satisfaction?"*, and answers it with SQL.

## What's covered

| Section | Example questions |
|---|---|
| **Sales & revenue** | Monthly revenue, month-on-month growth, cumulative revenue, customer spend tiers |
| **Products & categories** | Top categories by revenue, products never sold, best-reviewed categories |
| **Customers** | Customer value by state, repeat purchase rate, average days to second order |
| **Sellers** | Highest-volume sellers, top seller per category, revenue vs satisfaction |
| **Delivery & logistics** | Early / on-time / late split, same-state vs cross-state delivery times, busiest days and hours |
| **Reviews & satisfaction** | Sentiment breakdown, orders without reviews, review comments |
| **Operational reporting** | Full order history report, city name cleaning, reusable seller performance view |

## SQL techniques used

- Multi-table `JOIN`s across up to 5 tables, including `LEFT JOIN … IS NULL` anti-joins
- Common Table Expressions (`WITH`), including chained CTEs
- Window functions: `LAG`, `NTILE`, `ROW_NUMBER`, running totals with `SUM() OVER`
- `CASE` expressions for segmentation (value tiers, sentiment, delivery status)
- Aggregation with `GROUP BY` / `HAVING`
- Date handling with `strftime` and `julianday`
- Data cleaning with `TRIM`, `LOWER`, `COALESCE`
- Views (`CREATE VIEW`) for reusable reports

## How to run it

The dataset isn't stored in this repo. It's too large for GitHub and is already hosted on Kaggle. The setup script downloads it and builds the database for you. **No Kaggle account needed.**

**1. Clone the repo**
```bash
git clone https://github.com/SyoungCode/sql-buisness-questions.git
cd sql-buisness-questions
```

**2. Build the database** (requires Python 3)
```bash
pip install -r requirements.txt
python build_db.py
```
This downloads the 9 Olist CSVs and loads them into `olist.db` (SQLite).

**3. Run the queries**
Open `olist.db` in [DB Browser for SQLite](https://sqlitebrowser.org/) (free), go to the **Execute SQL** tab, open `olist_queries.sql`, and run any query by highlighting it and pressing `Ctrl+Enter` (`Cmd+Enter` on Mac).

<details>
<summary>Prefer not to use Python? Manual setup</summary>

1. Download the dataset from [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) and unzip it.
2. In DB Browser for SQLite, create a new database called `olist.db`.
3. Use **File → Import → Table from CSV file** for each of the 9 CSVs, keeping the file name (without `.csv`) as the table name and ticking "Column names in first line".
</details>

## Repo structure

```
├── olist_queries.sql   # all 34 business questions and queries
├── build_db.py         # downloads the dataset and builds olist.db
├── requirements.txt
└── README.md
```

## Dataset

Olist Brazilian E-Commerce Public Dataset, published by Olist on Kaggle. All credit for the data goes to Olist. See the [Kaggle page](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) for licence details.
