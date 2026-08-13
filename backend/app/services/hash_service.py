import hashlib

def calculate_sha256(data: bytes) -> str:
    """
    Calculates the SHA-256 hash of a byte sequence.
    """
    sha256_hash = hashlib.sha256()
    sha256_hash.update(data)
    return sha256_hash.hexdigest()

def verify_hash(data: bytes, expected_hash: str) -> bool:
    """
    Verifies if the calculated hash matches the expected hash.
    """
    actual_hash = calculate_sha256(data)
    return actual_hash.lower() == expected_hash.lower()
