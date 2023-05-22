#load "../shared/shared.jai";
#load "../shared/binary_serialization.jai";
#import "Basic";
#import "Shared_Memory_Channel";

quit := false;

listen_to_metaprogram :: () -> s64 {
    channel_name := tprint("%-%", IPC_CHANNEL_NAME_FROM_META, 100);

    #if OS != .WINDOWS {
        POSIX :: #import "POSIX";
        // @FixMe: Shouldn't this be a c-string ?
        POSIX.shm_unlink(channel_name.data);
    }

    success, channel := reader_create_channel(channel_name, CHANNEL_DATA_BYTES);
    if !success {
        return -1;
    }

    log( "Opened %", channel_name );

    defer reader_release_channel(*channel);

    write_channel: Write_Channel;
    while !quit {
        message_success, fatal_error, message := reader_poll_for_message(*channel);

        if fatal_error {
            log_error("Fatal error");
            return -1;
        }

        if !message_success {
            // @ToDo: We should probably not busy-loop here all the time.
            // Instead we could use a semaphore to only wait for messages after kicking of a compile command.
            sleep_milliseconds(10);
            continue;
        }

        defer {
            reader_done_with_message(*message);
        }

        bytes := message.user_read_bytes;
        if bytes < JAILS_HEADER_SIZE {
            log_error("Got a message that is too short (% bytes)! Quitting.", bytes);
            return -1;
        }

        success, workspace_index, command, body_bytes := decode_mesage_header(message, Protocol_Tag);
        if !success return -1;

        log( "Workspace is %\nCommand is %s\n", workspace_index, command );

        body_type : Type;

        Dump :: ( t: $T ) #expand {
          body := deserialize(`body_bytes, t);
          log( "Body is %", body );
        };

        if command == {
            case .INITIALIZATION; Dump( Initialization );
            case .MODULE_IMPORT; Dump( Module) ;
            case .FILE; Dump( Source_File) ;
            case .STRUCT; Dump( Struct) ;
            case .PROCEDURE; Dump( Procedure) ;
            case .TYPE_INSTANTIATION; Dump( Type_Instantiation) ;
            case .EXPRESSION; Dump( Expression) ;
            case .ENUM; Dump( Enum) ;
            case .BLOCK; Dump( Block) ;
        }
    }

    return 0;
}

main :: () {
  listen_to_metaprogram();
}
