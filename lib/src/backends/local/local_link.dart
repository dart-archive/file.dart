part of file.src.backends.local;

class _LocalLink extends _LocalFileSystemEntity<Link, io.Link>
    with ForwardingLink {
  _LocalLink(FileSystem fs, io.Link delegate) : super(fs, delegate);
}
