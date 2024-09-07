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
    def __init__(self, bazaar_url, listener_server, user_agent) -> None:
        self.request_session = requests.Session()
        self.localCache = {
            "last-updated": {
                "timestamp": 0,
                "timestring": "",
                "data": {}
            }
        }
        
        self.bazaar_url = bazaar_url
        self.listener_server = listener_server
        self.user_agent = user_agent
        

    def get_bazaar_data(self):
        request_data = self.request_session.get(self.bazaar_url, headers={'User-Agent': self.user_agent})
        return bazaar_data(request_data)
    
    def send_to_listener(self, data: bazaar_data):
        try:
            self.request_session.post(self.listener_server, json=data.json, timeout=0.5)
        except requests.exceptions.RequestException as e:
            print(e)
    
    def update_cache(self, data: bazaar_data):
        self.localCache["last-updated"]["timestamp"] = data.timestamp
        self.localCache["last-updated"]["timestring"] = data.last_updated
        self.localCache["last-updated"]["data"] = data.json
        
        print("Updated cache")
        
    def start(self):
        while True:
            request_data = self.get_bazaar_data()
            if (type(request_data) == bazaar_data):
                if self.localCache["last-updated"]["timestamp"] != request_data.timestamp:
                    self.send_to_listener(request_data)
                    self.update_cache(request_data)
                    
                    
def start_bazaar_client(bazaar_url, listener_server, user_agent):
    updater = bazaar_updater(bazaar_url, listener_server, user_agent)
    updater.start()