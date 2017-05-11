Want to edit CSS or Javascript in perl.org sites? You can refer to [Grunt's get started page](https://gruntjs.com/getting-started) or follow the usper quick and easy instructions below :)

###First things first
Say hi to Grunt, a task runner to automate minification, compilation, unit testing, linting and much more.
We're using Grunt to compile this repo's source .js and .less into minified .js and .css files.
The tasks we're currently automating can be found in Gruntfile.js and our project configuration and devDependencies in package.json.


###Installing Grunt

First, update npm
```npm update -g npm```


Then, install the CLI (you may need to use sudo)
```npm install -g grunt-cli```
This will put the grunt command in your system path, allowing it to be run from any directory.

###Installing the plugins
For automating our tasks we use a few grunt plugins (less, uglify and watch). You'll find explanations about those plugins below. In order to edit css and js in this repo, you'll need to install the plugins simply by:

- Change to the project's root directory.
- Install project dependencies with npm install.
- Run Grunt with ```grunt```

###Running grunt automatically (recommended)
Just run ```grunt watch``` from your command line. This will run predefined tasks whenever watched file patterns are added, changed or deleted. So if you make a change to any of the .less or .js assets, grunt will run automatically.

###Running grunt manually
After all is installed and working, you can just run ```grunt``` from your command line every time you make a change to css or js files in the assets folder. This way, the new minified files will be created in the correct public folder.

All plugins can be run separately, so if you don't want to go through all grunt tasks every time you change a file – it could take a while if you have too many assets –,  you can run just ```grunt less``` for .less files or ```grunt uglify``` for .js files.


###You're ready to go
If you are changing .less or .js files and your changes are not taking effect, it could be that you didn't ```grunt watch``` before editing the files and didn't manually run ```grunt``` either.


###Extra: Plugins configuration

We use *grunt-contrib-less* to minify .less files. All things this plugin does can be found in the grunt/less.js file. You can also refer to the [plugin documentation](https://github.com/gruntjs/grunt-contrib-less).


We use *grunt-contrib-uglify* to concat and minify .js files. All things this plugin does can be found in the grunt/uglify.js file. You can also refer to the [plugin documentation](https://github.com/gruntjs/grunt-contrib-uglify).

We use *grunt-contrib-watch* to watch for changes on folders/files. All things this plugin does can be found in the grunt/watch.js file. You can also refer to the [plugin documentation](https://github.com/gruntjs/grunt-contrib-watch).


###If you need to install a new plugin
There are [many plugins to help automate all sorts of things](https://gruntjs.com/plugins). After you found the one you can't live without, just run
```npm install grunt-contrib-jshint --save-dev```

This way, the plugin will be installed and added to the devDependencies section of package.json.

###Bônus
