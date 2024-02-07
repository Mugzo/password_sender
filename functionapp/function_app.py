import logging
import azure.functions as func
from azure.keyvault.secrets import SecretClient
from azure.identity import DefaultAzureCredential

import os
import pymongo
from datetime import datetime

app = func.FunctionApp()

@app.schedule(schedule="0 */1 * * * *", arg_name="myTimer", run_on_startup=False,
              use_monitor=False) 
def DeleteExpiredPasswords(myTimer: func.TimerRequest) -> None:
    if myTimer.past_due:
        logging.info("Timer past due")
        # Azure Keyvault endpoint
        KVuri = os.environ["AZURE_KEYVAULT_RESOURCEENDPOINT"]

        credential = DefaultAzureCredential()
        client = SecretClient(vault_url=KVuri, credential=credential)

        # Get the MongoDB name
        mongodb = client.get_secret("MongoDBConnectionString").value

        client = pymongo.MongoClient(mongodb)

        DB_NAME = "PasswordSender"
        COLLECTION_NAME = "Passwords"

        db = client[DB_NAME]
        collection = db[COLLECTION_NAME]

        now = datetime.now()

        query = {"expire_on": {"$lt": now}}
        data = collection.delete_many(query)
        logging.info("Expired passwords have been deleted.")

    logging.info('Python timer trigger function executed.')