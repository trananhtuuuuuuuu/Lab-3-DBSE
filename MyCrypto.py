import os
import base64
import hashlib
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa, padding

class MyCrypto:

    KEY_FOLDER = "key"
    PRIVATE_KEY_PATH = os.path.join(KEY_FOLDER, "private_key.pem")


    def __init__(self):
        if os.path.exists(self.PRIVATE_KEY_PATH):
            # Load private key from file
            with open(self.PRIVATE_KEY_PATH, "rb") as key_file:
                self.private_key = serialization.load_pem_private_key(
                    key_file.read(),
                    password=None,
                )
            # Get public key from private key
            self.public_key = self.private_key.public_key()
            print("Private key was loaded!")
        else:
            # Generate new RSA key pair and save private key to file 
            self.private_key, self.public_key = self.generate_key()
            self.save_key()
            

    def generate_key(self):
        private_key = rsa.generate_private_key(
                public_exponent=65537,
                key_size=2048
            )
        public_key = private_key.public_key()
        return private_key, public_key
    

    def save_key(self):
        os.makedirs(os.path.dirname(self.PRIVATE_KEY_PATH), exist_ok=True)

        private_pem = self.private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.TraditionalOpenSSL,
            encryption_algorithm=serialization.NoEncryption()
        )

        with open(self.PRIVATE_KEY_PATH, "wb") as key_file:
            key_file.write(private_pem)
        print("Private key saved in ", self.PRIVATE_KEY_PATH)


    def get_public_key(self):
        public_pem = self.public_key.public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo
        )
        lines = public_pem.decode().splitlines()
        public_key_value = ''.join(line for line in lines if "BEGIN" not in line and "END" not in line)
        return public_key_value


    def encrypt_salary(self, salary: str) -> bytes:
        """
        Encrypt salary by using RSA and public key
        :param salary: string of salary value
        :return: encrypted salary
        """
        encrypted_salary = self.public_key.encrypt(
            salary.encode(),
            padding.OAEP(
                mgf=padding.MGF1(algorithm=hashes.SHA1()),
                algorithm=hashes.SHA1(),
                label=None
            )
        )
        return encrypted_salary


    def decrypt_salary(self, ciphertext: bytes) -> str:
        """
        Decrypt salary by using RSA and private key
        :param ciphertext: encrypted salary 
        :return: slary value
        """
        decrypted_salary = self.private_key.decrypt(
            ciphertext,
            padding.OAEP(
                mgf=padding.MGF1(algorithm=hashes.SHA1()),
                algorithm=hashes.SHA1(),
                label=None
            )
        )
        return decrypted_salary.decode()


    def hash_password_by_sha1(self, password: str) -> str:
        """
        Hash password by using SHA1 algorithm
        :param password: password string 
        :return: hash string in hex
        """
        
        sha1_hash = hashlib.sha1(password.encode()).hexdigest()
        return sha1_hash



# -------------------------------
# USAGE
# -------------------------------
if __name__ == "__main__":
    # Init MyCrypto Instance
    my_crypto = MyCrypto()

    salary = "15000000"
    password = "abc123"

    public_key = my_crypto.get_public_key()
    print("Public key: ", public_key)

    encrypted_salary = my_crypto.encrypt_salary(salary)
    print("Encryp salary (base64): ", base64.b64encode(encrypted_salary).decode())

    decrypted_salary = my_crypto.decrypt_salary(encrypted_salary)
    print("Decryp salary: ", decrypted_salary)

    hashed_password = my_crypto.hash_password_by_sha1(password)
    print("Hash password by SHA1: ", hashed_password)
