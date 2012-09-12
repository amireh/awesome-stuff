## The Prayer Widget

The widget adds itself to the tray widget, and it displays the time left for the upcoming prayer along with its label. Labels and messages are currently localizable in English and Arabic.

The timer will go green if the prayer is still two hours away, orange if it's around an hour, and red if it's any less.

The timetable is fetched from [xhanch.com](http://xhanch.com/api/islamic-get-prayer-time.php) and is synchronized every 6 hours.

If anything goes wrong with synchronizing the timetable, a notification is displayed using Naughty reporting the error and the widget will gracefully cancel itself (it will simply display nothing).

### Installation

Edit your `rc.lua` and require the widget somewhere **AFTER beautiful is initialized**, usually after you load your theme, etc:

```lua
beautiful.init("/usr/share/awesome/themes/default/theme.lua")
-- ...
-- now we load the widget, because it relies on Naughty and Beautiful
local prayers = require 'awesome_prayers_widget'
```

And then in your wibox widget listing. Here's a snippet from my wibox configuration:

```lua
mywibox[s].widgets = {
  {
    mylauncher,
    mytaglist[s],
    mypromptbox[s],
    layout = awful.widget.layout.horizontal.leftright
  },
  mylayoutbox[s],
  mytextclock,
  prayers, -- <-- add it somewhere here
  mysystray[s],
  mytasklist[s],
  layout = awful.widget.layout.horizontal.rightleft
}
```

### Customizing it

* Pulses for the refreshing and synchronization timers, defaults to 30 seconds for updating the widget, and 6 hours for synchronizing the timetable feed.
* The locale, defaults to `ar`
* The colors
* The country in which you live; you need to provide the langtitude, latitude, and GMT offset of your place of residence to get accurate timing of prayers. Defaults to `Jordan`

### To-do

* Specify the server for fetching the timetable

## Licensing

The code is released under the MIT terms. Feel free to use it in both open and closed software as you please.

Copyright (c) 2011,2012 Ahmad Amireh

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.