# Gruntfile!

STATIC_DIR = 'static'
JS_DIR = "#{STATIC_DIR}/js"

module.exports = (grunt) ->

  utils = require('./gruntutils')(grunt)

  jadeFiles =
    'static/index.html': 'index.jade'
  lessFiles =
    'static/style/styles.css': 'static/style/styles.less'

  configFile = "#{JS_DIR}/app.js"

  requireConfig =
    shim: utils.requireShim
    paths: utils.createVendorPaths '../vendor'

  grunt.initConfig
    #pkg: grunt.file.readJSON 'package.json'
    bowerrc: grunt.file.readJSON '.bowerrc'
    dirname: __dirname

    coffee:
      options:
        bare: yes
      compile:
        options:
          sourceMap: yes
        expand: yes
        cwd: 'src'
        src: ['**/*.coffee', '!app.coffee']
        dest: "#{JS_DIR}/"
        ext: '.js'
      other:
        # Requires 'requirejsconfig' to actually work.
        src: 'src/app.coffee'
        dest: "#{JS_DIR}/app.configless.js"

    jade:
      production:
        files: jadeFiles
      development:
        options:
          pretty: yes
        files: jadeFiles

    less:
      development:
        files: lessFiles
      production:
        options:
          yuicompress: yes
        files: lessFiles

    watch:
      scripts:
        files: ['src/*.coffee', '!src/app.coffee']
        tasks: ['coffee:compile']
      jade:
        files: ['index.jade']
        tasks: ['jade:development']
      less:
        files: ['static/style/*.less']
        tasks: ['less:development']

    requirejs:
      # Use the given config.
      options: requireConfig
      compile:
        options:
          baseUrl: './static/js' # So that the static paths work right.
          name: './app'
          out: "./static/js/app.js"

    requirejsconfig:
      dev:
        src: "#{JS_DIR}/app.configless.js"
        dest: "#{JS_DIR}/app.js"
        options: requireConfig

    shell:
      # Make hard links to Bootstrap icon sprites.
      'copy-icons':
        command: 'ln <%= bowerrc.directory %>/bootstrap/img/*.png static/img/'

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-jade' # This mod is actually pretty dang nifty.
  grunt.loadNpmTasks 'grunt-contrib-less'
  grunt.loadNpmTasks 'grunt-contrib-requirejs'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-requirejs-config'
  grunt.loadNpmTasks 'grunt-shell'

  # TASKS
  grunt.registerTask 'default', ['setup']
  grunt.registerTask 'compile', ['coffee']
  grunt.registerTask 'prod-assets', ['jade:production', 'less:production']
  grunt.registerTask 'dev-assets', ['jade:development', 'less:development']
  grunt.registerTask 'setup-base', ['compile', 'requirejsconfig', 'shell']
  grunt.registerTask 'setup', ['setup-base', 'dev-assets']
  grunt.registerTask 'production', ['setup-base', 'prod-assets', 'requirejs']


