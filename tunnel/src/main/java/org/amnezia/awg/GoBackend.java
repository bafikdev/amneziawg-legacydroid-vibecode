package org.amnezia.awg;

import androidx.annotation.Nullable;

public class GoBackend {
    @Nullable
    public static native String awgGetConfig(int handle);

    public static native int awgGetSocketV4(int handle);

    public static native int awgGetSocketV6(int handle);

    public static native void awgTurnOff(int handle);

    public static native int awgTurnOn(String ifName, int tunFd, String settings);

    public static native String awgVersion();

    /**
     * Clear O_NONBLOCK on a file descriptor. Needed on Android 4.4 where
     * {@code VpnService.Builder.setBlocking()} does not exist.
     *
     * @return 0 on success, -1 on failure
     */
    public static native int awgSetBlocking(int fd);
}
