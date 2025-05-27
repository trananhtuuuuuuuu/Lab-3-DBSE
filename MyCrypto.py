import os
import hashlib
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa, padding

class MyCrypto:

    KEY_FOLDER = "key"


    def __init__(self):
        # Create key folder to store key if it does not exist
        os.makedirs(self.KEY_FOLDER, exist_ok=True)


    def _get_key_path(self, id: str):
        return os.path.join(self.KEY_FOLDER, f"{id}.pem")


    def _load_or_create_keys(self, id: str):
        key_path = self._get_key_path(id)

        if os.path.exists(key_path):
            with open(key_path, "rb") as key_file:
                private_key = serialization.load_pem_private_key(
                    key_file.read(),
                    password=None,
                )
            public_key = private_key.public_key()

        else:
            private_key = rsa.generate_private_key(
                public_exponent=65537,
                key_size=2048
            )
            public_key = private_key.public_key()
            private_pem = private_key.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.TraditionalOpenSSL,
                encryption_algorithm=serialization.NoEncryption()
            )
            with open(key_path, "wb") as key_file:
                key_file.write(private_pem)
                print(f"Generated and saved key for id {id}")

        return public_key, private_key
    

    def get_public_key(self, id: str) -> str:
        """
        Get public key for given id
        :param id: employee id
        :return: public key in PEM format
        """

        public_key, _ = self._load_or_create_keys(id)
        pem = public_key.public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo
        )

        lines = pem.decode().splitlines()
        public_key_value = ''.join(line for line in lines if "BEGIN" not in line and "END" not in line)
        
        return public_key_value


    def encrypt_salary(self, id: str, salary: str) -> bytes:

        """
        Encrypt salary by using RSA and public key for given id
        :param id: employee id
        :param salary: string of salary value
        :return: encrypted salary
        """

        public_key, _ = self._load_or_create_keys(id)
        encrypted_salary = public_key.encrypt(
            salary.encode(),
            padding.OAEP(
                mgf=padding.MGF1(algorithm=hashes.SHA1()),
                algorithm=hashes.SHA1(),
                label=None
            )
        )

        return "0x" + encrypted_salary.hex()


    def decrypt_salary(self, id: str, ciphertext: bytes) -> str:

        """
        Decrypt salary by using RSA and private key for given id
        :param id: employee id
        :param ciphertext: encrypted salary 
        :return: salary value
        """

        # Remove "0x" prefix
        ciphertext = bytes.fromhex(ciphertext[2:])

        _, private_key = self._load_or_create_keys(id)
        decrypted_salary = private_key.decrypt(
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
        return "0x" + sha1_hash



# -------------------------------
# USAGE
# -------------------------------
if __name__ == "__main__":

    my_crypto = MyCrypto()

    # Enter data here
    salary = "100000000"
    password = "abc123"
    employee_id = "NV05"

    public_key = my_crypto.get_public_key(employee_id)
    print(f"\nPublic key for {employee_id}:  {public_key}")
    print("\n" + "-" * 80 + "\n")
    encrypted_salary = my_crypto.encrypt_salary(employee_id, salary)
    print(f"Encryp salary (hex): {encrypted_salary}")
    print("\n" + "-" * 80 + "\n")

    decrypted_salary = my_crypto.decrypt_salary(employee_id, encrypted_salary)
    print(f"Decryp salary: {decrypted_salary}")
    print("\n" + "-" * 80 + "\n")

    hashed_password = my_crypto.hash_password_by_sha1(password)
    print(f"Hash password by SHA1: {hashed_password}")
    print("\n" + "-" * 80 + "\n")
