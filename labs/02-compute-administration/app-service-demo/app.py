# Script: app.py
#
# Purpose:
# Provide a minimal Flask application for Azure App Service deployment.
#
# Project:
# Azure Support Labs.
#
# Learning focus:
# Azure App Service, Python runtime, application configuration.
#
# Lifecycle:
# Temporary learning script.

import os
from flask import Flask

app = Flask(__name__)


@app.route("/")
def home():
    message = os.getenv(
        "APP_MESSAGE",
        "Azure Support Labs - App Service is running! Ola!"
    )
    return message