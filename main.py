from config import config_file
from update import start_bazaar_client

# Loading configuration
config = config_file()

bazaar_url = config.get('bazaar_url')
listener_server = config.get('listener_server')
user_agent = config.get('user_agent')

print(f"Configuration loaded: {bazaar_url}, {listener_server}, {user_agent}")

start_bazaar_client(bazaar_url, listener_server, user_agent)