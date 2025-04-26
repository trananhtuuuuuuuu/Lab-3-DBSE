from db import get_connection
from rsa_utils import encrypt_score

def insert_grade(masv, mahp, diemthi, pubkey_pem):
    encrypted_score = encrypt_score(pubkey_pem, diemthi)

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("EXEC SP_INSERT_GRADE ?, ?, ?", (masv, mahp, encrypted_score))
    conn.commit()

    conn.close()
