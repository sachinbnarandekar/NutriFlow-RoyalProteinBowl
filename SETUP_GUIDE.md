# NutriFlow — RoyalProteinBowl.in
## Step-by-Step Setup Guide for Students

This guide assumes you have **zero prior experience** with Python or MySQL.
Follow every step in order. Do not skip steps.

---

## PART 1 — Install What You Need (One-Time Setup)

### 1.1 Install Python
- Download from https://www.python.org/downloads/ (choose the latest stable version)
- During installation, **tick the box "Add Python to PATH"** — this is the most
  commonly missed step and causes errors later
- Verify installation: open Command Prompt and type `python --version`

### 1.2 Install VS Code
- Download from https://code.visualstudio.com/
- Install the **Python extension** inside VS Code (Extensions tab → search "Python" → Install)

### 1.3 Install MySQL Server + MySQL Workbench
- Download MySQL Installer from https://dev.mysql.com/downloads/installer/
- Choose "Developer Default" during setup — this installs both MySQL Server
  and MySQL Workbench together
- During setup, you will be asked to set a **root password** — write this down,
  you will need it later
- After installation, open MySQL Workbench and confirm you can connect using
  the root password you set

### 1.4 Install Required Python Libraries
Open Command Prompt (or VS Code terminal) and run:

```
pip install pandas numpy faker mysql-connector-python
```

Wait for all 4 to finish installing before moving on.

---

## PART 2 — Generate the Datasets

### 2.1 Open the Project Folder in VS Code
File → Open Folder → select the `NutriFlow-RoyalProteinBowl` folder

### 2.2 Run the Data Generation Script
- Open `scripts/01_data_generation.py`
- Click the Run button (▶) at the top right of VS Code, OR
- Open terminal in VS Code and type:
```
cd scripts
python 01_data_generation.py
```

### 2.3 Confirm Success
You should see output like this:
```
✅ calendar.csv              →    730 rows saved
✅ locations.csv             →     18 rows saved
✅ item_master.csv           →     35 rows saved
... (and so on for all 11 tables)
✅ ALL 11 TABLES GENERATED SUCCESSFULLY
```

Check the `data/raw/` folder — you should now see 11 CSV files inside.
**Open a couple of them in Excel just to look at the data — make sure it
looks realistic before moving forward.**

---

## PART 3 — Load Data into MySQL

### 3.1 Create the Database and Tables
- Open MySQL Workbench
- Connect to your local MySQL server (using the root password you set)
- Open `sql/create_tables.sql`
- Click the lightning bolt icon (Execute) to run the entire script
- This creates the `royalproteinbowl` database with all 11 empty tables

### 3.2 Update Your Password in the Loader Script
- Open `scripts/02_load_to_mysql.py`
- Find this section near the top:
```python
DB_CONFIG = {
    "host": "localhost",
    "user": "root",
    "password": "your_password_here",   # <-- CHANGE THIS
    "database": "royalproteinbowl"
}
```
- Replace `"your_password_here"` with your actual MySQL root password
- Save the file

### 3.3 Run the Loader Script
In VS Code terminal:
```
python 02_load_to_mysql.py
```

You should see:
```
✅ Connected to MySQL database: royalproteinbowl
✅ calendar             →    730 rows loaded into MySQL
✅ locations            →     18 rows loaded into MySQL
... (and so on)
✅ ALL TABLES LOADED SUCCESSFULLY
```

### 3.4 Verify in MySQL Workbench
- Open `sql/verification_queries.sql` in MySQL Workbench
- Run each query one by one (or all together)
- Compare the row counts against the comments in the file — they should match

---

## PART 4 — You're Ready to Analyze

At this point you have:
- ✅ 11 CSV files in `data/raw/` (for use in Python/pandas notebooks)
- ✅ A fully populated MySQL database `royalproteinbowl` (for SQL queries and Power BI)

You can now move on to:
1. `notebooks/02_EDA.ipynb` — Exploratory Data Analysis in Python
2. `sql/business_queries.sql` — Writing your own SQL queries for each module
3. Power BI Desktop — Connect directly to your MySQL database to build the dashboard

---

## Common Errors and Fixes

| Error | Likely Cause | Fix |
|---|---|---|
| `'python' is not recognized` | Python not added to PATH | Reinstall Python, tick "Add to PATH" |
| `ModuleNotFoundError: No module named 'faker'` | Library not installed | Run `pip install faker` again |
| `Access denied for user 'root'@'localhost'` | Wrong password in DB_CONFIG | Double-check password in `02_load_to_mysql.py` |
| `Table 'royalproteinbowl.orders' doesn't exist` | Forgot to run create_tables.sql | Go back to Step 3.1 |
| `Foreign key constraint fails` | Tables loaded out of order | Don't modify TABLE_LOAD_ORDER in the script — it's already in the correct sequence |

---

## Connecting Power BI to MySQL (For Later — Dashboard Stage)

1. Open Power BI Desktop
2. Get Data → More → Database → MySQL Database
3. Server: `localhost`, Database: `royalproteinbowl`
4. Enter your MySQL username (root) and password
5. Select all 11 tables and load
6. Build relationships in Model View if Power BI doesn't auto-detect them
   (it should, since we have proper Foreign Keys)

---

**If you get stuck at any step, note down the exact error message and ask
your instructor — don't skip ahead, each step depends on the previous one
working correctly.**
