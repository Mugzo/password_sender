from flask import Flask
from azure.keyvault.secrets import SecretClient
from azure.identity import DefaultAzureCredential

import os

# Azure Keyvault endpoint
KVuri = os.environ["AZURE_KEYVAULT_RESOURCEENDPOINT"]

credential = DefaultAzureCredential()
client = SecretClient(vault_url=KVuri, credential=credential)

# Get the encryption key from the KeyVault Secret
encryptionKey = client.get_secret("PasswordEncryptionKey").value

# Get the SQL server and Database name
sqlServerName = os.environ["AZURE_SQL_SERVER"]
sqlDbName = os.environ["AZURE_SQL_DATABASE"]

def create_app():
    app = Flask(__name__)
    app.secret_key = encryptionKey

    from .views import views

    app.register_blueprint(views, url_prefix='/')

    return app