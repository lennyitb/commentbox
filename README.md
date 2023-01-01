
# Lenny's C/C++ comment box generator ruby gem

## What it is

If you like to write CG templates for C/C++ in ruby, you might find this gem useful. Maybe it's a version increment script, or maybe it's an overly repetitive solution you haven't figured out a better approach for. It generates nice little formatted multiline comment boxes for you with just a couple of lines of code.

What you get is a pretty basic class with a to_s method and a small assortment of options to customize your CommentBox look and feel.

## Get it

```bash
  masterchief@corpco-workstation:~/importantproject$ gem install commentbox
```

```ruby
  #!/usr/bin/env ruby
  # my_script.rb
  require 'commentbox'
```

## Use it

### Initialize with a string

```ruby
  box = CommentBox.new "Lenny's box"
```

```C
  /*********************=/
  \                      \
  /     Lenny's box      /
  \                      \
  /=*********************/
```

### Initialize with a hash (all the parameters you can play with are shown here)

```ruby
  box = CommentBox.new\
    text: [
      "Line 1",
      "Line 2",
      "Line 3",
    ],
    alignment: [:center, :left, :right],
    style: :money, padding: 4, offset: 2, stretch: 15, spacelines: false
```

If you like to keep lengthy JSON files full of your settings, the only catch is the keys must be symbolized somehow. CommentBox is tolerant of String values, however:

```ruby
json_str = %q/{
  "text": [
    "Line 1",
    "Line 2",
    "Line 3"
  ],
  "alignment": ["center", "left", "right"],
  "style": "money",
  "padding": 4,
  "offset": 2,
  "stretch": 15,
  "spacelines": false
  }/
  require 'json'
  box = CommentBox.new JSON.parse(json_str, symbolize_names: true)
```

### Embed in ERB C/C++ templates

Referencing the same CommentBox we defined above and constructing a new one:

```erb
  <%= box %>

  #ifndef MY_HEADER_H
  #define MY_HEADER_H

  <%= CommentBox.new text: "note commentbox will insert a line\nif neccesary to ensure there's an odd number of lines", style: :bars %>

  #endif
```

```C
  /*><><><><><><><><><><><><><><><>X
  $!            Line 1            $!
  !$    Line 2                    !$
  $!                    Line 3    $!
  X<><><><><><><><><><><><><><><><*/

  #ifndef MY_HEADER_H
  #define MY_HEADER_H

  /*==============================================================/#
  ||                                                              ||
  ||    note commentbox will insert a line                        ||
  ||                                                              ||
  ||    if neccesary to ensure there's an odd number of lines     ||
  ||                                                              ||
  #/==============================================================*/

  #endif
```

### Built-in styles

```C
  /***************=/
  \                \
  /     :stub      /
  \                \
  /=***************/

  /*==============/#
  ||              ||
  ||    :bars     ||
  ||              ||
  #/==============*/

  /*=-=-=-=-=-=-=-=-=O
  \                  \
  /     :zigzag      /
  \                  \
  O-=-=-=-=-=-=-=-=-*/

  /*><><><><><><><>X
  $!              $!
  !$    :money    !$
  $!              $!
  X<><><><><><><><*/
```

### Your very own style

```erb
  <%= # for the minimalist in all of us
  CommentBox.new text: "Hello, world!",
  style: {
    hlines: '  ',
    oddlines: ['  ', '  '],
    evenlines: ['  ', '  '],
    oddcorners: ['*\\', '\\*']
  }%>
```

```C
  /*                      *\
                            
        Hello, world!       
                            
  \*                      */
```

So yeah this is a pretty simple one- thanks for checking it out.
