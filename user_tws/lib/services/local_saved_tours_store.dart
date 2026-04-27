import 'local_saved_tours_store_base.dart';
import 'local_saved_tours_store_io.dart'
    if (dart.library.html) 'local_saved_tours_store_web.dart';

export 'local_saved_tours_store_base.dart' show LocalSavedToursStore, sortIds;

/// Factory entrypoint for the platform implementation.
LocalSavedToursStore createStore() => createLocalSavedToursStore();

