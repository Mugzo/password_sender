import pymongo

from . import mongodb
from .validator import PASSWORD_VALIDATOR

client = pymongo.MongoClient(mongodb)

DB_NAME = "PasswordSender"
COLLECTION_NAME = "Passwords"

# Create database if it doesn't exist
db = client[DB_NAME]
if DB_NAME not in client.list_database_names():
    # Create a database
    db.command({"customAction": "CreateDatabase"})
    print(f"Created database: {DB_NAME}")
else:
    print(f"Using database: {DB_NAME}")

# Create collection if it doesn't exist
collection = db[COLLECTION_NAME]
if COLLECTION_NAME not in db.list_collection_names():
    # Creates a unsharded collection
    db.command({"customAction": "CreateCollection", "collection": COLLECTION_NAME}, validator=PASSWORD_VALIDATOR, validationAction="error", validationLevel="moderate")
    print(f"Created collection: {COLLECTION_NAME}")
else:
    print(f"Using collection: {COLLECTION_NAME}")


def create_password(password):
    collection.insert_one(password)
    return


def delete_password(password_id):
    query = {"password_id": password_id}
    collection.delete_one(query)
    return


def update_password(data):
    query = {"password_id": data["password_id"]}
    new_values = {"$set": {"views": data["views"], "updated_at": data["updated_at"]}}
    collection.update_one(query, new_values)
    return


def get_password(password_id, route):
    try:
        query = {"password_id": password_id}
        data = collection.find_one(query)
        if (route == "preview"):
            return {"expire_days": data["expire_days"], "expire_views": data["expire_views"], "viewer_deletable": data["viewer_deletable"]}
        elif (route == "access"):
            return {"passphrase_hash": data["passphrase_hash"]}
        elif (route == "view"):
            return data
    except TypeError:
        return None