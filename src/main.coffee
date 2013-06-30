# Service manager front-end
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



  ## Models

  # The Service: the main model of this application.
  Service = Backbone.Model.extend
    # Services use '_name' as its ID attribute.
    idAttribute: '_remoteName'

    initialize: (attributes) ->
      # Set the real name to the display name
      @attributes._remoteName = @get 'name'

    # These are a service's defaults.
    # Note that 'name' must be changed before initial save.
    defaults:
      name: ''
      method: 'POST'
      url: 'http://'
      parameters: []
      preprocess: []
      documentIDParameter: 'id'
      applicationParameter: 'app'

    # Check that the name is proper.
    validate: (attributes, options) ->
      'invalid name' unless attributes.name.match Service.nameValidationRegex
  ,
    # Basically, match a slug from 1 to 24 characters long.
    nameValidationRegex: /^[a-z][a-z0-9\-_]{0,23}$/



  # WSManager collects all of the services.
  WSManager = Backbone.Collection.extend
    model: Service
    url: '/WSManager'

    # Parse the object received from the server into a list of services.
    parse: (response) ->
      serviceList = _(response).map (partialService, name) ->
        service = _.clone partialService
        # The keys should become the 'name' attribute.
        service.name = name
        service



  ## View helper functions

  # Wraps an event handler with preventDefault
  prevent = (eventFunction) -> (event) ->
    event.preventDefault()
    eventFunction.apply @, arguments

  # Converts template returned by ich into a string.
  templateToString = (template) -> $('<div>').html(template).html()

  # Creates a control group for the named template.
  makeControlGroup = (label, controlName, options={}, extraClasses="") ->
    # Create a unique ID so that the label points to the input.
    inputID = _.uniqueId 'ctrl-'
    options.genID = inputID

    controlTemplate = ich[controlName]
    controlHTML = controlTemplate options

    # Hack to make the jQuery template into a string.
    controlAsString = templateToString controlHTML

    ich.tFormControlGroup
      labelHTML: label
      inputFor: inputID
      controls: controlAsString
      extraClasses



  ## Generic form views.

  # Just a simple text box
  # Takes an 'attr'
  TextBoxView = Backbone.View.extend
    initialize: (options) ->
      # Set the attribute to watch.
      @attr = options.attribute

      console.log options

      # I know there are other args, but whatever...
      @templateArgs = _.omit options, 'model', 'attribute', 'collection'
      @initialRender()

      # Get the text box, yo!
      @textBox = @$ 'input'

      # Bind changing the text when the model changes.
      @listenTo @model, "change:#{@attr}", =>
        @textBox.val @model.get @attr

      console.log @templateArgs

    template: 'tSimpleTextBoxControl'

    events:
      'keyup input' : -> @model.set @attr, @textBox.val()

    # Render the original element.
    initialRender: ->
      # Render the element
      opts = _(@templateArgs).extend
        initialValue: @model.get @attr
      @setElement makeControlGroup @templateArgs.label, @template, opts


  DefaultableTextBoxView = TextBoxView.extend
    initialize: ->
      # Call the ol' initialize. It will set the element.
      TextBoxView.prototype.initialize.apply @, arguments
      @button = @$ 'button'

    template: 'tDefaultableTextControl'

    events:
      'click button': 'setDefault'

    setDefault: ->
      # Grab the default from its 'data-default' attribute.
      val = @button.attr 'data-default'
      # The text-box will automatically update.
      @model.set @attr, val



  ## Views

  # Views a WSManager collection as a list.
  ServiceListView = Backbone.View.extend
    tagName: 'ul'
    className: 'service-list unstyled'

    # Track a list of services
    trackedViews: {}

    # Add an element to the tracked view.
    addElement: (service, _collection, _sync) ->

      # Make a shiny new view.
      view = new ServiceInfoView { model: service }

      # Track it and add it to the DOM
      @trackedViews[service.get 'name'] = view

      view.$el.appendTo @$el

    removeElement: (service, _collection, _sync) ->
      name = service.get 'name'
      view = @trackedViews[name]
      delete @trackedViews[name]
      view.remove()

    initialize: ->
      @listenTo @collection, "add", @addElement
      @listenTo @collection, "remove", @removeElement
      # TODO: use _.sortedIndex to insert in the proper position.
      @listenTo @collection, 'modify:_remoteName'

  # Views a Service for info at a glance.
  ServiceInfoView = Backbone.View.extend
    tagName: 'li'
    # Use Bootstrap rows.
    className: 'service-info'

    initialize: ->
      @editView = null
      @render()

      @listenTo @model, 'change', @render

    events:
      'click a[href$="/edit"]'  : 'toggleEdit'

    toggleEdit: prevent ->
      if @editView
        # Slide the view out.
        @editView.$el.slideUp
          complete: =>
            # Destroy it once the animation is complete.
            @editView.remove()
            @editView = null
      else
        @editView = new ServiceEditView { model: @model }
        @editView.$el
          .css('display', 'none')
          .insertAfter(@$el)
          .slideDown()

    render: ->
      # Replace the element's HTML with the rendered template
      rendered = ich.tServiceListItem @model.attributes
      @$el.html rendered

      @

  # Views a Service, with intent to edit it.
  ServiceEditView = Backbone.View.extend
    tagName: 'div'
    className: 'service-edit'

    initialize: ->
      @initialRender()

    events:
      'submit': 'submit'
      'click [data-close]': 'close'
    
    controls: [
      name: 'TextBoxView'
      props:
        label: 'Name',
        attribute: 'name',
        placeholder: 'Service name'
    ,
      name: 'TextBoxView'
      props:
        label: 'URL',
        attribute: 'url',
        placeholder: 'name, yo'
    ]

    # Create each element that belongs to this... thing.
    initialRender: ->
      # Create the form and its controls.
      $form = ich.tServiceForm()

      # Create actions thingy.
      $actions = $('<div>')
        .addClass('form-actions')
        .append(ich.tServiceEditActions())

      model = @model

      nameControl = new TextBoxView
        label: 'Name',
        model: @model,
        attribute: 'name',
        placeholder: 'name, yo'

      urlControl = new TextBoxView
        label: 'URL'
        model: @model
        attribute: 'url'
        placeholder: 'http://'

      $methodControl = makeControlGroup 'Method', 'tToggleButtonControl',
        options: [
          { active: yes, id: 'POST', text: 'POST' }
          { id: 'GET', text: 'GET' }
        ]

      # Doc control!
      $docControl = makeControlGroup 'Document parameter', 'tDefaultableTextControl',
        initialValue: @model.get 'documentIDParameter'
        placeholder: 'param'
        helpText: 'The parameter that the manager will use to send ' +
          'the ID of one Ludicrous document.'
      $docControl.find('input').first().on 'keyup', ->
        model.set 'documentIDParameter', $(@).val()
      @listenTo model, 'change:documentIDParameter', ->
        $docControl.find('input').val(model.get 'documentIDParameter')
      $docControl.find('button').first().on 'click', ->
        model.set 'documentIDParameter', $(@).val()

      # Append each form part
      $form.append nameControl.$el, urlControl.$el, $methodControl, $docControl
      $form.append $actions

      # Now place the entire thing in the div.
      @$el.append $form

    submit: prevent ->
      @model.save [],
        success: =>
          alert 'Saved successfully!'
        error: =>
          alert 'Error while saving! See log.'
          console.log 'Error args:', arguments

    close: ->
      alert 'You closed, yo.'




  ## The "main" function.

  # Install the service manager on an element.
  serviceManager = (elem) ->
    # Create an jQuery alias of the element.
    $elem = $ elem

    # Silently give up if the element doesn't exist.
    return if not $elem.length

    # Initialize the WSManager.
    window.herp = wsmanager = new WSManager [],
      url: '/WSManager'

    # Make the main list view.
    serviceList = new ServiceListView { collection: wsmanager }

    # Download the service list via AJAX.
    $elem.html ich.tIndefiniteLoading { title: 'Loading services...' }
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
    serviceManager $ '.service-manager'

