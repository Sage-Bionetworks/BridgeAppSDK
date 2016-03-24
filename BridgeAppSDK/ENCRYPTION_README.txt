-------------------------------
Setting up Encryption
-------------------------------

The APCCMSSupport.h header file defines an interface for an APCCMSSupport class.

By default, no implementation of this class is included in BridgeAppSDK. If you provide an implementation and link it
into the same executable binary with BridgeAppSDK, the methods included in the wrapper will return the result of those
implementations.

If you provide no implementation of this class, the default behavior of the methods are to log a warning
to the console and return the data unchanged.