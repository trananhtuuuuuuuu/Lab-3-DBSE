import pyodbc

def get_connection():
    return pyodbc.connect(
        'DRIVER={ODBC Driver 17 for SQL Server};'
        'SERVER=ANHTU;'
        'DATABASE=QLSVNhom;'
        'Trusted_Connection=yes;'
    )
