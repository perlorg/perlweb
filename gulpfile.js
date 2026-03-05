const gulp = require('gulp');
const less = require('gulp-less');
const terser = require('gulp-terser');
const concat = require('gulp-concat');
const cleanCSS = require('gulp-clean-css');
const header = require('gulp-header');
const gulpIf = require('gulp-if');
const purgecss = require('gulp-purgecss');

const banner = '/* Perl.org - http://www.perl.org */\n';

const paths = {
  less: {
    src: 'docs/assets/less/main.less',
    dest: 'docs/static/css/',
    watch: 'docs/assets/less/**/*.less'
  },
  js: {
    src: [
      'docs/assets/js/libs/jquery-3.7.0.min.js',
      'node_modules/bootstrap/js/transition.js',
      'node_modules/bootstrap/js/collapse.js',
      'node_modules/bootstrap/js/tooltip.js',
      'docs/assets/js/main.js'
    ],
    dest: 'docs/static/js/',
    watch: 'docs/assets/js/**/*.js'
  }
};

function styles() {
  return gulp.src(paths.less.src)
    .pipe(less())
    .pipe(purgecss({
      content: ['**/*.html', '**/*.tpl', '**/*.pod', '!node_modules/**']
    }))
    .pipe(cleanCSS())
    .pipe(concat('perlweb_bootstrap.min.css'))
    .pipe(header(banner))
    .pipe(gulp.dest(paths.less.dest));
}

function scripts() {
  return gulp.src(paths.js.src)
    .pipe(gulpIf(file => !file.path.endsWith('.min.js'), terser({
      compress: {
        passes: 2,
        drop_console: true,
        dead_code: true
      },
      mangle: true,
      output: {
        comments: false,
        ascii_only: true
      }
    })))
    .pipe(concat('perlweb_bootstrap.min.js'))
    .pipe(header(banner))
    .pipe(gulp.dest(paths.js.dest));
}

function watchFiles() {
  gulp.watch(paths.less.watch, styles);
  gulp.watch(paths.js.watch, scripts);
}

const build = gulp.parallel(styles, scripts);
const watch = gulp.series(build, watchFiles);

exports.styles = styles;
exports.scripts = scripts;
exports.watch = watch;
exports.default = build;
