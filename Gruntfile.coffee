
requireShim =
  underscore:
    exports: '_'
  backbone:
    exports: 'Backbone'
    deps: ['jquery', 'underscore']
  icanhaz:
    exports: 'ich'
  'bootstrap-button':
    deps: ['jquery']

requireLibs = [
  'jquery', 'backbone', 'underscore', 'icanhaz',
  { name: 'icanhaz', path: 'icanhas/ICanHaz' }
  { name: 'bootstrap-button', path: 'bootstrap/js/bootstrap-button' }
]

module.exports = (grunt) ->
  STATIC_DIR = 'static'
  JS_DIR = "#{STATIC_DIR}/js"

  createVendorPaths = (vendorPath, libs) ->
    paths = {}

    for lib in libs
      if 'string' is grunt.util.kindOf lib
        libName = lib
        libPath = "#{vendorPath}/#{libName}/#{libName}"
      else
        libName = lib.name
        libPath = "#{vendorPath}/#{lib.path}"

      paths[libName] = libPath

    paths

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    bowerrc: grunt.file.readJSON '.bowerrc'

    requirejsconfig:
      dev:
        src: "#{JS_DIR}/app.configless.js"
        dest: "#{JS_DIR}/app.js"
        options:
          shim: requireShim
          paths: createVendorPaths '../vendor', requireLibs

    shell:
      # Make hard links to Bootstrap icon sprites.
      'copy-icons':
        command: 'ln <%= bowerrc.directory %>/bootstrap/img/*.png static/img/'

  grunt.loadNpmTasks 'grunt-requirejs-config'
  grunt.loadNpmTasks 'grunt-shell'

  # TASKS
  grunt.registerTask 'default', ['test-grunt']
  grunt.registerTask 'test-grunt', []
  grunt.registerTask 'setup', ['requirejsconfig:dev']
  #grunt.registerTask 'production', ['bower']


