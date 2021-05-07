import os
from flask import Flask
import requests
app = Flask(__name__)

@app.route("/")
def hello_world():
    env_name = os.environ.get("NAME")
    return f"Hello world again from {env_name}"

@app.route("/about")
def about_us():
    return "This this about us"


@app.route("/another")
def another_view():
    return "Yet another route"


@app.route("/lookup")
def lookup_view():
    r = requests.get("http://raspberrypi")
    return r"STATUS {r.status_code}"

if __name__=="__main__":
    app.run(host="0.0.0.0", port=8000)