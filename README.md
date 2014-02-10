# ContentBird Upload - Image processing module of contentbird.com

## Description
A node.js server designed to resize avatar images without using contentbird ruby dynos.

## Installation
* Get the code : `git clone git@github.com:contentbird/cb-upload.git`
* Install Node.js & Npm: Mac OS X users get .pkg from [here](http://nodejs.org/dist/latest/), Linux users use this [link](http://gist.github.com/579814)
* Download & install node dependencies : `npm install`
* Install foreman : `gem install foreman`

## Run example on local server
* Create .env file at root with followning content
``` shell
S3_KEY=<your_s3_key>
S3_SECRET=<your_s3_secret>
IMAGE_BUCKET=<avatar_bucket>
```

* Run the server in terminal
``` shell
foreman start
```

## Dev & test
* Create Run the server in one terminal
``` shell
foreman start
```

* Run coffeescript
``` shell
coffee -c -w -o lib/ src/
```

* Run test (notice -t param to set timeout as integration tests can take time)
``` shell
./node_modules/mocha/bin/mocha -w -t 10000 spec --compilers coffee:coffee-script spec/*
```

## Deploy

* Add required remotes (or use tools/git_config.txt)
``` shell
git remote add cbdev-upload git@heroku.com:cbdev-upload.git
git remote add cb-upload git@heroku.com:cb-upload.git
```

* Run deploy script
``` shell
sh ./tools/deploy.sh cbdev-upload
```
You can add the following lines to your .bashrc (Linux) or .bash_profile (Max OSX):
``` shell
alias deploy='./tools/deploy.sh'
chmod +x ./tools/deploy.sh
```
and now you can deploy to the server matching your current branch in one word :)
``` shell
deploy
```