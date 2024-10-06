# Moqui Apache Camel Tool Component

[![license](http://img.shields.io/badge/license-CC0%201.0%20Universal-blue.svg)](https://github.com/moqui/moqui-camel/blob/master/LICENSE.md)
[![release](http://img.shields.io/github/release/moqui/moqui-camel.svg)](https://github.com/moqui/moqui-camel/releases)

Moqui Framework tool component for Apache Camel, an enterprise integration pattern (EIP) suite, along with an endpoint for the Service Facade.

To install run (with moqui-framework):

    $ ./gradlew getComponent -Pcomponent=moqui-camel

This will add the component to the Moqui runtime/component directory. 

The Apache Camel and dependent JAR files are added to the lib directory when the build is run for this component, which is
designed to be done from the Moqui build (ie from the moqui root directory) along with all other component builds. 

To use just install this component. The configuration for the ToolFactory and ServiceRunner is already in place in the 
MoquiConf.xml included in this component and will be merged with the main configuration at runtime. 
