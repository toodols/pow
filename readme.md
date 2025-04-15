# Pow
Homebrew Cmdr with more palatable syntax features

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