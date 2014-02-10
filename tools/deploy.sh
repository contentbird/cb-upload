#!/bin/bash
# Deploy script to heroku
currentBranch() {
  git branch | grep "*" | sed "s/* //"
}

safeMatchingEnvForBranch() {
  case $1 in
    "sprint") env="cbdev-upload";;
    "master") env="cb-upload";;
    *) echo "no matching env for $1"
       exit ;;
  esac
  echo "$env"
}

case $1 in
  "cbdev-upload") branch="sprint"
                  heroku_app="$1";;
  "cb-upload") branch="master"
               heroku_app="$1";;
  "") branch=$(currentBranch)
      heroku_app=$(safeMatchingEnvForBranch $(currentBranch))
      echo "No target env specified: safely deploying to $heroku_app";;
  *) echo "Choose between 'cbdev-upload' or 'cb-upload' !"
     exit ;;
esac

echo "-- Pushing $branch to $heroku_app"
git checkout $branch

if [ "$?" = "0" ]; then
  echo "-- Pushing to GitHub"
  git push origin $branch

  if [ "$?" = "0" ]; then
    echo "-- Pushing to Heroku"
    git push $heroku_app $branch:master
  fi
fi