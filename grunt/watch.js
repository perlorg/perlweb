module.exports = function() {

var watch;

watch = {
  options: {
    spawn: false
  },
  configFiles: {
    files: [ 'Gruntfile.js', 'grunt/*.js' ],
    options: {
      reload: true
    }
  },
  css: {
    files: [ 'docs/assets/less/*.less', 'docs/assets/less/**/*.less','docs/assets/less/**/**/*.less' ],
    tasks: [ 'less' ]
  },
  js: {
    files: [ 'docs/assets/js/*.js', 'docs/assets/js/**/*.js' ],
    tasks: [ 'uglify' ]
  },
};

return watch;

};
