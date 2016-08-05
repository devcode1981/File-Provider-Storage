# Local Network Binding

The default host binding for the rails application is `localhost`, if you
would like to use other devices on your local network to test the rails
application then run:

```
echo 0.0.0.0 > host
./run
```

If you would like to revert back to the `localhost` network then run:

```
rm host
./run
```
