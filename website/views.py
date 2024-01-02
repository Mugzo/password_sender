from flask import Blueprint, render_template, request, redirect, url_for, flash, session
import uuid
import base64
from cryptography.fernet import Fernet
from datetime import datetime, timedelta

from .helpers import hash_password
from .sql import Passwords, create_password, delete_password, get_password, update_password
from . import encryptionKey

views = Blueprint('views', __name__)

@views.route('/', methods=['GET'])
def home():
    return render_template("home.html")


@views.route('/create', methods=['GET','POST'])
def create():
    if request.method == "GET":
        return render_template('404.html'), 404
    elif request.method == "POST":
        # Get the form values
        password = request.form.get("passwordFormInput")
        expirationDays = request.form.get('daysRange')
        expirationViews = request.form.get('viewsRange')
        allowDeletion = request.form.get('deletionCheck') != None
        passphrase = request.form.get('passphraseFormInput')

        # Create a unique string for url_for
        password_id = str(base64.urlsafe_b64encode(uuid.uuid4().bytes)).lstrip("b'").rstrip("='")

        # Encrypt the password
        fernet = Fernet(encryptionKey)
        encrypted_password = fernet.encrypt(password.encode())

        decrypted_password = fernet.decrypt(encrypted_password).decode()

        # Hash the passphrase
        if passphrase != '':
            passphrase_hash = hash_password(passphrase)
        else:
            passphrase_hash = None

        # Time of create
        now = datetime.now()
        expirationDate = now + timedelta(days=int(expirationDays))

        # Create the password in the database
        new_password = Passwords(password_id=password_id, created_at=now, expire_days=expirationDays, expire_views=expirationViews, viewer_deletable=allowDeletion,  views=0, expire_on=expirationDate, passphrase_hash=passphrase_hash, password=encrypted_password)
        create_password(new_password)

        return redirect(url_for('views.preview', password_id=password_id))
    return render_template('404.html'), 404


@views.route('/preview/<password_id>', methods=['GET'])
def preview(password_id):
    data = get_password(password_id, "preview")

    if (data is None):
        return render_template('404.html'), 404
    else:
        expire_days = data["expire_days"]
        expire_views = data["expire_views"]
        viewer_deletable = "can" if data["viewer_deletable"] else "cannot"
        return render_template("preview.html", password_id=password_id, expire_days=expire_days, expire_views=expire_views, viewer_deletable=viewer_deletable)
    return render_template('404.html'), 404


@views.route('/view/<password_id>', methods=['GET'])
def password(password_id):
    data = get_password(password_id, "view")
    if (data is None):
        return render_template('404.html'), 404

    now = datetime.now()

    if (data.expire_on < now):
        delete_password(password_id)
        return render_template('404.html'), 404
    elif (data.passphrase_hash != None and session["passphrase"] != True):
        return redirect(url_for('views.passphrase', password_id=password_id))
    else:
        session["passphrase"] = False
        data.views += 1
        if (data.views >= data.expire_views):
            delete_password(password_id)
        else:
            data.updated_at = now
            update_password(data)
        
        fernet = Fernet(encryptionKey)
        decrypted_password = decrypted_password = fernet.decrypt(data.password).decode()

        # Calculate the number of days left, 86400 seconds = 1 day
        expire_days = round((data.expire_on - now).total_seconds() / 86400)

        # Calculate the number of views left
        expire_views = data.expire_views - data.views

        return render_template('password.html', password_id=password_id, password=decrypted_password, expire_days=expire_days, expire_views=expire_views, viewer_deletable=data.viewer_deletable)
    return render_template('404.html'), 404

@views.route('/passphrase/<password_id>', methods=['GET'])
def passphrase(password_id):
    return render_template('passphrase.html', password_id=password_id)


@views.route('/access/<password_id>', methods=['GET', 'POST'])
def access(password_id):
    if request.method == "GET":
        return render_template('404.html'), 404
    elif request.method == "POST":
        data = get_password(password_id, "access")
        if (data is None):
            return render_template('404.html'), 404

        passphrase = request.form.get("passphrase")

        if (data["passphrase_hash"] == hash_password(passphrase)):
            session["passphrase"] = True
            return redirect(url_for('views.password', password_id=password_id))
        else:
            flash("That passphrase is incorrect. Please try again or contact the person or organization that sent you this link.")
            return redirect(url_for('views.passphrase', password_id=password_id))
    return render_template('404.html'), 404


@views.route('/delete/<password_id>', methods=['GET', 'POST'])
def delete(password_id):
    if request.method == "GET":
        return render_template('404.html'), 404
    elif request.method == "POST":
        print('Hello')
        delete_password(password_id)
        return redirect(url_for("views.home"))
    return render_template('404.html'), 404