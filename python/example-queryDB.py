#!/usr/local/bin/python
import psycopg2
import sys

arg1 = sys.argv[1]
arg2 = sys.argv[2]
arg3 = sys.argv[3]


def main(table=arg1, date1=arg2, date2=arg3):
    #Define our connection string
    conn_string = "host='myhostname1' user='masteruser' password='Change#Password1' port='5439' dbname='mydbname1'"
    conn_string2 = "host='myhostname2' user='masteruser' password='Change#Password2' port='5439' dbname='mydbname2'"


    # get a connection, if a connect cannot be made an exception will be raised here
    conn = psycopg2.connect(conn_string)
    conn2 = psycopg2.connect(conn_string2)

    # conn.cursor will return a cursor object, you can use this cursor to perform queries
    cursor = conn.cursor()
    cursor2 = conn2.cursor()

    # row count statement
    cursor.execute("""select count(distinct visitor_id) from mydbname__main__spectrum.%s where visit_day = '%s';""" % (table, date1))
    cursor2.execute("""select count(distinct visitor_id) from mydbname__main.%s where updated >= '%s' and updated < '%s';""" % (table, date1, date2) )

    count = cursor.fetchall()
    count2 = cursor2.fetchall()

    print("Spectrum row count for %s table on day %s" % (table, date1))
    print(count)

    print("")
    print("")

    print("Native row count for %s table on day %s" % (table, date1))
    print(count2)

if __name__ == "__main__":
    main()
