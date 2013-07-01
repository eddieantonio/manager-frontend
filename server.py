#!/usr/bin/env python

from importd import d

import time
import json

from collections import defaultdict
from copy import deepcopy

def default_service(**kwargs):
    d = {
        # URL of the service on our internal servers.
        "url": "http://noronha.nis.ualberta.ca:8801/wikifyweb",
        # Parameter used to ingest IDs.
        "documentIDParameter": "id",
        # Parameter used to ingest applications.
        "applicationParameter": "app",
        # HTTP method used for requests.
        "method": "POST",
        # Any extra parameters the service might take.
        "parameters": [],
        # Services used to preprocess the full-text.
        # For example, many services require NLP preprocessing.
        "preprocess": []
    }
    d.update(kwargs)
    return d

# LOOK AT ALL THIS SAMPLE DATABASE!
SAMPLE_DATABASE = {
    # The name should be derived from the key.
    "wikifier": default_service(
        url="http://noronha.nis.ualberta.ca:8801/wikifyweb",
        preprocess=["nlp"]
    ),

    "complex": default_service(
        url="http://noronha.nis.ualberta.ca:8801/complexreweb/complexonline",
        method="GET",
        preprocess=["nlp"]
    ),

    "sonex": default_service(
        url="http://noronha.nis.ualberta.ca:8801/sonexweb/sonexonline",
        method="GET",
        preprocess=["nlp"]
    ),

    "sentiment": default_service(
        url="http://localhost:8000",
        method="POST",
        preprocess=["nlp"]
    ),

    "nlp": default_service(
        url="http://localhost:8000",
        documentIDParameter="doc",
        applicationParameter="batch",
        method="POST"
    ),

    "classifier": default_service(
        url="http://noronha.nis.ualberta.ca:8801/complexreweb/complexonline",
        method="GET"
    )

}

# Sample DB!
def reset_db(request=None, *args, **kwargs):
    # yerp...
    global database
    database = deepcopy(SAMPLE_DATABASE)

    if request:
        return d.HttpResponse(status=204)

# For the first time.
reset_db()

# Django configuration:
d(
    MIDDLEWARE_CLASSES = (
        'django.middleware.common.CommonMiddleware',
        'django.contrib.sessions.middleware.SessionMiddleware',
        'django.contrib.messages.middleware.MessageMiddleware',
    )
)

def o(this='GET', **handlers):
    """
    'o' is for 'OPTIONS'. Decorates a function that with OPTIONS, providing
    pointers to other method request handlers.
    """

    def with_accept(status=200):
        def accept(*args, **kwargs):
            res = d.HttpResponse(status=status)
            res['Accept'] = ', '.join(handlers.keys())
            return res
        return accept

    options = with_accept()
    method_not_allowed = with_accept(405) # Method not allowed

    # Set default action for options.
    handlers.setdefault('OPTIONS', options)

    def decorator(func):
        # The func provided works for 'this'.
        handlers[this] = func

        def handle_request(request, *args, **kwargs):
            # Either fetch a method handler, or give back a 'method not allowed'
            handler = handlers.get(request.method, method_not_allowed)
            return handler(request, *args, **kwargs)

        return handle_request

    return decorator

def parse_json_body(handler):
    """
    Passes the parsed JSON body as a string.
    """
    def middleware(request, *args, **kwargs):
        try:
            resource = json.loads(request.body)
        except ValueError:
            # Couldn't parse, yo!
            return d.HttpResponse('Invalid JSON', status=400)
        else:
            return handler(request, resource, *args, **kwargs)

    return middleware

def created_response(request, name):
    res = d.HttpResponse(status=201)
    res['Location'] = request.build_absolute_uri('/WSManager/%s' % name)

    return res

@parse_json_body
def add_service(request, new_service):
    try:
        name = new_service['name']
    except KeyError:
        return d.HttpResponse('Needs a "name" attribute.', status=404)
    database[name] = new_service

    return created_response(request, name)

def delete_service(request, name):
    if name not in database:
        return d.HttpResponse(status=404)

    # Delete it!
    del database[name]
    return d.HttpResponse(status=204)


@parse_json_body
def change_service(request, new_service, name):

    if name not in database:
        return d.HttpResponse(status=400)

    old_service = database[name]
    new_name = new_service['name']

    # Set the value
    database[new_name] = new_service

    # TODO: (maybe) make sure we're not clobbering some other name.
    if new_name != old_service['name']:
        # Must rename (that is, remove) the old service.
        # It'd be nice if this was transactional but... whatever.
        del database[name]

        # Notify the client that the resource has been created
        # under a new name.
        return created_response(request, new_name)

    # Success! Yay!
    return d.HttpResponse(status=204)

@d('/WSManager/<slug:name>')
@o(PUT=change_service, DELETE=delete_service)
def service(request, name=None):
    # Why doesn't Python have a lazy default method for dicts?
    if name not in database:
        return d.HttpResponse(status=404)
    else:
        return database[name]

@d('/WSManager')
@o(DELETE=reset_db, POST=add_service)
def wsmanager(request):
    """
    Returns the database as JSON.
    """
    return database

