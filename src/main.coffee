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
  require 'bootstrap-javascript' # requires jQuery...



  ## Models

  # The Service: the main model of this application.
  Service = Backbone.Model.extend
    # Services use 'name' as its ID attribute.
    idAttribute: '_remoteName'

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

    # Sort by remote name.
    comparator: '_remoteName'

    # Parse the object received from the server into a list of services.
    parse: (response) ->
      serviceList = _.map response, (partialService, name) ->
        service = _.extend partialService,
          # The keys should become the '_remoteName' attribute.
          _remoteName: name
          # Also, carry the name attribute verbatim
          name: name



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

  # Takes an 'attribute'
  GenericFormView = Backbone.View.extend
    initialize: (options) ->
      @attr = attr = options.attribute
      model = @model
      # Create a new closure that gets/and sets the fixed attribute
      @val = (newValue) ->
        if newValue
          model.set attr, newValue
        else
          model.get attr

      # I know there are other args to filter, but whatever...
      @templateArgs = _.omit options, 'model', 'attribute', 'collection'

      # Render and let parent initialize.
      @initialRender()
      @postInitialize options

    # A default, I guess. It should really be some blank template.
    template: 'tSimpleTextBoxControl'

    # Render the original element.
    initialRender: ->
      # Render the element
      opts = _(@templateArgs).extend
        initialValue: @val()
      @setElement makeControlGroup @templateArgs.label, @template, opts

    # Views should extend this. Default is no-op.
    postInitialize: ->

  # Just a simple text box
  TextBoxView = GenericFormView.extend
    template: 'tSimpleTextBoxControl'

    postInitialize: (options) ->
      # Get the text box, yo!
      @textBox = @$('input').first()

      # Bind changing the text when the model changes.
      @listenTo @model, "change:#{@attr}", =>
        @textBox.val @val()

    events:
      'keyup input' : -> @val @textBox.val()

  # A 'defaultable' text box has a 'use default' button.
  DefaultableTextBoxView = TextBoxView.extend
    template: 'tDefaultableTextControl'

    postInitialize: ->
      # Call the ol' initialize. It will set the element.
      TextBoxView.prototype.postInitialize.apply @, arguments
      @button = @$ 'button'

    events: _.extend TextBoxView.prototype.events,
      'click [data-default]': 'setDefault'

    setDefault: ->
      # Grab the default from its 'data-default' attribute.
      newVal = @button.attr 'data-default'
      # The text-box will automatically update on model set.
      @val newVal

  ToggleButtonView = GenericFormView.extend
    template: 'tToggleButtonControl'

    postInitialize: (options) ->
      # Construct an object of possible options, as given in the template args
      @toggleOpts = {}
      for opt in @templateArgs.options
        @toggleOpts[opt.id] = opt.label

      # Render will highlight the proper active element.
      @render()

      # Render on model change.
      @listenTo @model, "change:#{@attr}", @render

    events:
      'click button[data-option]' : 'setOption'

    render: ->
      # Set the correct active option from the current value.
      currentID = @val()
      unless _.has @toggleOpts, currentID
        console.warn "#{currentID} not found in options:", @toggleOpts

      @$("[data-toggle] button").removeClass 'active'
      @$("[data-toggle] button[data-option='#{currentID}']").addClass 'active'

    setOption: (event) ->
      $el = $ event.currentTarget
      newVal = $el.attr 'data-option'
      @val newVal



  ## Views

  # Views a WSManager collection as a list.
  ServiceListView = Backbone.View.extend
    tagName: 'ul'
    className: 'service-list unstyled'

    # Track a list of services
    trackedViews: {}

    sort: ->
      # Detach the elements from the DOM for a while...
      @$el.children().detach()
      # Do the sorting.
      $children = _.chain(@trackedViews)
        .pairs()
        .sortBy((e) -> e[0]) # Sort by key
        .map((e) -> e[1].$el) # Get the element
        .value()

      # Reattach to the DOM.
      @$el.append '', $children

    # Add an element to the tracked view.
    addElement: (service, _collection, _sync) ->

      # Make a shiny new view.
      view = new ServiceInfoView { model: service }

      # Track it and add it to the DOM
      @trackedViews[service.get 'name'] = view

      view.$el.appendTo @$el

      # It's a bit inefficient to sort for EVERY insert, but whatever.
      @sort()

    removeElement: (service, _collection, _sync) ->
      name = service.get 'name'
      view = @trackedViews[name]
      delete @trackedViews[name]

      # Do a stupid animation before removal.
      view.$el.slideUp
        complete: ->
          view.remove()

    initialize: ->
      @listenTo @collection, "add", @addElement
      @listenTo @collection, "remove", @removeElement
      # TODO: use _.sortedIndex to insert in the proper position.
      #@listenTo @collection, 'modify:_remoteName'

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

    showEdit: ->
      @editView = new ServiceEditView { model: @model }
      @editView.$el
        .css('display', 'none')
        .insertAfter(@$el)
        .slideDown()

    closeEdit: ->
      # Slide the view out.
      @editView.$el.slideUp
        complete: =>
          # Destroy it once the animation is complete.
          @editView.remove()
          @editView = null

    toggleEdit: prevent ->
      unless @editView then @showEdit() else @closeEdit()

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
      @listenTo @model, 'destroy', @remove

    events:
      'submit': 'submit'
      'click [data-close]': 'close'
      'click [data-delete]': 'delete'

    controls: [
      # Name input
      label: 'Name',
      class: TextBoxView
      attribute: 'name'
      placeholder: 'Service name'
    ,
      # URL input
      label: 'URL'
      class: TextBoxView
      attribute: 'url'
      placeholder: 'http://'
    ,
      # Method toggle
      label: 'Method'
      class: ToggleButtonView
      attribute: 'method'
      options: [
        { id: 'POST', label: 'POST' }
        { id: 'GET', label: 'GET' }
      ]
    ,
      # ?id=
      label: 'Document Parameter'
      class: DefaultableTextBoxView
      attribute: 'documentIDParameter'
      placeholder: 'Parameter'
      defaultValue: 'id'
      helpText: 'The parameter that the manager will use to send ' +
        'the ID of one Ludicrous document.'
    ,
      # ?app=
      label: 'Application Parameter'
      class: DefaultableTextBoxView
      attribute: 'applicationParameter'
      placeholder: 'Parameter'
      defaultValue: 'app'
      helpText: 'The parameter that the manager will use to ' +
        'send the name of an entire Ludicrous application.'

      # Still need controls for parameters
      # and preprocessors
    ]

    # From the given controls in @controls, creates them
    # Returns the list of controls.
    makeControls: ->
      # Instantiate all of the controls.
      @controlInstances = for props in @controls
        # Make a copy of the props with our model.
        newProps = _.extend props,
          model: @model

        # "Pop" the class property from new props.
        cls = newProps.class

        # Instantiate!
        control = new cls newProps


    # Create each element that belongs to this... thing.
    initialRender: ->
      # Create the form and its controls.
      $form = ich.tServiceForm()

      # Create actions thingy.
      $actions = $('<div>')
        .addClass('form-actions')
        .append(ich.tServiceEditActions())

      controls = @makeControls()

      # Append each form part.
      $form.append '', _.pluck controls, '$el'

      # And the form actions.
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

    delete: ->
      # Confirm delete, yo!
      msg = 'Are you sure you want to delete this service? This ' +
        'action cannot be undone.'
      return unless confirm msg

      @model.destroy().then ->
        true # Don't really need to do anything.
      , ->
        alert 'Could not delete model!'

    close: -> false




  ## The "main" function.

  # Install the service manager on an element.
  serviceManager = (elem) ->
    # Create an jQuery alias of the element.
    $elem = $ elem

    # Silently give up if the element doesn't exist.
    return if not $elem.length

    # Initialize the WSManager.
    window.col = wsmanager = new WSManager [],
      url: '/WSManager'

    # Show a loading... thing.
    $elem.html ich.tIndefiniteLoading { title: 'Loading services...' }

    # Make the main list view.
    serviceList = new ServiceListView { collection: wsmanager }

    # Fetch the service list.
    jqxhr = wsmanager.fetch()

    # Add the service list to the element upon the initial loaded.
    jqxhr.done ->
      # Append the view to the DOM.
      $elem
        .empty()
        .append serviceList.$el

    # Or display an error on error.
    jqxhr.fail (_, textStatus) ->
      $elem.text "Error! Status #{textStatus}."




  # On Document ready...
  $ ->
    # Ensure that the templates are loaded.
    ich.grabTemplates()
    # Install the service manager in its element.
    serviceManager $ '.service-manager'

