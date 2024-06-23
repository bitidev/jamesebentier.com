#!/usr/bin/env sh

mode=$1

case $mode in
    "json") yaml2json resume.yml -p;;
    "serve") yaml2json resume.yml -p > resume.json && resume serve --theme /usr/local/lib/node_modules/jsonresume-theme-elegant;;
    "html") yaml2json resume.yml -p > resume.json && resume export --format html --theme /usr/local/lib/node_modules/jsonresume-theme-stackoverflow dist/resume.html;;
    "pdf") yaml2json resume.yml -p > resume.json && resume export --format pdf --theme /usr/local/lib/node_modules/jsonresume-theme-onepage dist/resume.pdf;;
    "yml") cat resume.yml;;
    *) echo "Please utilize a valid command (json|serve|yml|html)";;
esac
