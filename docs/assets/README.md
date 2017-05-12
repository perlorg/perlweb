# CSS & JS editing

Want to edit CSS or Javascript in this repo? You can refer to [Grunt's get started page](https://gruntjs.com/getting-started) or follow the super quick and easy instructions below!

## First things first
Say hi to [Grunt](https://gruntjs.com), a task runner that automates minification, compilation, unit testing, linting and much more. We're using Grunt to compile this repo's source .js and .less into minified .js and .css files.

The tasks we're currently automating can be found in our [Gruntfile.js](../../Gruntfile.js) and the project configuration and devDependencies in our [package.json](../../package.json).


## Installing Grunt

- Make sure npm is updated:

```npm update -g npm```

- Install grunt's command line interface (CLI) – you may need to use sudo:

```npm install -g grunt-cli```

This will put the grunt command in your system path, allowing it to be run from any directory.

## Installing the plugins in use
In order to edit CSS and Javascript in this repo, you'll need to install the grunt plugins in use simply by:

- Changing to the project's root directory.
- Installing project dependencies with ```npm install```.
- Run Grunt with ```grunt``` from your command line.

Ready? Now let's get to work!

## You can run grunt automatically (recommended)
Just run ```grunt watch``` from your command line once, before editing any .less or .js files. This will run predefined tasks whenever watched file patterns are added, changed or deleted.

## Or manually
You can just run ```grunt``` from your command line anytime you make changes to .less or .js files in the assets folder.

Also, all plugins can be run separately, so if you don't want to go through all grunt tasks every time you change a file,  you can just run ```grunt less``` if you changed .less files or ```grunt uglify``` for .js files.


## Plugins already in use

We use **grunt-contrib-less** to minify .less files. All things this plugin does can be found in the [grunt/less.js](../../grunt/less.js) file. You can also refer to the [plugin documentation](https://github.com/gruntjs/grunt-contrib-less).


We use **grunt-contrib-uglify** to concat and minify .js files. All things this plugin does can be found in the [grunt/uglify.js](../../grunt/uglify.js) file. You can also refer to the [plugin documentation](https://github.com/gruntjs/grunt-contrib-uglify).

We use **grunt-contrib-watch** to watch for changes on folders/files. All things this plugin does can be found in the [grunt/watch.js](../../grunt/watch.js) file. You can also refer to the [plugin documentation](https://github.com/gruntjs/grunt-contrib-watch).


## New plugins
There are [many plugins to help automate all sorts of things](https://gruntjs.com/plugins). After you found the one you can't live without - in our example [JSHint](http://jshint.com/) - just run:

```npm install grunt-contrib-jshint --save-dev```

This way the plugin will be installed and added to the devDependencies section of [package.json](../../package.json).

## Bonus

 - Getting started with [Less](http://lesscss.org/)
 - Getting started with [Bootstrap v3.3.6](http://bootstrapdocs.com/v3.3.6/docs/getting-started/)
