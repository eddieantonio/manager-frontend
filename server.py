#!/usr/bin/env python

from importd import d
import time

# LOOK AT ALL THIS SAMPLE DATABASE!
database = {
    "wikifier": {
        "name": "wikifier",
        "url": "http://noronha.nis.ualberta.ca:8801/wikifyweb",
        "documentIDParameter": "id",
        "applicationParameter": "app",
        "method": "POST",
        "parameters": []
    },
    "complex": {
        "name": "complex",
        "url": "http://noronha.nis.ualberta.ca:8801/complexreweb/complexonline",
        "documentIDParameter": "id",
        "applicationParameter": "app",
        "method": "GET",
        "parameters": []
    },
    "sonex": {
        "name": "sonex",
        "url": "http://noronha.nis.ualberta.ca:8801/sonexweb/sonexonline",
        "documentIDParameter": "id",
        "applicationParameter": "app",
        "method": "GET",
        "parameters": []
    }
}

@d('/WSManager')
def wsmanager(response):
    return database.values()

