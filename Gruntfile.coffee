
requireShim =
  underscore:
    exports: '_'
  backbone:
    exports: 'Backbone'
    deps: ['underscore']
  icanhaz:
    exports: 'ich'
  'bootstrap-button':
    deps: ['jquery']

module.exports = (grunt) ->
  STATIC_DIR = 'static'
  JS_DIR = "#{STATIC_DIR}/js"
  #VENDOR_DIR = grunt.file.readJSON '.bowerrc'

  createVendorPaths = (vendorPath, libs) ->
    paths = {}

    for lib in libs
      if 'string' is grunt.util.kindOf lib
        libName = lib
        libPath = "#{vendorPath}/#{libName}"
      else
        libName = lib.name
        libPath =
          if lib.path?
            "#{vendorPath}/#{lib.path}"
          else
            "#{vendorPath}/#{libName}"

      paths[libName] = libPath

    paths

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    bower:
      target:
        rjsConfig: "./#{JS_DIR}/config.js"

    requirejsconfig:
      dev:
        src: 'src/config.js'
        dest: '#{JS_DIR}/config.js'
        options:
          shim: requireShim
          paths: createVendorPaths 'vendor'



  # Bower-RequireJS task.
  grunt.loadNpmTasks 'grunt-bower-requirejs'

  # Shim that in here, yo!
  grunt.loadNpmTasks 'grunt-requirejs-config'

  # TASKS

  #grunt.registerTask 'default', ['bower']
  #grunt.registerTask 'production', ['bower']

  grunt.registerTask 'herp', 'derp', ->
    console.log createVendorPaths '../vendor', [
      'jquery'
      'backbone'
      'underscore'
      'icanhaz'
      { name: 'bootstrap-button', path: 'bootstrap/js/bootstrap-button' }
    ]

  

