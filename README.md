
# Lenny's C/C++ comment box generator gem

## Get it

```bash
  masterchief@corpco-workstation ~/importantproject $ gem install commentbox
```

```ruby
  #!/usr/bin/env ruby
  # my_script.rb
  require 'commentbox'
```

## Use it

### Initialize with a string

```ruby
  box = CommentBox.new "Hello, world!"
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

### Embed in ERB C/C++ templates

```erb
  <%= box %>

  <%= CommentBox.new text: "note commentbox will insert a line\nif neccesary to ensure there's an odd number of lines", style: :bars %>
```

```C
  /*><><><><><><><><><><><><><><><>X
  $!            Line 1            $!
  !$    Line 2                    !$
  $!                    Line 3    $!
  X<><><><><><><><><><><><><><><><*/

  /*==============================================================/#
  ||                                                              ||
  ||    note commentbox will insert a line                        ||
  ||                                                              ||
  ||    if neccesary to ensure there's an odd number of lines     ||
  ||                                                              ||
  #/==============================================================*/
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

### your very own style

```erb
  <%= # for the minimalist in all of us
  CommentBox.new text: "Hello, world!",
  style: {
    hlines: '  ',
    oddlines: ['  ', '  '],
    evenlines: ['  ', '  '],
    oddcorners: ['  ', '  ']
  }%>
```

```C
  /*                        
                            
        Hello, world!       
                            
                          */
```

So yeah this is a pretty simple one- thanks for checking it out.
