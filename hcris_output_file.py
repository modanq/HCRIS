import mysql.connector
import csv
import time
import config


def main():
    # Connect to MySQL database
    cnx = mysql.connector.connect(
        user=config.database.user,
        password=config.database.password,
        host='localhost',
        database='HCRIS'
    )

    cursor = cnx.cursor()

    # Extract relevant features into CSV file for data analysis with Python or R
    start = time.time()

    print("Querying database for reports and features")
    cursor.execute("SELECT * FROM `aggregate`;")

    print("Writing output file to hcris.csv")
    with open("./hcris.csv", "w+") as csv_file:
        csv_writer = csv.writer(csv_file)
        csv_writer.writerow(col[0] for col in cursor.description)
        csv_writer.writerows(cursor)

    end = time.time()
    print("Execution took %f seconds" % (end - start))

    cursor.close()
    cnx.close()


if __name__ == '__main__':
    main()
