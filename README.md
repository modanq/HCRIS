# Medicare 340B
Python and MySQL Scripts to analyze the 340B drug discount program.

## Load Medicare HCRIS files from CMS Website
1. Setup MySQL environment
    * Recommend high cpu and high memory machine with optimization of `mysqld.cnf` configuration; using Google Cloud compute engine n1-highmem-4 (4 vCPUs, 26 GB memory) it takes ~15 min
2. Run `./HCRIS/hcris_create_database.sql` (creates HCRIS databsase and tables)
3. Setup Python 3 enviornment
    * Create `./HCRIS/config.py` file as below
    * Install `mysql.connector` Python package by either:
        * `apt-get install apt-get install python3-mysql.connector`
        * `pip3 install mysql.connector`
4. Run `./HCRIS/hcris_load_extract.py` (downloads and loads Medicare HCRIS data into MySQL)

## ./HCRIS/config.py
~~~~
class Database:
    def __init__(self):
        self.user = "user"
        self.password = "password"


database = Database()
~~~~
