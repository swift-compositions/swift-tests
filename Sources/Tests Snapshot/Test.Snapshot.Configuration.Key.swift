public import Dependency
public import File_System
internal import Kernel
import Standard_Library_Extensions
internal import Strings
public import Test


extension Test.Snapshot.Configuration {
    /// Dependency key for snapshot configuration.
    ///
    /// Provides optional configuration for each scope.
    public enum Key: Dependency.Key {
    }
}
