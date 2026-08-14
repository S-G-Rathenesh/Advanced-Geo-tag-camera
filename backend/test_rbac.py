import requests

def test_api():
    print("Testing backend...")
    try:
        r = requests.get("http://127.0.0.1:8000/api/v1/health")
        print("Health:", r.text)
    except Exception as e:
        print("Backend not running", e)

if __name__ == "__main__":
    test_api()
