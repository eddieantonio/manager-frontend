# Gruntfile!

STATIC_DIR = 'static'
JS_DIR = "#{STATIC_DIR}/js"

module.exports = (grunt) ->

  utils = require('./gruntutils')(grunt)

  jadeFiles =
    'static/index.html': 'index.jade'
  lessFiles =
    'static/style/styles.css': 'static/style/styles.less'


  grunt.initConfig
    #pkg: grunt.file.readJSON 'package.json'
    bowerrc: grunt.file.readJSON '.bowerrc'

    coffee:
      other:
        options:
          bare: yes
          sourceMap: yes
        files:
          # Requires 'requirejsconfig' to actually work.
          'static/js/app.configless.js': 'src/app.coffee'
      compile:
        options:
          bare: yes
        files:
          'static/js/main.js': 'src/main.coffee'

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
          compress: yes
        files: lessFiles

    watch:
      scripts:
        files: ['src/main.coffee']
        tasks: ['coffee:compile']
      jade:
        files: ['index.jade']
        tasks: ['jade:development']
      less:
        files: ['styles/style/*.less']
        tasks: ['less:development']

    requirejsconfig:
      dev:
        src: "#{JS_DIR}/app.configless.js"
        dest: "#{JS_DIR}/app.js"
        options:
          shim: utils.requireShim
          paths: utils.createVendorPaths '../vendor'

    shell:
      # Make hard links to Bootstrap icon sprites.
      'copy-icons':
        command: 'ln <%= bowerrc.directory %>/bootstrap/img/*.png static/img/'

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-jade'
  grunt.loadNpmTasks 'grunt-contrib-less' # This mod is actually pretty dang nifty.
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-requirejs-config'
  grunt.loadNpmTasks 'grunt-shell'

  # TASKS
  grunt.registerTask 'default', ['setup']
  grunt.registerTask 'compile', ['coffee:compile']
  grunt.registerTask 'prod-assets', ['jade:production', 'less:production']
  grunt.registerTask 'dev-assets', ['jade:development', 'less:development']
  grunt.registerTask 'setup', ['coffee:other', 'requirejsconfig', 'shell']
  grunt.registerTask 'production', ['prod-assets'] # Also, r.js stuff.


