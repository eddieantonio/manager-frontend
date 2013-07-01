# Other junk used in the Gruntfile.

module.exports = (grunt) ->

  requireLibs = [
    'jquery', 'backbone', 'underscore', 'icanhaz',
    { name: 'icanhaz', path: 'icanhas/ICanHaz' }
    { name: 'bootstrap-button', path: 'bootstrap/js/bootstrap-button' }
  ]

  # Export module

  createVendorPaths: (vendorPrefix) ->
    libs = requireLibs
    paths = {}

    for lib in libs
      if 'string' is grunt.util.kindOf lib
        libName = lib
        libPath = "#{vendorPrefix}/#{libName}/#{libName}"
      else
        libName = lib.name
        libPath = "#{vendorPrefix}/#{lib.path}"

      paths[libName] = libPath

    paths

  requireShim:
    underscore:
      exports: '_'
    backbone:
      exports: 'Backbone'
      deps: ['jquery', 'underscore']
    icanhaz:
      exports: 'ich'
    'bootstrap-button':
      deps: ['jquery']


