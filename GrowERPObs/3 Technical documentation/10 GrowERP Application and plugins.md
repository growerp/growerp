# GrowERP plugins

## Introduction

GrowERP consist completely out of a number of plugins which are called by an application. The application is just a list of screens and a menu structure. An example is the 'admin' application which shows all the functions currently available within the system. All packages names which start with 'growerp' are plugins.

## Why plugins?

A plugin gives you the ability to create or update a system functionlity independent of the existing system based on other plugins which are froozen in the https://pub.dev repository.

It is always your own decision if you would like to upgrade by updating the plugins you base your plugin on in the pubspec.yaml file.

Further, plugins can be maintained and tested outside of the existing system. When finished, the existing system can be upgraded by changing the plugin version in the pubspec.yml.

## Parts of a plugin
A GrowERP plugin can be as simple as a single screen, or a number of screens together:
1. So at least one single or more screens
2. a routing of how to access these screens
3. a model of the data to be managed
4. an API for a backend system
5. an integration test
6. An example to demonstrate the plugin

## Location of files
In general you store your files in the src directory so they will not be visble to its users. The files you want to make visble are exported in the dart file with the same name as the plugin package.

## Directory organization

plugin_name
	lib
		plugin_name.dart
		src
			models
			views
			widgets
				


