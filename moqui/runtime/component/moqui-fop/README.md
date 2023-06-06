# Moqui Apache FOP Tool Component

[![license](http://img.shields.io/badge/license-CC0%201.0%20Universal-blue.svg)](https://github.com/moqui/moqui-fop/blob/master/LICENSE.md)
[![release](http://img.shields.io/github/release/moqui/moqui-fop.svg)](https://github.com/moqui/moqui-fop/releases)

Moqui Tool Component for Apache FOP to transform XSL-FO to PDF, etc using the ResourceFacade.xslFoTransform() method.

To install run (with moqui-framework):

    $ ./gradlew getComponent -Pcomponent=moqui-fop

This will add the component to the Moqui runtime/component directory.

The Apache FOP and dependent JAR files are added to the lib directory when the build is run for this component, which is
designed to be done from the Moqui build (ie from the moqui root directory) along with all other component builds.

To use just install this component. The configuration for the ToolFactory is already in place in the
MoquiConf.xml included in this component and will be merged with the main configuration at runtime.
