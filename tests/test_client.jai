#import "Basic";
#import "File";
#import "String";

main :: () {
  args := get_command_line_arguments();

  project_dir := args[ 0 ];
  _, basename := path_decomp( project_dir );

  workspaceFolders : [1]Workspace_Folder;
  workspaceFolders[0] = .{
    uri = path_to_uri( project_dir ),
    name = basename,
  };

  init_message := LSP_Request_Message_Initialize. {
    params=  .{
      clientInfo = .{
        name = "JailsTest",
        version = VERSION,
      },
      rootPath = *project_dir,
      rootUri = *path_to_uri( project_dir ),
      workspaceFolders = *array_view( workspaceFolders, 0, workspaceFolders.count),
    }
  };

}

path_to_uri :: ( path: string ) -> string {
  return tprint( "file://%", path );
}

VERSION :: "1.0.0";
#load "../lsp/lsp_interface.jai";
#load "../lsp/rpc.jai";
