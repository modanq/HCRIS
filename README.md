# Medicare Hospital Cost Reports (HCRIS) Data
Python and MySQL Scripts to extract and analyze Medicare HCRIS files.

## Load HCRIS files from CMS Website
1. **Setup MySQL environment**
    * Recommend high cpu and high memory server with optimization of `mysqld.cnf` configuration
    * Using Google Cloud compute engine n1-highmem-4 (4 vCPUs, 26 GB memory) it takes ~15 min
2. **Run `hcris_create_database.sql`**
    * Creates empty HCRIS databsase and tables
3. **Setup Python 3 enviornment**
    * Create `config.py` file as below
    * Install `mysql.connector` Python package
4. **e**
5. **Run `hcris_load_extract.py`**
    * Downloads and loads Medicare HCRIS data into MySQL
    * Extracts features present in `features.csv` and creates `hcris.csv` file for analysis with R or Python 

## config.py
~~~~
class Database:
    def __init__(self):
        self.user = "[user]"
        self.password = "[password]"


database = Database()
~~~~
