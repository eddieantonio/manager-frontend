# Services front-end
# ALL IN ONE FILE!
# Author: Eddie Antonio Santos <easantos@ualberta.ca>



define (require) ->
  # Libaries needed, by name.
  $ = require 'jquery'
  Backbone = require 'backbone-amd'


  # Need to use its global...
  require 'icanhaz'         # ich
  require 'underscore-amd'  # _
  
  # Libraries that should just exist on the page.
  require 'bootstrap-javascript'
  
  # The Service: the main model of this application.
  Service = Backbone.Model.extend
    # Services use 'name' as its ID attribute
    idAttribute: 'name'
    # These are a service's defaults.
    # Note that 'name' must be changed before initial save.
    defaults:
      name: ''
      method: 'POST'
      url: 'http://'
      parameters: []
      documentIDParameter: 'id'
      applicationParameter: 'app'


  # WSManager collects all of the services.
  WSManager = Backbone.Collection.extend
    model: Service
    url: '/WSManager'

  

  # Views a WSManager collection as a list.
  ServiceListView = Backbone.View.extend
    tagName: 'ul'
    className: 'service-list unstyled'

    # Keep a list of services
    trackedViews: {}

    # Add an element to the tracked view.
    addElement: (service, _collection, _sync) ->

      # Make a shiny new view.
      view = new ServiceInfoView { model: service }

      # Track it and add it to the DOM
      @trackedViews[service.get 'name'] = view
      view.$el.appendTo @$el

      @

    removeElement: (service, _collection, _sync) ->
      name = service.get 'name'
      view = @trackedViews[name]
      delete @trackedViews[name]
      view.remove()

    initialize: ->
      @listenTo @collection, "add", @addElement
      @listenTo @collection, "remove", @removeElement



  # Helper to create a control group from the named template.
  makeControlGroup = (label, controlName, options={}, extraClasses="") ->
    # Create a unique ID so that the label points to the input.
    inputID = _.uniqueId 'cnt-'
    options.genID = inputID

    controlTemplate = ich[controlName]
    controlHTML = controlTemplate options

    console.log controlHTML
    window.herp = controlHTML

    # Hack to make the jQuery template into a string.
    controlAsString = $('<div>').html(controlHTML).html()

    ich.tFormControlGroup
      labelHTML: label
      inputFor: inputID
      controls: controlAsString
      extraClasses
      

  # Views a Service for info at a glance.
  ServiceInfoView = Backbone.View.extend
    tagName: 'li'
    # Use Bootstrap rows.
    className: 'service-info'

    initialize: ->
      @render()
      @listenTo @model, 'change', @render

    render: ->
      # Replace the element's HTML with the rendered template
      rendered = ich.tServiceListItem @model.attributes
      @$el.html rendered

      @

  

  # Install the service manager on an element.
  serviceManager = (elem) ->
    # Create an jQuery alias of the element.
    $elem = $ elem

    # Silently give up if the element doesn't exist.
    return if not $elem.length

    # Initialize the WSManager.
    wsmanager = new WSManager [],
      url: '/WSManager'

    # Make the main list view.
    serviceList = new ServiceListView { collection: wsmanager }

    # Download the service list via AJAX.
    $elem.html ich.tIndefiniteLoading { title: 'Loading services...' }
    #jqxhr = wsmanager.sync 'read', wsmanager
    jqxhr = wsmanager.fetch()

    # Add the service list to the element upon the initial loaded.
    jqxhr.done ->
      $elem.empty()
      serviceList.$el.appendTo $elem

    # Or display an error on error.
    jqxhr.fail (_, textStatus) ->
      $elem.text "Error! Status #{textStatus}."

  

  # On Document ready...
  $ ->
    # Install the service manager in its element.
    #serviceManager $ '.service-manager'

    # Test the helper function
    fakeControl = makeControlGroup 'Label!', 'tSimpleTextBoxControl',
      name: 'txtbx'
      placeholder: 'Text box!'
    $('article').append fakeControl
    
