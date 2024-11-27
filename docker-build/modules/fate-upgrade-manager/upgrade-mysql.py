import mysql.connector
import sys
import os

from functools import cmp_to_key


def cmp_ver(a, b):
    for va, vb in zip(a.split('.'), b.split('.')):
        va, vb = int(va), int(vb)
        if va > vb:
            return 1
        if va < vb:
            return -1
    return 0


def cmp_file_ver(a, b):
    return cmp_ver(a.split('-')[0], b.split('-')[0])


def get_script_list(start_ver, target_ver):
    sql_script_names = os.listdir("sql")
    print("FUM upgradeable sql list:", sql_script_names)
    inclusive_files = filter(lambda x: cmp_ver(
        x.split('-')[0], start_ver) >= 0 and cmp_ver(x.split('-')[1], target_ver) <= 0, sql_script_names)
    return sorted(inclusive_files, key=cmp_to_key(cmp_file_ver))


def preprocess_script(script):
    queries = []
    query = ''
    delimiter = ';'
    with open("sql/%s" % script, "r") as sql_file:
        for line in sql_file.readlines():
            line = line.strip()
            if line.startswith('DELIMITER'):
                delimiter = line[10:]
            else:
                query += line+'\n'
                if line.endswith(delimiter):
                    # Get rid of the delimiter, remove any blank lines and add this query to our list
                    queries.append(query.strip().strip(delimiter))
                    query = ''
    return queries


def run_script(script, cursor):
    queries = preprocess_script(script)
    for query in queries:
        if not query.strip():
            continue
        print("execute query %s" % query)
        cursor.execute(query)


if __name__ == '__main__':
    _, user, password, start_ver, end_ver = sys.argv
    print("Version upgrade span:", start_ver, end_ver)
    scripts_to_run = get_script_list(start_ver, end_ver)
    print("Filtered sql list:", scripts_to_run)
    mydb = mysql.connector.connect(
        host="mysql",
        user=user,
        password=password,
        database="eggroll_meta"
    )
    cursor = mydb.cursor()
    for script in scripts_to_run:
        run_script(script, cursor)
    cursor.close()
