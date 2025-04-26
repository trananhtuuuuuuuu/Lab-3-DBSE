# db.py
import pyodbc

# Hàm kết nối Database sử dụng Windows Authentication
def get_connection():
    conn = pyodbc.connect(
        'DRIVER={ODBC Driver 17 for SQL Server};'
        'SERVER=ANHTU;'
        'DATABASE=QLSVNhom;'
        'Trusted_Connection=yes;'
    )
    return conn