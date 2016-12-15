part of file.src.backends.local;

class _LocalDirectory
    extends _LocalFileSystemEntity<_LocalDirectory, io.Directory>
    with ForwardingDirectory {
  _LocalDirectory(FileSystem fs, io.Directory delegate) : super(fs, delegate);
}
