module.exports = function() {

  var less;

  less = {
    options: {
        compress : true,
        sourceMap: false,
    },
    style: {
      files: {
        'docs/static/css/perlweb_bootstrap.min.css': 'docs/assets/less/main.less'
      }
    },
  };

  return less;

};
