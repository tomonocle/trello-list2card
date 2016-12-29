# list2card
A simple program to summarise the cards on a Trello list as a comment on a card, then archive the cards on the source list.

## Purpose
At the end of every week I summarise the "Done" column of my personal 
Trello board into a "Captain's Log"
metacard, before archiving all of the completed tasks. I wrote `list2card` to automate this process.

Note: scheduling the execution of `list2card` is left as an exercise for the reader.

## Installation
```
$ gem install trello-list2card
```

## Configuration
`list2card` requires a configuration file to operate. An example is available on [Github](https://github.com/tomonocle/trello-list2card/blob/master/etc/config.toml.example), or you can follow the guide below.

### Trello API key and token
Visit [https://trello.com/app-key](https://trello.com/app-key) to get your unique API key and token.

Config file:

```
$ cat config.toml
user_key   = '<KEY>'
user_token = '<TOKEN>'
```

### Source list, destination card

First list your boards to find the id of board you want to work with

```
$ list2card --list-boards
 *  id                       name                                       url
[*] abc123abc123abc123abc123 Test board A                               https://trello.com/b/abc123ab/test-board-a
[ ] 123abc123abc123abc123abc Test board B                               https://trello.com/b/123abc12/test-board-b
```

Now list the lists on the board to find your `source_list_id`

```
$ list2card --list-lists abc123abc123abc123abc123
id                       name
xyz789zxy789xyz789xyz789 Todo
789xyz789xyz789xyz789xyz Done
```

Finally list the cards on the appropriate list to find the id of your summary metacard `dest_card_id`

```
$ list2card --list-cards xyz789zxy789xyz789xyz789
id                       name                                       url
def456def456def456def456 Captain's Log                              https://trello.com/c/aabbccdd
```

### Final config file
```
$ cat config.toml
user_key   = '<KEY>'
user_token = '<TOKEN>'

source_list_id = '789xyz789xyz789xyz789xyz'
dest_card_id   = 'def456def456def456def456'
```

## Usage

```
$ list2card -c config.toml
```

This will silently summarise the contents of `source_list_id` into `dest_card_id` as a comment in the following format:

```
N tasks completed
<Task 1>
<Task ..>
<Task N>
```

Before archiving the cards on `source_list_id`.

Note: No entry will be written if there are no cards to summarise.

### Logging
Log level can be adjusted with `-l [debug,info,warn,error,fatal]` (defaults to **warn**).

### Dry-run
Dry-run (read-only, don't write comment or archive cards) can be enabled with `-d`. Note: you'll probably want to increase the log level with `-l` for this to be useful.

### Exit codes
| Code | Meaning |
|:----:|---------|
| 0    | Success (wrote output, or nothing to do) |
| 1    | Failure. Something went wrong. Always accompanied by a FATAL log message. |
