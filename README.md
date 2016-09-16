DemoGod
=======

A super simple (and poorly written) Mac app to help with live coding demos.

How to use
----------

Basically, you prepare your live coding demo repo by adding annotated tags at relevant points. If you
don't know, annotated tags are created like so: `git tag -a myTagName -m 'some useful comment'`.

Run the app, File->Open, choose your git repo on your disk. The window will show all the annotated tags with
their comments. Double-clicking on any row will stash any changes (including new files) and then
forcibly switch to the selected tag. You can sort the tag or comment column.

You can start from the commandline if you prefer from the root of your git repo with `open -a DemoGod .`

There's a pre-compiled (and signed) app in [Releases](https://github.com/aufflick/DemoGod/releases).

Happy presenting!
