import pyodbc, struct
from azure.identity import DefaultAzureCredential
from sqlalchemy import create_engine, event, Column, String, Integer, DateTime, Boolean, select, update, delete
from sqlalchemy.engine.url import URL
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.sql import func

from . import sqlServerName, sqlDbName

SQL_COPT_SS_ACCESS_TOKEN = 1256 # Connection option for access tokens, as defined in msodbcsql.h
TOKEN_URL = "https://database.windows.net/"  # The token URL for any Azure SQL database

connection_string = f"mssql+pyodbc://@{sqlServerName}/{sqlDbName}?driver=ODBC+Driver+18+for+SQL+Server"

engine = create_engine(connection_string)

credentials = DefaultAzureCredential()

Session = sessionmaker(bind=engine)
session = Session()


@event.listens_for(engine, "do_connect")
def provide_token(dialect, conn_rec, cargs, cparams):
    # remove the "Trusted_Connection" parameter that SQLAlchemy adds
    cargs[0] = cargs[0].replace(";Trusted_Connection=Yes", "")

    # create token credential
    raw_token = credentials.get_token(TOKEN_URL).token.encode("utf-16-le")
    token_struct = struct.pack(f"<I{len(raw_token)}s", len(raw_token), raw_token)

    # apply it to keyword arguments
    cparams["attrs_before"] = {SQL_COPT_SS_ACCESS_TOKEN: token_struct}

Base = declarative_base()

class Passwords(Base):
    __tablename__ = "Passwords"

    password_id = Column("password_id", String(22), primary_key=True)
    created_at = Column("created_at", DateTime, nullable=False)
    updated_at = Column("updated_at", DateTime)
    expire_days = Column("expire_days", Integer, nullable=False)
    expire_views = Column("expire_views", Integer, nullable=False)
    viewer_deletable = Column("viewer_deletable", Boolean, nullable=False)
    views = Column("views", Integer, nullable=False)
    expire_on = Column("expire_on", DateTime, nullable=False)
    passphrase_hash = Column("passphrase_hash", String(64))
    password = Column("password", String(184), nullable=False)

    
def create_password(new_password):
    session.add(new_password)
    session.commit()
    return


def delete_password(password_id):
    delete_query = delete(Passwords).where(Passwords.password_id == password_id)
    session.execute(delete_query)
    session.commit()
    return


def get_password(password_id, route):
    try:
        password_query = select(Passwords).where(Passwords.password_id == password_id)
        data = session.execute(password_query).first()[0]
        if (route == "preview"):
            return {"expire_days": data.expire_days, "expire_views": data.expire_views, "viewer_deletable": data.viewer_deletable}
        elif (route == "access"):
            return {"passphrase_hash": data.passphrase_hash}
        elif (route == "view"):
            return data
    except TypeError:
        return None

def update_password(data):
    update_query = update(Passwords).where(Passwords.password_id == data.password_id).values({"views": data.views, "updated_at": data.updated_at})
    session.execute(update_query)
    session.commit()
    return
    
