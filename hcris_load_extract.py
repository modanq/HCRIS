import mysql.connector
import requests, zipfile, io
import os, codecs
import datetime
import csv
import config


def main():
    # Define data directory for data dump and MySQL LOAD DATA INFILE statements
    data_dir = "./data"
    current_year = datetime.datetime.now().year

    # Download raw HCRIS data from CMS website function
    def download(form, year=None):
        """Downloads HCRIS files from CMS website based on year and form (i.e. 2552-96 or 2552-10)."""
        if form == "2552-96" and year is not None:
            r = requests.get(f"http://downloads.cms.gov/Files/hcris/HOSPFY{year}.zip")
        elif form == "2552-10" and year is not None:
            r = requests.get(f"http://downloads.cms.gov/Files/hcris/HOSP10FY{year}.zip")
        elif form == "2552-96" and year is None:
            r = requests.get("http://downloads.cms.gov/files/hcris/HOSP-REPORTS.ZIP")
        elif form == "2552-10" and year is None:
            r = requests.get("http://downloads.cms.gov/files/hcris/hosp10-reports.zip")

        # Read content stream of Zip file and extract to data directory
        z = zipfile.ZipFile(io.BytesIO(r.content))
        z.extractall(f"{data_dir}/")
        z.close()

    # Remove 'Byte Order Mark' from report file of earlier years 1996-2011 form 2552-96
    def remove_bom(file):
        """Removes the 'Byte Order Mark' at the beginning of CSV file, which causes LOAD INFILE to fail"""
        bufsize = 4096
        bomlen = len(codecs.BOM_UTF8)

        with open(file, "r+b") as fp:
            chunk = fp.read(bufsize)
            if chunk.startswith(codecs.BOM_UTF8):
                i = 0
                chunk = chunk[bomlen:]
                while chunk:
                    fp.seek(i)
                    fp.write(chunk)
                    i += len(chunk)
                    fp.seek(bomlen, os.SEEK_CUR)
                    chunk = fp.read(bufsize)
                fp.seek(-bomlen, os.SEEK_CUR)
                fp.truncate()

    # Connect to MySQL database
    cnx = mysql.connector.connect(
        user=config.database.user,
        password=config.database.password,
        host='localhost',
        database='HCRIS'
    )

    cursor = cnx.cursor()

    # Load variable names and locations in HCRIS files
    cursor.execute("""
        LOAD DATA LOCAL INFILE './features.csv'
            INTO TABLE features
                FIELDS TERMINATED BY ','
    """)
    cnx.commit()

    # Generic load Providers SQL Statement, with placeholder for data file
    providers_load_sql = """
        LOAD DATA LOCAL INFILE %s
            IGNORE INTO TABLE provider # IGNORE here skips duplicates
                FIELDS TERMINATED BY ','
                LINES TERMINATED BY '\\r\\n'
                IGNORE 1 LINES
            (provider_id, @FYB, @FYE, @`STATUS`, @CTRL_TYPE, hospital_name, street_address, po_box, city, @state, @zip_code, county, @Rural)
                SET state = CASE
                    WHEN @state = "CONNECTICUT" THEN "CT"
                    WHEN @state = "MICHIGAN" THEN "MI"
                    WHEN @state = "NEW YORK" THEN "NY"
                    WHEN @state = "TEXAS" THEN "TX"
                    ELSE @state
                END
                , zip_code = TRIM(TRAILING '-' FROM @zip_code)
    """

    # Generic load Reports SQL Statement, with placeholders for data file, year, and form
    report_load_sql = """
        LOAD DATA LOCAL INFILE %s
            INTO TABLE report
                FIELDS TERMINATED BY ','
                LINES TERMINATED BY '\\r\\n'
            (report_id, @control_type_id, provider_id, @npi, report_status, @fiscal_year_start, @fiscal_year_end, @process_date, @INITL_RPT_SW, @LAST_RPT_SW, @TRNSMTL_NUM, @FI_NUM, @ADR_VNDR_CD, @FI_CREAT_DT, @medicare_utilization, @NPR_DT, @SPEC_IND, @FI_RCPT_DT)
                SET form = %s
                , report_year = %s
                , control_type_id = IF(@control_type_id = '', NULL, @control_type_id)
                , npi = NULLIF(@npi, '')
                , fiscal_year_start = DATE_FORMAT(STR_TO_DATE(@fiscal_year_start, '%m/%d/%Y'), '%Y-%m-%d')
                , fiscal_year_end = DATE_FORMAT(STR_TO_DATE(@fiscal_year_end, '%m/%d/%Y'), '%Y-%m-%d')
                , process_date = DATE_FORMAT(STR_TO_DATE(@process_date, '%m/%d/%Y'), '%Y-%m-%d')
                , medicare_utilization = CASE
                    WHEN @medicare_utilization = "L" THEN "Low"
                    WHEN @medicare_utilization = "N" THEN "None"
                    ELSE "Full"
                END
    """
    # Generic load Alpha SQL Statement into temporary table, with placeholders for data file and form
    alpha_load_sql = """
        LOAD DATA LOCAL INFILE %s
            INTO TABLE alpha_temp
                FIELDS TERMINATED BY ','
            (report_id, worksheet_code, line_number, column_number, item_text)
                SET form = %s    
    """
    # Extract and insert only those desired alpha variables in the features table (join of alpha_temp and extracted)
    alpha_insert_sql = """
        INSERT INTO alpha
        SELECT report_id, form, variable_name, item_text FROM alpha_temp
            JOIN features USING(form, worksheet_code, line_number, column_number)
        WHERE variable_type = "Alpha"    
    """
    # Generic load Numeric SQL Statement into temporary table, with placeholders for data file and form
    numeric_load_sql = """
        LOAD DATA LOCAL INFILE %s
            INTO TABLE numeric_temp
                FIELDS TERMINATED BY ','
                LINES TERMINATED BY '\\r\\n'
            (report_id, worksheet_code, line_number, column_number, item_value)
                SET form = %s    
    """
    # Extract and insert only those desired numeric variables in the features table (join of alpha_temp and extracted)
    numeric_insert_sql = """
        INSERT INTO `numeric`
        SELECT report_id, form, variable_name, item_value FROM numeric_temp
            JOIN features USING(form, worksheet_code, line_number, column_number)
        WHERE variable_type = "Numeric"
    """

    # Set form for years 1996-2011 and download provider data
    form = '2552-96'
    print(f"Downloading provider data for {form}")
    download(form)

    # Load provider data for 1996-2011
    provider_file = f"{data_dir}/HOSPITAL_PROVIDER_ID_INFO.csv"
    print(f"Loading provider data for {form}")
    cursor.execute(providers_load_sql, (provider_file,))
    cnx.commit()

    # Loop for years 1996-2011 to download, load, and extract data
    for year in range(1996, 2012):
        print(f"Downloading report data for {year}")
        download(form, year)

        report_file = f"{data_dir}/hosp_{year}_RPT.CSV"
        remove_bom(report_file)
        alpha_file = f"{data_dir}/hosp_{year}_ALPHA.CSV"
        numeric_file = f"{data_dir}/hosp_{year}_NMRC.CSV"

        print(f"Loading reports for {year}")
        cursor.execute(report_load_sql, (report_file, form, year))

        print(f"Loading alpha for {year}")
        cursor.execute(alpha_load_sql, (alpha_file, form))
        cursor.execute(alpha_insert_sql)
        cursor.execute("TRUNCATE alpha_temp")

        print(f"Loading numeric for {year}")
        cursor.execute(numeric_load_sql, (numeric_file, form))
        cursor.execute(numeric_insert_sql)
        cursor.execute("TRUNCATE numeric_temp")

        cnx.commit()

    # Set form for years 2010-present and download provider data
    form = '2552-10'
    print(f"Downloading provider data for {form}")
    download(form)

    # Load provider data for 2010-present
    provider_file = f"{data_dir}/HOSPITAL_PROVIDER_ID_INFO.csv"
    print(f"Loading provider data for {form}")
    cursor.execute(providers_load_sql, (provider_file,))
    cnx.commit()

    # Loop for years 2010-present to download, load, and extract data
    for year in range(2010, current_year):
        print(f"Downloading report data for {year}")
        download(form, year)

        report_file = f"{data_dir}/hosp10_{year}_RPT.CSV"
        alpha_file = f"{data_dir}/hosp10_{year}_ALPHA.CSV"
        numeric_file = f"{data_dir}/hosp10_{year}_NMRC.CSV"

        print(f"Loading reports for {year}")
        cursor.execute(report_load_sql, (report_file, form, year))

        print(f"Loading alpha for {year}")
        cursor.execute(alpha_load_sql, (alpha_file, form))
        cursor.execute(alpha_insert_sql)
        cursor.execute("TRUNCATE alpha_temp")

        print(f"Loading numeric for {year}")
        cursor.execute(numeric_load_sql, (numeric_file, form))
        cursor.execute(numeric_insert_sql)
        cursor.execute("TRUNCATE numeric_temp")

        cnx.commit()

    # Extract relevant features into CSV file for data analysis with Python or R
    cursor.execute("SELECT * FROM aggregate;")

    with open("./hcris.csv", "w+") as csv_file:
        csv_writer = csv.writer(csv_file)
        csv_writer.writerow(col[0] for col in cursor.description)
        csv_writer.writerows(cursor)

    cursor.close()
    cnx.close()


if __name__ == '__main__':
    main()
