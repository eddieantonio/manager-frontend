#!/usr/bin/env python

from importd import d
import time

# LOOK AT ALL THIS SAMPLE DATABASE!
database = {
    # The name should be derived from the key.
    "wikifier": {
        # URL of the service on our intranet
        "url": "http://noronha.nis.ualberta.ca:8801/wikifyweb",
        # Parameter used to ingest IDs
        "documentIDParameter": "id",
        # Parameter used to ingest applications.
        "applicationParameter": "app",
        # HTTP method used for requests
        "method": "POST",
        # Any extra parameters the service might take.
        "parameters": [],
        # Service used to preprocess the full-text.
        # For example, many services require NLP preprocessing.
        "preprocess": ["nlp"]
    },

    "complex": {
        "url": "http://noronha.nis.ualberta.ca:8801/complexreweb/complexonline",
        "documentIDParameter": "id",
        "applicationParameter": "app",
        "method": "GET",
        "parameters": [],
        "preprocess": ["nlp"]
    },

    "sonex": {
        "url": "http://noronha.nis.ualberta.ca:8801/sonexweb/sonexonline",
        "documentIDParameter": "id",
        "applicationParameter": "app",
        "method": "GET",
        "parameters": [],
        "preprocess": ["nlp"]
    },

    "sentiment": {
        "url": "http://localhost:8000",
        "documentIDParameter": "id",
        "applicationParameter": "app",
        "method": "POST",
        "parameters": [],
        "preprocess": ["nlp"]
    },

    "nlp": {
        "url": "http://localhost:8000",
        "documentIDParameter": "id",
        "applicationParameter": "app",
        "method": "POST",
        "parameters": [],
        "preprocess": []
    },

    "classifier": {
        "url": "http://noronha.nis.ualberta.ca:8801/complexreweb/complexonline",
        "documentIDParameter": "id",
        "applicationParameter": "app",
        "method": "GET",
        "parameters": [],
        "preprocess": []
    }

}

@d('/WSManager')
def wsmanager(response):
    return database

