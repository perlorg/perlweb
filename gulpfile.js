const gulp = require('gulp');
const sass = require('gulp-sass')(require('sass'));
const terser = require('gulp-terser');
const concat = require('gulp-concat');
const cleanCSS = require('gulp-clean-css');
const header = require('gulp-header');
const gulpIf = require('gulp-if');
const purgecss = require('gulp-purgecss');

const banner = '/* Perl.org - http://www.perl.org */\n';

const paths = {
  scss: {
    src: 'docs/assets/scss/main.scss',
    dest: 'docs/static/css/',
    watch: 'docs/assets/scss/**/*.scss'
  },
  js: {
    src: [
      'node_modules/@popperjs/core/dist/umd/popper.min.js',
      'node_modules/bootstrap/dist/js/bootstrap.min.js',
      'docs/assets/js/main.js'
    ],
    dest: 'docs/static/js/',
    watch: 'docs/assets/js/**/*.js'
  }
};

function styles() {
  return gulp.src(paths.scss.src)
    .pipe(sass({
      includePaths: ['node_modules'],
      quietDeps: true
    }).on('error', sass.logError))
    .pipe(purgecss({
      content: ['**/*.html', '**/*.tpl', '**/*.pod', '!node_modules/**'],
      safelist: {
        standard: [/^nav-/, /^navbar-/, /^dropdown-/, /^collapse/, /^show/, /^btn-/, /^col-/, /^d-/, /^tagcloud/, /^sub/, /^selected/]
      }
    }))
    .pipe(cleanCSS())
    .pipe(concat('perlweb_bootstrap.min.css'))
    .pipe(header(banner))
    .pipe(gulp.dest(paths.scss.dest));
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
  gulp.watch(paths.scss.watch, styles);
  gulp.watch(paths.js.watch, scripts);
}

const build = gulp.parallel(styles, scripts);
const watch = gulp.series(build, watchFiles);

exports.styles = styles;
exports.scripts = scripts;
exports.watch = watch;
exports.default = build;
