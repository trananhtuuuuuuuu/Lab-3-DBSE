from Crypto.PublicKey import RSA
from Crypto.Cipher import PKCS1_OAEP

def encrypt_score(pubkey_pem, score):
    pubkey = RSA.import_key(pubkey_pem)
    cipher = PKCS1_OAEP.new(pubkey)
    encrypted = cipher.encrypt(str(score).encode())
    return encrypted
