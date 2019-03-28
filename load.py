import mysql.connector
import requests, zipfile, io
import os, codecs
import config


def main():
    # Define data directory for MySQL LOAD DATA INFILE statements
    data_dir = "/var/lib/mysql-files"

    # Download raw HCRIS data from CMS website function
    def download(year, form):
        """Downloads HCRIS files from CMS website based on year and form (i.e. 2552-96 or 2552-10)."""
        if form == "2552-96":
            r = requests.get(f"http://downloads.cms.gov/Files/hcris/HOSPFY{year}.zip")
        else:
            r = requests.get(f"http://downloads.cms.gov/Files/hcris/HOSP10FY{year}.zip")
        # Extract contents of Zip file into folders by year
        z = zipfile.ZipFile(io.BytesIO(r.content))
        z.extractall(f"{data_dir}/{year}/")
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

    # Generic load Reports SQL Statement, with placeholders for data file, year, and form
    report_load_sql = """
        LOAD DATA INFILE %s
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
        LOAD DATA INFILE %s
            INTO TABLE alpha_temp
                FIELDS TERMINATED BY ','
            (report_id, worksheet_code, line_number, column_number, item_text)
                SET form = %s    
    """
    # Insert only those desired alpha variables in the extracted table (join of alpha_temp and extracted)
    alpha_insert_sql = """
        INSERT INTO alpha
        SELECT report_id, form, variable_name, item_text FROM alpha_temp
            JOIN extracted USING(form, worksheet_code, line_number, column_number)
        WHERE variable_type = "Alpha"    
    """
    # Generic load Numeric SQL Statement into temporary table, with placeholders for data file and form
    numeric_load_sql = """
        LOAD DATA INFILE %s
            INTO TABLE numeric_temp
                FIELDS TERMINATED BY ','
                LINES TERMINATED BY '\\r\\n'
            (report_id, worksheet_code, line_number, column_number, item_value)
                SET form = %s    
    """
    # Insert only those desired numeric variables in the extracted table (join of alpha_temp and extracted)
    numeric_insert_sql = """
        INSERT INTO `numeric`
        SELECT report_id, form, variable_name, item_value FROM numeric_temp
            JOIN extracted USING(form, worksheet_code, line_number, column_number)
        WHERE variable_type = "Numeric"
    """

    # Loop for years 1996-2011 to download, load, and extract data
    form = '2552-96'
    for year in range(1996, 2012):
        print(f"Downloading data for {year}")
        download(year, form)

        report_file = f"{data_dir}/{year}/hosp_{year}_RPT.CSV"
        remove_bom(report_file)
        alpha_file = f"{data_dir}/{year}/hosp_{year}_ALPHA.CSV"
        numeric_file = f"{data_dir}/{year}/hosp_{year}_NMRC.CSV"

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

    # Loop for years 2010-2018 to download, load, and extract data
    form = '2552-10'
    for year in range(2010, 2019):
        print(f"Downloading data for {year}")
        download(year, form)

        report_file = f"{data_dir}/{year}/hosp10_{year}_RPT.CSV"
        alpha_file = f"{data_dir}/{year}/hosp10_{year}_ALPHA.CSV"
        numeric_file = f"{data_dir}/{year}/hosp10_{year}_NMRC.CSV"

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

    cursor.close()
    cnx.close()


if __name__ == '__main__':
    main()
