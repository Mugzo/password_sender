from flask import Flask
from azure.keyvault.secrets import SecretClient
from azure.identity import DefaultAzureCredential

# In production this needs to be an envrionment variable
KVuri = f"https://dev-kv-passwordsender-0.vault.azure.net/"

credential = DefaultAzureCredential()
client = SecretClient(vault_url=KVuri, credential=credential)

# Get the encryption key from the KeyVault Secret
encryptionKey = client.get_secret("PasswordEncryptionKey").value

# Get the SQL server and Database name
sqlServerName = client.get_secret("sqlServerName").value
sqlDbName = client.get_secret("sqlDbName").value

def create_app():
    app = Flask(__name__)
    app.secret_key = encryptionKey

    from .views import views

    app.register_blueprint(views, url_prefix='/')

    return app