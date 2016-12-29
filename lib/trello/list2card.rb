module Trello
    class List2Card
        require 'logger'
        require 'ostruct'
        require 'toml'
        require 'trello'
    
        @@LOG_LEVEL_MAP = {
            'debug' => Logger::DEBUG,
            'info'  => Logger::INFO,
            'warn'  => Logger::WARN,
            'error' => Logger::ERROR,
            'fatal' => Logger::FATAL,
        }
    
        @@DEFAULT_LOG_LEVEL = 'warn'
    
        def initialize( config_path, log_level, dry_run )
            @log = Logger.new( STDERR )
            self.set_log_level( @@DEFAULT_LOG_LEVEL )
    
            @log.info 'Starting up'
    
            begin
                raise 'config file not specified' if not config_path
    
                @log.info "Loading config from #{ config_path }"
                @config = OpenStruct.new( TOML.load_file( config_path ) )
                @log.info 'Loaded config'
                @log.debug @config.to_s
    
            rescue => e
                @log.fatal "Failed to load config: #{e.message}"
                exit 1
            end
            
            self.set_log_level( @config[ 'log_level' ] )
            self.set_log_level( log_level )
    
            # very basic sanity check of the config
            [ 'user_key', 'user_token' ].each do |key|
                if ( not @config[ key ] )
                    @log.fatal "Key #{ key } not present in config"
                    exit 1
                end
            end
    
            Trello.configure do |c|
                c.developer_public_key = @config.user_key
                c.member_token         = @config.user_token
            end
    
            if ( dry_run )
                @log.warn 'Dry run mode: ON'
                @dry_run = true
            end
        end
    
        def set_log_level( level )
            return if not level
            
            level.downcase!
    
            if ( not @@LOG_LEVEL_MAP[ level ] )
                @log.fatal "Unrecognised log_level '#{ level }'"
                exit 1
            end
    
            @log.level = @@LOG_LEVEL_MAP[ level ]    
        end
    
        def do_listboards
            begin
                me = Trello::Member.find( 'me' )
            rescue => e
                @log.fatal "Failed to load boards: #{ e.message }"
                exit 1
            end
    
            puts sprintf ' *  %-24s %-42s %s', 'id', 'name', 'url'
            me.boards( :filter => :open ).each do |board|
                puts sprintf '[%s] %s %-42s %s', ( board.starred == true ? '*' : ' ' ), board.id, board.name[ 0, 42 ], board.url
            end
        end
    
        def do_listlists( board_id )
            begin
                board = Trello::Board.find( board_id )
            rescue => e
                @log.fatal "Failed to load board: #{ e.message }"
                exit 1
            end
    
            puts sprintf '%-24s %s', 'id', 'name'
            board.lists.each do |list|
              puts "#{ list.id } #{ list.name }"
            end
        end
    
        def do_listcards( list_id )
            begin
                list = Trello::List.find( list_id )
            rescue => e
                @log.fatal "Failed to load list: #{ e.message }"
                exit 1
            end
            
            puts sprintf '%-24s %-42s %s', 'id', 'name', 'url'
            list.cards.each do |card|
                puts sprintf '%s %-42s %s', card.id, card.name[ 0, 42 ], card.short_url
            end
        end
    
        def do_run
            [ 'source_list_id', 'dest_card_id' ].each do |k|
                if ( not @config[ k ] )
                    @log.fatal "Key #{ k } not present in config"
                    exit 1
                end
            end
    
            # avoid a possible race condition by taking a snapshot of the list
            source_cards = []
    
            begin
                list = Trello::List.find( @config.source_list_id )
                source_cards = list.cards
                @log.info "Loaded list #{ @config.source_list_id }"
    
            rescue => e
                @log.fatal "Couldn't load list_id '#{ @config.source_list_id }': #{ e.message }"
                exit 1
            end
    
            if ( source_cards.count == 0 ) then
                @log.info 'No cards to process - aborting'
                exit 0
    
            else 
                @log.info "#{ source_cards.count } card(s) to process"
            end
    
            # prepare the message itself
            message = sprintf "%d task%s completed\n\n%s", source_cards.count, ( source_cards.count == 1 ? '' : 's' ), ( source_cards.map { |card| card.short_url } ).join( "\n" )
            @log.debug "message: '#{ message }'"
    
            begin
                log_card = Trello::Card.find( @config.dest_card_id )
                log_card.add_comment( message ) if not @dry_run
                @log.info sprintf "%sWrote message to log_card '%s'", ( @dry_run == true ? "[DRYRUN] " : '' ), @config.dest_card_id
    
            rescue => e
                @log.fatal "Failed to write message to log_card '#{ config.dest_card_id }': #{ e.message }"
                exit 1
            end
    
            # Successfully posted the message, now archive the cards
            source_cards.each do |card|
                begin
                    if ( not @dry_run )
                        card.close
                        card.save
                    end
    
                    @log.info sprintf "%sArchived '%s' (%s)", ( @dry_run == true ? '[DRYRUN] ' : '' ), card.name, card.id
    
                rescue => e
                    @log.error "Failed to archive '#{ card.id }'"
                end
            end
    
            @log.info 'Done'
        end
    end
end
