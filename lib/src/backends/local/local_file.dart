part of file.src.backends.local;

class _LocalFile extends _LocalFileSystemEntity<File, io.File>
    with ForwardingFile {
  _LocalFile(FileSystem fs, io.File delegate) : super(fs, delegate);
}
