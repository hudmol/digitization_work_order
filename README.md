Digitization Work Order Plugin
-----------------------------------

This is an ArchivesSpace plugin that provides the ability to download reports for sets of components under a resource for the purpose of creating digitization work orders.

There are three forms of report, selectable via a configuration option.

The default report is a TSV file. When this work order is downloaded, component unique identifiers will be generated for components that don't have one. The plugin ships with a default id generator. See the section below on how to provide your own generator.

The alternative form of the report is an xlsx file suitable for importing into Yale's Ladybird system. Finally, there is an xslx for import into Goobi, also for Yale's use.

This plugin was developed by Hudson Molonglo for New York University and Yale University. It should run under all ArchivesSpace versions from v1.5.x to v4.0.x.


# Getting Started

Download the latest release from the Releases tab in Github:

  https://github.com/hudmol/digitization_work_order/releases

Unzip the release and move it to:

    /path/to/archivesspace/plugins

Unzip it:

    $ cd /path/to/archivesspace/plugins
    $ unzip digitization_work_order-vX.X.zip

Enable the plugin by editing the file in `config/config.rb`:

    AppConfig[:plugins] = ['some_plugin', 'digitization_work_order']

(Make sure you uncomment this line (i.e., remove the leading '#' if present))

Install dependencies by initializing the plugin:

    $ cd /path/to/archivesspace
    $ ./scripts/initialize-plugin.sh digitization_work_order

See also:

  https://archivesspace.github.io/archivesspace/user/archivesspace-plug-ins/


# Configuring it

To use the Ladybird form of the report, set the following configuration option in config.rb:

    AppConfig[:digitization_work_order_ladybird] = true

To use the Goobi form of the report, set the following configuration option in config.rb:
    AppConfig[:digitization_work_order_goobi] = true

# How it works

When this plugin is installed, you will see a new toolbar option at the top
of the Resource tree. Clicking this button will open a modal and allow you
to customize a Work Order Report for the selected items in the resource tree.


# How to replace the default id generator

To replace the default id generator, you will need to subclass:

    backend/model/id_generators/generator_interface.rb

Place your new class file in the same directory. For an example, see the default generator:

    backend/model/id_generators/default_generator.rb

To activate your new generator, edit `archivesspace/config/config.rb`, adding a line like this:

    AppConfig[:digitization_work_order_id_generator] = 'MyClassName'

Then restart ArchivesSpace. Be sure to test your generator on non-production data first!

