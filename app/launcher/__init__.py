"""Windows one-click launcher surfaces."""

from .contracts import APPLICATION_ID, APPLICATION_VERSION, LOOPBACK_HOST


_WINDOWS_EXPORTS = {
    "LaunchResult",
    "LauncherError",
    "LauncherPaths",
    "find_existing_instance",
    "launch",
    "resolve_default_paths",
}


def __getattr__(name: str) -> object:
    if name not in _WINDOWS_EXPORTS:
        raise AttributeError(name)
    from . import windows

    return getattr(windows, name)

__all__ = [
    "APPLICATION_ID",
    "APPLICATION_VERSION",
    "LOOPBACK_HOST",
    "LaunchResult",
    "LauncherError",
    "LauncherPaths",
    "find_existing_instance",
    "launch",
    "resolve_default_paths",
]
