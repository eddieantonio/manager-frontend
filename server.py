#!/usr/bin/env python

from importd import d
import time

from copy import deepcopy
import json


# LOOK AT ALL THIS SAMPLE DATABASE!
SAMPLE_DATABASE = {
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
        "documentIDParameter": "doc",
        "applicationParameter": "batch",
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

# Sample DB!
def resetDB(*args, **kwargs):
    # yerp...
    global database
    database = deepcopy(SAMPLE_DATABASE)

# For the first time.
resetDB()

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
    'o' is for 'OPTIONS'
    """

    def withAccept(status=200):
        def accept(*args, **kwargs):
            res = d.HttpResponse(status=status)
            res['Accept'] = ', '.join(handlers.keys())
            return res
        return accept

    options = withAccept()
    methodNotAllowed = withAccept(405) # Method not allowed

    # Set default action for options.
    handlers.setdefault('OPTIONS', options)

    def decorator(func):

        # The func provided works for 'this'.
        handlers[this] = func

        def handle_request(request, *args, **kwargs):
            # Either fetch a method handler, or give back a 'method not allowed'
            handler = handlers.get(request.method, methodNotAllowed)
            return handler(request, *args, **kwargs)

        return handle_request

    return decorator

def parseJSONBody(handler):
    """
    Passes the parsed JSON body as a string.
    """
    def middleware(request, *args, **kwargs):
        try:
            resource = json.loads(request.body)
        except ValueError:
            # couldn't parse, yo!
            return d.HttpResponse(status=400)
        else:
            return handler(request, resource, *args, **kwargs)

    return middleware

@parseJSONBody
def addService(request, new_service):
    name = new_service['name']
    database[name] = new_service

    res = d.HttpResponse(status=201)
    res['Location'] = request.get_host() + '/WSManager/' + name

    return res

@parseJSONBody
def changeService(request, new_service, name):

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

        # Notify the client that the resource name has changed.
        res = d.HttpResponse(status=301) # Moved Permanantly
        res['Location'] = request.get_host() + '/WSManager/' + new_name

        return res

    # Success! Yay!
    return d.HttpResponse(status=204)

@d('/WSManager/<slug:name>')
@o(PUT=changeService)
def service(request, name=None):
    # Why doesn't Python have a lazy default method for dicts?
    if name not in database:
        return d.HttpResponse(status=404)
    else:
        return database[name]

@d('/WSManager')
@o(DELETE=resetDB, POST=addService)
def wsmanager(request):
    """
    Returns the database as JSON.
    """
    return database

