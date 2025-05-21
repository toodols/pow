# Pow
Homebrew Cmdr with more palatable syntax features

## Command Format
`run` - This command can be run on either server and client, at the convenience of the current context executing it.
`server_run` - This command is run exclusively on server, and the client will defer to the server.
`client_run` - This command is run exclusively on client, and the server will defer to the client.

```lua
print hi; /* Commands start off in a client context */
```

```lua
kill Player1 /* Some commands are run on the server */
```

```lua
bind_tool (tool die) {
    print "tool activated"; /* This is run on the server */
    kill @me
}
```

## ??
Here's an example of fibonacci
```lua
set a (number 0); /* a = 0 */
set b (number 1); /* b = 1 */
set text 0; /* text = "0" */

repeat 50 { /* for i = 1, 50 do */
    set text (concat (get text) ", " (to_string (get b))); /* text = text .. ", " .. tostring(b) */
    set temp (get b); /* temp = b */
    set b (add (get a) (get b)); /* b = a + b */
    set a (get temp); /* a = temp */
}; /* end */

print (get text) /* print (text) */
```

