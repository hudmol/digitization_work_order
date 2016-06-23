Digitization Work Order Plugin
-----------------------------------

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

See also:

  https://github.com/archivesspace/archivesspace/blob/master/plugins/README.md

You will need to shutdown archivesspace and migrate the database:

     $ cd /path/to/archivesspace
     $ scripts/setup-database.sh

See also:

  https://github.com/archivesspace/archivesspace/blob/master/UPGRADING.md

# How it works

When this plugin is installed, you will see a new toolbar option at the top
of the Resource tree. Clicking this button will open a modal and allow you
to customize a Work Order Report for the selected items in the archival tree.
