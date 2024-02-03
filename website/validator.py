PASSWORD_VALIDATOR = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "title": "Password",
    "description": "A password in the collection",
    "type": "object",
    "properties" : {
        "password_id": {
            "description": "The unique identifier for the password",
            "type": "string",
            "maxLength": 22
        },
        "created_at": {
            "description": "The date the document was created",
            "type": "string",
            "format": "date-time"
        },
        "updated_at": {
            "description": "The last date the password was viewed",
            "type": "string",
            "format": "date-time"
        },
        "expire_days": {
            "description": "The number of days until the password expires",
            "type": "integer",
            "minimum": 0,
            "maximum": 30
        },
        "expire_views": {
            "description": "The number of views until the password expires",
            "type": "integer",
            "minimum": 1,
            "maximum": 100
        },
        "viewer_deletable": {
            "description": "If the viewer can immediately delete the password",
            "type": "boolean"
        },
        "views": {
            "description": "The current amount of views on the password",
            "type": "integer"
        },
        "expire_on": {
            "description": "The date the password expires on",
            "type": "string",
            "format": "date-time"
        },
        "passphrase_hash": {
            "description": "The passphrase SHA-256 hash",
            "type": "string",
            "maxLength": 64
        },
        "password": {
            "description": "The encrypted password",
            "type": "string",
            "maxLength": 184
        }
    },
    "required": [ "password_id","created_at","expire_days","expire_views","viewer_deletable","views","expire_on","password" ]
}