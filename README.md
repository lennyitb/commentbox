
# Lenny's C/C++ comment box generator ruby gem

## What it is

```C
            /*><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>X
            $!                                                              $!
            !$                    Lenny's CommentBox gem                    !$
            $!                                                              $!
            X<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><*/
```

It generates nice little formatted multiline comment boxes for you with just a couple of lines of code. I wrote this for another project, but I got carried away with it to the point that I think it's useful as its very own utility. It's around about 200 lines of ruby. This readme should have 100% of the information you need to use this gem. What you get is a pretty basic class with a to_s method and a small assortment of options to customize your CommentBox look and feel all available under the fabulous MIT license.

## Get it

```bash
  masterchief@corpco-workstation:~/importantproject$ gem install commentbox
```

```ruby
  # my_script.rb
  require 'commentbox'
```

## Use it

### Initialize with a string

```ruby
  puts CommentBox.new "Lenny's box"
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
  # my_script.rb

  box = CommentBox.new\
    # text can be either an Array of Strings or a String with newlines
    text: [
      "Line 1",
      "Line 2",
      "Line 3",
    ],
    # every other parameter is optional
    # last alignment symbol will be copied for each remaining line if not enough are provided
    alignment: [:center, :left, :right], # Array of Symbols/Strings, or just one Symbol/String
    style: :money,     # Symbol/String naming a built-in style or Hash describing your custom style
    padding: 4,        # number of spaces before and after the longest line
    offset: 2,         # number of indent spaces
    stretch: 15,       # makes the box wider without changing the padding
    min_width: 0,      # a lot like stretch but absolute. forces a minimum width for more consistent formatting across all your boxes
    spacelines: false  # empty lines above and below text
```

If you like to keep lengthy JSON files full of your build settings, for now, the only catch is that keys must be symbolized somehow. CommentBox is mostly tolerant of String values, however:

```ruby
  #...
  # my_script.rb

  json_str =\
    %q/{
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
  box2 = CommentBox.new JSON.parse(json_str, symbolize_names: true)

  # also consider:
  box3 = CommentBox.new JSON.parse(json_str).transform_keys(&:to_sym)

  # box, box2, and box3 are all identical
  unless (box == box2 && box2 == box3)
    gift_shop.shut_down; circus.cancel; zoo.secure_all_animals; exits.close
  end # gift shop remains open
```

### Embed in ERB C/C++ templates

Referencing the same CommentBox we defined above and constructing a new one:

```erb
  % require_relative 'my_script'
  <%= box %>

  #ifndef MY_HEADER_H
  #define MY_HEADER_H

  <%= CommentBox.new text: "note commentbox will insert a line\nif neccesary to ensure there's an odd number of lines", style: :parallax %>

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

```erb
%# print a box for each style
<% CommentBox.styles.keys.each do |s| %>
<%= CommentBox.new text: (":" + s.to_s), style: s, alignment: :center, min_width: 14 %>
<% end %>
```

```C
  /***********************=/
  \                        \
  /         :stub          /
  \                        \
  /=***********************/

  /*======================/#
  ||                      ||
  ||      :parallax       ||
  ||                      ||
  #/======================*/

  /*=-=-=-=-=-=-=-=-=-=-=-=O
  \                        \
  /        :zigzag         /
  \                        \
  O-=-=-=-=-=-=-=-=-=-=-=-*/

  /*><><><><><><><><><><><>X
  $!                      $!
  !$        :money        !$
  $!                      $!
  X<><><><><><><><><><><><*/
```

### Messing with the defaults

You're probably gonna wind up with a favorite setting you wanna stick with. There's a handful of set-&-forget type class methods you can use to add some consistency to your boxes.

```ruby
  #...
  # helper_file.rb

  # access a hash of all the default settings
  params = CommentBox.default_params
  # equivalent to:
  params = CommentBoxStyles::DefaultParams

  # pass self.default_params= only a complete hash with every setting
  params[:style] = :money
  CommentBox.default_params = params

  # use self.set_default_params to merge a hash with the current defaults
  # String keys are acceptable
  CommentBox.set_default_params "padding" => 2, spacelines: false, alignment: :right

  # i never definded a default_params[]= method but somehow it works anyway:
  CommentBox.default_params[:stretch] = 20
  # don't try and call this with a String key though
  
  # if you have a lot of CommentBoxes, consider something like this:
  def cb(arg); CommentBox.new(arg).to_s; end
```

```erb
  % require_relative 'helper_file'
  %# i defined a little alias method 'cb' 2 lines ago if you're lost here:
  <%= cb "Lenny's box" %>
  <%= cb "another box" %>
```

```C
    /*><><><><><><><><><><><><><><><><><><><><>X
    $!                         Lenny's box    $!
    X<><><><><><><><><><><><><><><><><><><><><*/
    /*><><><><><><><><><><><><><><><><><><><><>X
    $!                         another box    $!
    X<><><><><><><><><><><><><><><><><><><><><*/
```

### Your very own style

A style is just a hash (as shown below). it has a key for each of the two 'odd' corners (the begin/end corners will always be /\* \*/), as well as the begin/end borders for odd and even lines respectively, and finally a string for the horizontal lines at the top and bottom of the box. All Strings are exactly two characters that are repeated as necessary.

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

Also of course you may add your own style to the catalog of built-in styles:

```ruby
  CommentBox.add_style minimal: {
    hlines: '  ',
    oddlines: ['  ', '  '],
    evenlines: ['  ', '  '],
    oddcorners: ['*\\', '\\*'],
    default?: true # optional syntactic sugar- works with or without a question mark
  }
  CommentBox.set_default_params style: :minimal # redundant here, but possible nonetheless
  puts CommentBox.new text: "Hello, world!" # produces the same output as above
```

Study the output of `puts CommentBox.styles.to_s` for more examples.

So yeah this is a pretty simple one- thanks for checking it out.
