# Local Network Binding

The default host binding for the rails application is `127.0.0.1`, if you
would like to use other devices on your local network to test the rails
application then:

- In your `gdk.yml` write:

  ```yaml
  hostname: 0.0.0.0
  ```

- Reconfigure and restart

  ```sh
  gdk reconfigure
  gdk restart
  ```
