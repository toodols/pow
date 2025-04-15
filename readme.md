# Pow
Homebrew Cmdr with more palatable syntax features

Here's an example of fibonacci
```lua
/* (number ...) must be used because otherwise it will interpret it as a string */
set a (number 0);
set b (number 1);
set text 0; /* here is fine because we want a string */

repeat 50 {
    set text (concat (get text) ", " (to_string (get b)));                     
    set temp (get b);
    set b (add (get a) (get b));
    set a (get temp);
}; /* semicolons are mandatory after every line */

print (get text) /* last line is treated as a "return" unless there is semicolon */
```