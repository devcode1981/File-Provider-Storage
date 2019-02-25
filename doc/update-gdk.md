# Updating GDK

1. Make sure postgres is running:

    ```
    cd <gdk-dir>
    gdk run db
    ```

1. Then, **open a separate terminal window** and update gdk along with all its
    components:

    ```
    cd <gdk-dir>
    git pull origin master
    gdk update
    gdk reconfigure
    ```

1. Then stop the `gdk run db` process running in the first tab.  It must be
    restarted once `gdk reconfigure` has been run.
