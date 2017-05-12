module.exports = function() {

var uglify;

uglify = {
  options: {
    banner: '<%= banner %>',
    codegen: { ascii_only: true },
    report: 'min',
    sourceMap: false,
    preserveComments: false,
    //sourceMapIncludeSources: true,
  },
  main: {
    src: [
      'docs/assets/js/libs/jquery-1.12.3.min.js',
      'docs/assets/js/libs/bootstrap.min.js',
      'docs/assets/js/main.js',
    ],
    dest: 'docs/static/js/perlweb_bootstrap.min.js'
  },
};

return uglify;

};
