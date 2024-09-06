import requests
from datetime import datetime

# TODO: Add error handling for requests, logging, configuration, and a listener queue

class bazaar_data:
    def __init__(self, request_data: requests.Response) -> None:
        self.json = request_data.json()
        self.last_updated = request_data.headers['last-modified']
        self.timestamp = datetime.timestamp(datetime.strptime(self.last_updated, "%a, %d %b %Y %H:%M:%S GMT"))

        self.headers = request_data.headers
        
class bazaar_updater:
    def __init__(self) -> None:
        self.request_session = requests.Session()
        self.localCache = {"last-updated": {"last-updated-timestamp": None, "last-updated-string": None, "last-updated-data": None}}
    
    def get_bazaar_data(self):
        request_data = self.request_session.get('https://api.hypixel.net/skyblock/bazaar', headers={'User-Agent': 'Mozilla/5.0'})
        return bazaar_data(request_data)
    
    def send_to_listener(self, data: bazaar_data):
        try:
            self.request_session.post('http://localhost:8000/bazaar', json=data.json, timeout=0.5)
        except requests.exceptions.RequestException as e:
            print(e)
    
    def update_cache(self, data: bazaar_data):
        self.localCache["last-updated"]["last-updated-timestamp"] = data.timestamp
        self.localCache["last-updated"]["last-updated-string"] = data.last_updated
        self.localCache["last-updated"]["last-updated-data"] = data.json
        
        print("Updated cache")
        
    def start(self):
        while True:
            request_data = self.get_bazaar_data()
            if (type(request_data) == bazaar_data):
                if self.localCache["last-updated"]["last-updated-timestamp"] != request_data.timestamp:
                    self.send_to_listener(request_data)
                    self.update_cache(request_data)
                    
                    
if __name__ == "__main__":
    updater = bazaar_updater()
    updater.start()