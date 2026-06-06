abstract class ReplayBufferRepository {
  Future<void> enable(int seconds);
  Future<void> disable();
  Future<void> save();
}
