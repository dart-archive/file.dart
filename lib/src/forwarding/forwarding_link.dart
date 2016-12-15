part of file.src.forwarding;

abstract class ForwardingLink extends ForwardingFileSystemEntity<Link, io.Link>
    implements Link {
  @override
  ForwardingLink wrap(io.Link delegate) => wrapLink(delegate);

  @override
  Future<Link> create(String target, {bool recursive: false}) async =>
      wrap(await delegate.create(target, recursive: recursive));

  @override
  void createSync(String target, {bool recursive: false}) =>
      delegate.createSync(target, recursive: recursive);

  @override
  Future<Link> update(String target) async =>
      wrap(await delegate.update(target));

  @override
  void updateSync(String target) => delegate.updateSync(target);

  @override
  Future<String> target() => delegate.target();

  @override
  String targetSync() => delegate.targetSync();
}
